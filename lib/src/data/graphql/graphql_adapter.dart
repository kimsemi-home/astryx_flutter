import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../core/transport.dart';
import '../core/transport_middleware.dart';
import '../rest/rest_adapter.dart';

/// A typed GraphQL-over-HTTP operation.
@immutable
class GraphqlOperation {
  const GraphqlOperation({
    required this.document,
    this.variables = const {},
    this.operationName,
    this.headers = const {},
    this.abortTrigger,
  });

  final String document;
  final Map<String, Object?> variables;
  final String? operationName;
  final Map<String, String> headers;
  final Future<void>? abortTrigger;

  Map<String, Object?> toJson() => {
        'query': document,
        if (operationName != null) 'operationName': operationName,
        if (variables.isNotEmpty) 'variables': variables,
      };
}

@immutable
class GraphqlError {
  const GraphqlError({
    required this.message,
    this.path = const [],
    this.locations = const [],
    this.extensions = const {},
  });

  factory GraphqlError.fromJson(Map<String, Object?> json) {
    return GraphqlError(
      message: json['message']?.toString() ?? 'Unknown GraphQL error',
      path: (json['path'] as List?)?.cast<Object?>() ?? const [],
      locations: (json['locations'] as List?)?.cast<Object?>() ?? const [],
      extensions:
          (json['extensions'] as Map?)?.cast<String, Object?>() ?? const {},
    );
  }

  final String message;
  final List<Object?> path;
  final List<Object?> locations;
  final Map<String, Object?> extensions;
}

/// Decoded GraphQL envelope. HTTP errors and GraphQL errors remain distinct.
@immutable
class GraphqlResponse {
  const GraphqlResponse({
    required this.transport,
    this.data,
    this.errors = const [],
    this.extensions = const {},
  });

  factory GraphqlResponse.fromTransport(TransportResponse response) {
    response.ensureSuccess();
    final json = response.requireJsonObject();
    final rawErrors = json['errors'] as List? ?? const [];
    return GraphqlResponse(
      transport: response,
      data: (json['data'] as Map?)?.cast<String, Object?>(),
      errors: rawErrors
          .whereType<Map>()
          .map((value) => GraphqlError.fromJson(value.cast<String, Object?>()))
          .toList(growable: false),
      extensions:
          (json['extensions'] as Map?)?.cast<String, Object?>() ?? const {},
    );
  }

  final TransportResponse transport;
  final Map<String, Object?>? data;
  final List<GraphqlError> errors;
  final Map<String, Object?> extensions;

  bool get hasErrors => errors.isNotEmpty;

  /// Converts the GraphQL `data` object into an application-owned type.
  T parseData<T>(T Function(Map<String, Object?> data) parser) {
    final value = data;
    if (value == null) {
      throw TransportException(
        'Expected a GraphQL data object.',
        protocol: AstryxProtocol.graphql,
        uri: transport.request.uri,
        statusCode: transport.statusCode,
        responseBody: transport.rawBody,
      );
    }
    return parser(value);
  }
}

/// GraphQL query/mutation adapter with no widget or cache lock-in.
class GraphqlAdapter extends TransportAdapter {
  GraphqlAdapter({
    required this.endpoint,
    http.Client? client,
    this.defaultHeaders = const {},
    HeaderProvider? headerProvider,
    List<TransportMiddleware> middleware = const [],
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _pipeline = TransportMiddlewarePipeline(middleware) {
    _rest = RestAdapter(
      client: _client,
      ownsClient: false,
      defaultHeaders: defaultHeaders,
      headerProvider: headerProvider,
    );
  }

  final Uri endpoint;
  final Map<String, String> defaultHeaders;
  final http.Client _client;
  final bool _ownsClient;
  final TransportMiddlewarePipeline _pipeline;
  late final RestAdapter _rest;

  @override
  AstryxProtocol get protocol => AstryxProtocol.graphql;

  @override
  Set<TransportCapability> get capabilities => const {
        TransportCapability.requestResponse,
      };

  Future<GraphqlResponse> execute(GraphqlOperation operation) async {
    final response = await send(
      TransportRequest(
        protocol: protocol,
        uri: endpoint,
        method: HttpMethod.post,
        operation: operation.document,
        headers: operation.headers,
        body: operation.toJson(),
        abortTrigger: operation.abortTrigger,
      ),
    );
    return GraphqlResponse.fromTransport(response);
  }

  @override
  Future<TransportResponse> send(TransportRequest request) {
    return _pipeline.send(request, _send);
  }

  Future<TransportResponse> _send(TransportRequest request) async {
    final operation = request.operation;
    Object? body = request.body;
    if (body == null && operation != null) body = {'query': operation};
    if (body is! Map || body['query'] == null) {
      throw ArgumentError(
        'GraphQL requests require an operation or a body containing query.',
      );
    }
    final response = await _rest.send(
      request.copyWith(
        protocol: protocol,
        uri: request.uri.hasScheme ? request.uri : endpoint,
        method: HttpMethod.post,
        headers: {
          'accept': 'application/graphql-response+json, application/json',
          ...request.headers,
        },
        body: body,
      ),
    );
    return response;
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
