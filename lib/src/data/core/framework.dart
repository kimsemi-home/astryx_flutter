import 'package:http/http.dart' as http;

import '../graphql/graphql_adapter.dart';
import '../hateoas/hateoas_adapter.dart';
import '../rest/rest_adapter.dart';
import '../sse/sse_adapter.dart';
import 'transport.dart';
import 'transport_registry.dart';

/// Convenience composition root for the four built-in protocol adapters.
class AstryxFramework {
  AstryxFramework({required this.registry});

  factory AstryxFramework.standard({
    required Uri restBaseUri,
    required Uri graphqlEndpoint,
    Uri? sseBaseUri,
    Uri? hateoasBaseUri,
    http.Client? sharedClient,
    Map<String, String> defaultHeaders = const {},
    HeaderProvider? headerProvider,
  }) {
    return AstryxFramework(
      registry: TransportRegistry([
        RestAdapter(
          baseUri: restBaseUri,
          client: sharedClient,
          defaultHeaders: defaultHeaders,
          headerProvider: headerProvider,
        ),
        GraphqlAdapter(
          endpoint: graphqlEndpoint,
          client: sharedClient,
          defaultHeaders: defaultHeaders,
          headerProvider: headerProvider,
        ),
        SseAdapter(
          baseUri: sseBaseUri ?? restBaseUri,
          client: sharedClient,
          defaultHeaders: defaultHeaders,
          headerProvider: headerProvider,
        ),
        HateoasAdapter(
          baseUri: hateoasBaseUri ?? restBaseUri,
          client: sharedClient,
          defaultHeaders: defaultHeaders,
          headerProvider: headerProvider,
        ),
      ]),
    );
  }

  final TransportRegistry registry;

  RestAdapter get rest => registry.adapter(AstryxProtocol.rest);
  GraphqlAdapter get graphql => registry.adapter(AstryxProtocol.graphql);
  SseAdapter get sse => registry.adapter(AstryxProtocol.sse);
  HateoasAdapter get hateoas => registry.adapter(AstryxProtocol.hateoas);

  void close() => registry.close();
}
