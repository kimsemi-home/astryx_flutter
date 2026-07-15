import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../core/transport.dart';
import '../core/transport_middleware.dart';
import '../rest/rest_adapter.dart';

/// One event from a W3C Server-Sent Events stream.
@immutable
class SseEvent {
  const SseEvent({required this.data, this.id, this.event, this.retry});

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

/// Delay progression used between consecutive SSE connection failures.
enum SseBackoffMode { constant, linear, exponential }

/// Immutable reconnection settings for an SSE stream.
@immutable
class SseReconnectPolicy {
  const SseReconnectPolicy({
    this.enabled = true,
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
    this.mode = SseBackoffMode.constant,
    this.multiplier = 2,
  })  : assert(maxAttempts >= 0, 'maxAttempts must not be negative.'),
        assert(multiplier >= 1, 'multiplier must be at least 1.');

  static const none = SseReconnectPolicy(enabled: false, maxAttempts: 0);

  final bool enabled;

  /// Maximum reconnections after consecutive failures.
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final SseBackoffMode mode;
  final double multiplier;

  Duration delayForAttempt(int zeroBasedAttempt, {Duration? serverHint}) {
    if (zeroBasedAttempt < 0) {
      throw ArgumentError.value(
        zeroBasedAttempt,
        'zeroBasedAttempt',
        'must not be negative',
      );
    }
    final base = serverHint ?? initialDelay;
    if (base.isNegative || maxDelay.isNegative) {
      throw ArgumentError(
        'SSE reconnect delays must not be negative.',
      );
    }
    final factor = switch (mode) {
      SseBackoffMode.constant => 1.0,
      SseBackoffMode.linear => zeroBasedAttempt + 1.0,
      SseBackoffMode.exponential =>
        math.pow(multiplier, zeroBasedAttempt).toDouble(),
    };
    final microseconds = math.min(
      (base.inMicroseconds * factor).round(),
      maxDelay.inMicroseconds,
    );
    return Duration(microseconds: microseconds);
  }
}

/// Context supplied immediately before an SSE reconnect delay.
@immutable
class SseReconnectAttempt {
  const SseReconnectAttempt({
    required this.attempt,
    required this.delay,
    this.lastEventId,
  });

  final int attempt;
  final Duration delay;
  final String? lastEventId;
}

typedef SseReconnectCallback = void Function(SseReconnectAttempt attempt);

/// SSE client with Last-Event-ID propagation and optional reconnection.
class SseAdapter extends TransportAdapter {
  SseAdapter({
    this.baseUri,
    http.Client? client,
    this.defaultHeaders = const {},
    this.headerProvider,
    this.defaultRetry = const Duration(seconds: 2),
    List<TransportMiddleware> middleware = const [],
    bool? ownsClient,
  })  : _client = client ?? http.Client(),
        _ownsClient = ownsClient ?? client == null,
        _pipeline = TransportMiddlewarePipeline(middleware);

  final Uri? baseUri;
  final Map<String, String> defaultHeaders;
  final HeaderProvider? headerProvider;
  final Duration defaultRetry;
  final http.Client _client;
  final bool _ownsClient;
  final TransportMiddlewarePipeline _pipeline;

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
    SseReconnectPolicy? reconnectPolicy,
    SseReconnectCallback? onReconnect,
    Future<void>? abortTrigger,
  }) {
    final uri = path is Uri ? path : Uri.parse(path.toString());
    final policy = reconnectPolicy ??
        SseReconnectPolicy(
          enabled: reconnect,
          maxAttempts: maxReconnectAttempts,
          initialDelay: defaultRetry,
        );
    final request = TransportRequest(
      protocol: protocol,
      uri: _resolveUri(uri, queryParameters),
      headers: headers,
      metadata: {
        'reconnectPolicy': policy,
        if (onReconnect != null) 'onReconnect': onReconnect,
      },
      abortTrigger: abortTrigger,
    );
    return openStream(request).map(
      (event) => SseEvent(
        data: event.data,
        id: event.id,
        event: event.event,
        retry: event.retry,
      ),
    );
  }

  @override
  Stream<TransportEvent> openStream(TransportRequest request) {
    return _pipeline.openStream(request, _openStream);
  }

  Stream<TransportEvent> _openStream(TransportRequest request) {
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
    final policy = request.metadata['reconnectPolicy'] as SseReconnectPolicy? ??
        SseReconnectPolicy(initialDelay: defaultRetry);
    final onReconnect =
        request.metadata['onReconnect'] as SseReconnectCallback?;
    var attempts = 0;
    Duration? serverRetry;
    String? lastEventId;

    while (true) {
      Object? failure;
      StackTrace? failureStackTrace;
      try {
        await for (final event in _connectOnce(request, lastEventId)) {
          if (event.id != null) lastEventId = event.id;
          if (event.retry != null) serverRetry = event.retry;
          attempts = 0;
          yield event;
        }
      } on TransportAbortedException {
        rethrow;
      } catch (error, stackTrace) {
        failure = error;
        failureStackTrace = stackTrace;
      }
      if (!policy.enabled || attempts >= policy.maxAttempts) {
        if (failure != null) {
          Error.throwWithStackTrace(failure, failureStackTrace!);
        }
        return;
      }
      final delay = policy.delayForAttempt(attempts, serverHint: serverRetry);
      attempts += 1;
      onReconnect?.call(
        SseReconnectAttempt(
          attempt: attempts,
          delay: delay,
          lastEventId: lastEventId,
        ),
      );
      await _waitForReconnect(request, delay);
    }
  }

  Future<void> _waitForReconnect(
    TransportRequest request,
    Duration delay,
  ) async {
    final abortTrigger = request.abortTrigger;
    if (abortTrigger == null) {
      await Future<void>.delayed(delay);
      return;
    }
    final aborted = await Future.any([
      Future<bool>.delayed(delay, () => false),
      abortTrigger.then((_) => true),
    ]);
    if (aborted) {
      throw TransportAbortedException(
        protocol: request.protocol,
        uri: request.uri,
      );
    }
  }

  Stream<SseEvent> _connectOnce(
    TransportRequest request,
    String? lastEventId,
  ) async* {
    final uri = _resolveUri(request.uri, request.queryParameters);
    try {
      final dynamicHeaders = await headerProvider?.call() ?? const {};
      final headers = <String, String>{
        'accept': 'text/event-stream',
        'cache-control': 'no-cache',
        ...defaultHeaders,
        ...dynamicHeaders,
        ...request.headers,
        if (lastEventId != null) 'last-event-id': lastEventId,
      };
      final httpRequest = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: request.abortTrigger,
      )..headers.addAll(headers);
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
    } on http.RequestAbortedException catch (error) {
      throw TransportAbortedException(
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
