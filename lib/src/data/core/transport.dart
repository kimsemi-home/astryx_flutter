import 'dart:convert';

import 'package:meta/meta.dart';

/// Protocol families supported by the default Astryx transport registry.
enum AstryxProtocol { rest, graphql, sse, hateoas }

/// Features an adapter can expose.
enum TransportCapability { requestResponse, streaming, hypermedia }

/// HTTP verbs shared by REST, GraphQL-over-HTTP, and hypermedia links.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head,
  options;

  String get wireName => name.toUpperCase();

  static HttpMethod parse(String value) {
    final normalized = value.trim().toLowerCase();
    return HttpMethod.values.firstWhere(
      (method) => method.name == normalized,
      orElse: () => throw FormatException('Unsupported HTTP method: $value'),
    );
  }
}

/// A protocol-neutral command sent through a [TransportAdapter].
@immutable
class TransportRequest {
  const TransportRequest({
    required this.protocol,
    required this.uri,
    this.method = HttpMethod.get,
    this.headers = const {},
    this.queryParameters = const {},
    this.body,
    this.operation,
    this.metadata = const {},
  });

  final AstryxProtocol protocol;
  final Uri uri;
  final HttpMethod method;
  final Map<String, String> headers;
  final Map<String, Object?> queryParameters;
  final Object? body;

  /// GraphQL document, operation name, or another protocol-specific command.
  final String? operation;
  final Map<String, Object?> metadata;

  TransportRequest copyWith({
    AstryxProtocol? protocol,
    Uri? uri,
    HttpMethod? method,
    Map<String, String>? headers,
    Map<String, Object?>? queryParameters,
    Object? body,
    String? operation,
    Map<String, Object?>? metadata,
  }) {
    return TransportRequest(
      protocol: protocol ?? this.protocol,
      uri: uri ?? this.uri,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      body: body ?? this.body,
      operation: operation ?? this.operation,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// A protocol-neutral response with both decoded and raw payloads.
@immutable
class TransportResponse {
  const TransportResponse({
    required this.protocol,
    required this.request,
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.rawBody,
    this.metadata = const {},
  });

  final AstryxProtocol protocol;
  final TransportRequest request;
  final int statusCode;
  final Map<String, String> headers;
  final Object? body;
  final String rawBody;
  final Map<String, Object?> metadata;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  TransportResponse ensureSuccess() {
    if (!isSuccess) {
      throw TransportException(
        'Request failed with HTTP $statusCode',
        protocol: protocol,
        uri: request.uri,
        statusCode: statusCode,
        responseBody: rawBody,
      );
    }
    return this;
  }

  Map<String, Object?> requireJsonObject() {
    final value = body;
    if (value is Map<String, Object?>) return value;
    if (value is Map) return value.cast<String, Object?>();
    throw TransportException(
      'Expected a JSON object response.',
      protocol: protocol,
      uri: request.uri,
      statusCode: statusCode,
      responseBody: rawBody,
    );
  }
}

/// A normalized event emitted by a streaming transport.
@immutable
class TransportEvent {
  const TransportEvent({
    required this.protocol,
    required this.data,
    this.id,
    this.event,
    this.retry,
    this.metadata = const {},
  });

  final AstryxProtocol protocol;
  final String data;
  final String? id;
  final String? event;
  final Duration? retry;
  final Map<String, Object?> metadata;

  Object? decodeJson() => jsonDecode(data);
}

/// Base class for request/response and streaming adapters.
abstract class TransportAdapter {
  AstryxProtocol get protocol;
  Set<TransportCapability> get capabilities;

  Future<TransportResponse> send(TransportRequest request) {
    return Future<TransportResponse>.error(
      UnsupportedError('$protocol does not support request/response.'),
    );
  }

  Stream<TransportEvent> openStream(TransportRequest request) {
    return Stream<TransportEvent>.error(
      UnsupportedError('$protocol does not support streaming.'),
    );
  }

  void close() {}
}

/// Failure raised by any Astryx transport adapter.
class TransportException implements Exception {
  const TransportException(
    this.message, {
    required this.protocol,
    this.uri,
    this.statusCode,
    this.responseBody,
    this.cause,
  });

  final String message;
  final AstryxProtocol protocol;
  final Uri? uri;
  final int? statusCode;
  final String? responseBody;
  final Object? cause;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    return 'TransportException[$protocol]$status: $message';
  }
}
