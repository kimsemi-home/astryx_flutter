# Transport guide

## Shared composition root

```dart
final framework = AstryxFramework.standard(
  restBaseUri: Uri.parse('https://api.example.com/'),
  graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
  sseBaseUri: Uri.parse('https://events.example.com/'),
  hateoasBaseUri: Uri.parse('https://api.example.com/'),
  headerProvider: () async => {'authorization': await tokenProvider()},
);
```

Call `framework.close()` when the runtime owns its HTTP clients. If you inject a
shared client, the caller retains ownership and must close it.

## REST

```dart
final response = await framework.rest.post(
  '/orders',
  queryParameters: {'dryRun': true},
  body: {'sku': 'demo-42', 'quantity': 1},
);

response.ensureSuccess();
final order = response.requireJsonObject();
```

Non-2xx responses remain inspectable. Call `ensureSuccess()` when your boundary
should convert them into `TransportException`.

## GraphQL

```dart
final result = await framework.graphql.execute(
  const GraphqlOperation(
    document: r'''
      query Order($id: ID!) {
        order(id: $id) { id status }
      }
    ''',
    operationName: 'Order',
    variables: {'id': '42'},
  ),
);

if (result.hasErrors) {
  for (final error in result.errors) {
    log(error.message);
  }
}
```

This adapter covers GraphQL queries and mutations over HTTP. It intentionally
does not provide normalized caching, code generation, or WebSocket
subscriptions. Those remain application-level choices and can coexist with
the registry.

## Server-Sent Events

```dart
await for (final event in framework.sse.connect(
  '/events',
  queryParameters: {'topic': 'orders'},
  maxReconnectAttempts: 5,
)) {
  final payload = event.decodeJson();
  log('${event.id}: $payload');
}
```

The SSE adapter incrementally decodes UTF-8, joins repeated `data:` lines,
ignores comments, tracks `id`, honors `retry`, and sends `Last-Event-ID` after
a reconnect. Set `reconnect: false` for finite or test streams.

## HATEOAS and HAL

The adapter accepts both HAL `_links` objects and generic `links` arrays:

```json
{
  "_links": {
    "self": {"href": "/orders/42"},
    "next": {"href": "/orders{?page,size}", "templated": true}
  }
}
```

```dart
final response = await framework.hateoas.send(
  TransportRequest(
    protocol: AstryxProtocol.hateoas,
    uri: Uri.parse('/orders/42'),
  ),
);
final document = framework.hateoas.document(response);
final next = await framework.hateoas.follow(
  document,
  'next',
  variables: {'page': 2, 'size': 20},
);
```

URI template support currently covers simple path variables (`{id}`) and query
expressions (`{?page,size}` / `{&cursor}`).

## Testing

All default adapters accept `package:http/testing.dart`'s `MockClient`:

```dart
final adapter = RestAdapter(
  baseUri: Uri.parse('https://api.example.com/'),
  client: MockClient((request) async {
    return http.Response('{"ok":true}', 200,
      headers: {'content-type': 'application/json'});
  }),
);
```
