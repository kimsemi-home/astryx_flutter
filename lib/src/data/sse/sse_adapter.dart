import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../core/transport.dart';
import '../rest/rest_adapter.dart';

/// One event from a W3C Server-Sent Events stream.
@immutable
class SseEvent {
  const SseEvent({
    required this.data,
    this.id,
    this.event,
    this.retry,
  });

  final String data;
  final String? id;
  final String? event;
  final Duration? retry;

  Object? decodeJson() => jsonDecode(data);
}

/// Incremental UTF-8 decoder for `text/event-stream` response bodies.
class SseDecoder extends StreamTransformerBase<List<int>, SseEvent> {
  const SseDecoder();

  @override
  Stream<SseEvent> bind(Stream<List<int>> stream) async* {
    var dataLines = <String>[];
    String? id;
    String? event;
    Duration? retry;

    SseEvent? dispatch() {
      if (dataLines.isEmpty) return null;
      final value = SseEvent(
        data: dataLines.join('\n'),
        id: id,
        event: event,
        retry: retry,
      );
      dataLines = <String>[];
      event = null;
      return value;
    }

    final lines =
        stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (line.isEmpty) {
        final value = dispatch();
        if (value != null) yield value;
        continue;
      }
      if (line.startsWith(':')) continue;
      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'data':
          dataLines.add(value);
        case 'event':
          event = value;
        case 'id':
          if (!value.contains('\u0000')) id = value;
        case 'retry':
          final milliseconds = int.tryParse(value);
          if (milliseconds != null && milliseconds >= 0) {
            retry = Duration(milliseconds: milliseconds);
          }
      }
    }
    final trailing = dispatch();
    if (trailing != null) yield trailing;
  }
}

/// SSE client with Last-Event-ID propagation and optional reconnection.
class SseAdapter extends TransportAdapter {
  SseAdapter({
    this.baseUri,
    http.Client? client,
    this.defaultHeaders = const {},
    this.headerProvider,
    this.defaultRetry = const Duration(seconds: 2),
    bool? ownsClient,
  })  : _client = client ?? http.Client(),
        _ownsClient = ownsClient ?? client == null;

  final Uri? baseUri;
  final Map<String, String> defaultHeaders;
  final HeaderProvider? headerProvider;
  final Duration defaultRetry;
  final http.Client _client;
  final bool _ownsClient;

  @override
  AstryxProtocol get protocol => AstryxProtocol.sse;

  @override
  Set<TransportCapability> get capabilities => const {
        TransportCapability.streaming,
      };

  Stream<SseEvent> connect(
    Object path, {
    Map<String, String> headers = const {},
    Map<String, Object?> queryParameters = const {},
    bool reconnect = true,
    int maxReconnectAttempts = 3,
  }) {
    final uri = path is Uri ? path : Uri.parse(path.toString());
    final request = TransportRequest(
      protocol: protocol,
      uri: _resolveUri(uri, queryParameters),
      headers: headers,
      metadata: {
        'reconnect': reconnect,
        'maxReconnectAttempts': maxReconnectAttempts,
      },
    );
    return _events(request);
  }

  @override
  Stream<TransportEvent> openStream(TransportRequest request) {
    return _events(request).map(
      (event) => TransportEvent(
        protocol: protocol,
        data: event.data,
        id: event.id,
        event: event.event,
        retry: event.retry,
      ),
    );
  }

  Stream<SseEvent> _events(TransportRequest request) async* {
    final reconnect = request.metadata['reconnect'] as bool? ?? true;
    final maxAttempts = request.metadata['maxReconnectAttempts'] as int? ?? 3;
    var attempts = 0;
    var retryDelay = defaultRetry;
    String? lastEventId;

    while (true) {
      try {
        await for (final event in _connectOnce(request, lastEventId)) {
          if (event.id != null) lastEventId = event.id;
          if (event.retry != null) retryDelay = event.retry!;
          attempts = 0;
          yield event;
        }
      } catch (error) {
        if (!reconnect || attempts >= maxAttempts) rethrow;
      }
      if (!reconnect || attempts >= maxAttempts) return;
      attempts += 1;
      await Future<void>.delayed(retryDelay);
    }
  }

  Stream<SseEvent> _connectOnce(
    TransportRequest request,
    String? lastEventId,
  ) async* {
    final uri = _resolveUri(request.uri, request.queryParameters);
    final dynamicHeaders = await headerProvider?.call() ?? const {};
    final headers = <String, String>{
      'accept': 'text/event-stream',
      'cache-control': 'no-cache',
      ...defaultHeaders,
      ...dynamicHeaders,
      ...request.headers,
      if (lastEventId != null) 'last-event-id': lastEventId,
    };
    final httpRequest = http.Request('GET', uri)..headers.addAll(headers);
    final response = await _client.send(httpRequest);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw TransportException(
        'SSE handshake failed.',
        protocol: protocol,
        uri: uri,
        statusCode: response.statusCode,
        responseBody: body,
      );
    }
    yield* response.stream.transform(const SseDecoder());
  }

  Uri _resolveUri(Uri uri, Map<String, Object?> parameters) {
    final resolved = uri.hasScheme
        ? uri
        : baseUri?.resolveUri(uri) ??
            (throw ArgumentError('A relative URI requires baseUri.'));
    if (parameters.isEmpty) return resolved;
    return resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        for (final entry in parameters.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
      },
    );
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
