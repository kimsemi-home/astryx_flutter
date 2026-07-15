import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/transport.dart';
import '../core/transport_middleware.dart';

typedef HeaderProvider = Future<Map<String, String>> Function();

/// Multi-platform REST adapter backed by an injectable `package:http` client.
class RestAdapter extends TransportAdapter {
  RestAdapter({
    this.baseUri,
    http.Client? client,
    this.defaultHeaders = const {},
    this.headerProvider,
    List<TransportMiddleware> middleware = const [],
    bool? ownsClient,
  })  : _client = client ?? http.Client(),
        _ownsClient = ownsClient ?? client == null,
        _pipeline = TransportMiddlewarePipeline(middleware);

  final Uri? baseUri;
  final Map<String, String> defaultHeaders;
  final HeaderProvider? headerProvider;
  final http.Client _client;
  final bool _ownsClient;
  final TransportMiddlewarePipeline _pipeline;

  @override
  AstryxProtocol get protocol => AstryxProtocol.rest;

  @override
  Set<TransportCapability> get capabilities => const {
        TransportCapability.requestResponse,
      };

  Future<TransportResponse> request(
    Object path, {
    HttpMethod method = HttpMethod.get,
    Map<String, String> headers = const {},
    Map<String, Object?> queryParameters = const {},
    Object? body,
    Future<void>? abortTrigger,
  }) {
    final uri = path is Uri ? path : Uri.parse(path.toString());
    return send(
      TransportRequest(
        protocol: protocol,
        uri: uri,
        method: method,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
        abortTrigger: abortTrigger,
      ),
    );
  }

  Future<TransportResponse> get(
    Object path, {
    Map<String, String> headers = const {},
    Map<String, Object?> queryParameters = const {},
    Future<void>? abortTrigger,
  }) =>
      request(
        path,
        headers: headers,
        queryParameters: queryParameters,
        abortTrigger: abortTrigger,
      );

  Future<TransportResponse> post(
    Object path, {
    Map<String, String> headers = const {},
    Map<String, Object?> queryParameters = const {},
    Object? body,
    Future<void>? abortTrigger,
  }) =>
      request(
        path,
        method: HttpMethod.post,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
        abortTrigger: abortTrigger,
      );

  @override
  Future<TransportResponse> send(TransportRequest request) {
    return _pipeline.send(request, _send);
  }

  Future<TransportResponse> _send(TransportRequest request) async {
    final uri = _resolveUri(request.uri, request.queryParameters);
    final dynamicHeaders = await headerProvider?.call() ?? const {};
    final headers = <String, String>{
      ...defaultHeaders,
      ...dynamicHeaders,
      ...request.headers,
    };
    final httpRequest = http.AbortableRequest(
      request.method.wireName,
      uri,
      abortTrigger: request.abortTrigger,
    );
    httpRequest.headers.addAll(headers);
    _writeBody(httpRequest, request.body);

    try {
      final streamed = await _client.send(httpRequest);
      final bytes = await streamed.stream.toBytes();
      final rawBody = utf8.decode(bytes, allowMalformed: true);
      final decoded = _decodeBody(rawBody, streamed.headers['content-type']);
      return TransportResponse(
        protocol: request.protocol,
        request: request.copyWith(uri: uri),
        statusCode: streamed.statusCode,
        headers: streamed.headers,
        body: decoded,
        rawBody: rawBody,
      );
    } on http.RequestAbortedException catch (error) {
      throw TransportAbortedException(
        protocol: request.protocol,
        uri: uri,
        cause: error,
      );
    } catch (error) {
      if (error is TransportException) rethrow;
      throw TransportException(
        'Unable to complete request.',
        protocol: request.protocol,
        uri: uri,
        cause: error,
      );
    }
  }

  Uri _resolveUri(Uri uri, Map<String, Object?> parameters) {
    final resolved = uri.hasScheme
        ? uri
        : baseUri?.resolveUri(uri) ??
            (throw ArgumentError('A relative URI requires baseUri.'));
    if (parameters.isEmpty) return resolved;
    final merged = <String, String>{...resolved.queryParameters};
    for (final entry in parameters.entries) {
      if (entry.value != null) merged[entry.key] = entry.value.toString();
    }
    return resolved.replace(queryParameters: merged);
  }

  void _writeBody(http.Request request, Object? body) {
    if (body == null) return;
    if (body is String) {
      request.body = body;
      return;
    }
    if (body is List<int>) {
      request.bodyBytes = body;
      return;
    }
    request.headers.putIfAbsent('content-type', () => 'application/json');
    request.body = jsonEncode(body);
  }

  Object? _decodeBody(String value, String? contentType) {
    if (value.isEmpty) return null;
    final trimmed = value.trimLeft();
    final looksLikeJson = contentType?.toLowerCase().contains('json') == true ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[');
    if (!looksLikeJson) return value;
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
