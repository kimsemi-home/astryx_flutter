# Transport guide

## Shared composition root

```dart
final framework = AstryxFramework.standard(
  restBaseUri: Uri.parse('https://api.example.com/'),
  graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
  sseBaseUri: Uri.parse('https://events.example.com/'),
  hateoasBaseUri: Uri.parse('https://api.example.com/'),
  headerProvider: () async => {'authorization': await tokenProvider()},
  middleware: [correlationIdMiddleware],
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

final typedOrder = response.decode(Order.fromJsonBody);
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

final order = result.parseData(Order.fromGraphqlData);
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
  reconnectPolicy: const SseReconnectPolicy(
    maxAttempts: 5,
    mode: SseBackoffMode.exponential,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 20),
  ),
  onReconnect: (attempt) => log(
    'Reconnect ${attempt.attempt} after ${attempt.delay}',
  ),
)) {
  final payload = event.decodeJson();
  log('${event.id}: $payload');
}
```

The SSE adapter incrementally decodes UTF-8, joins repeated `data:` lines,
ignores comments, tracks `id`, honors `retry`, and sends `Last-Event-ID` after
a reconnect. Set `reconnect: false` for finite or test streams.
`reconnect` and `maxReconnectAttempts` remain available as shorthand. An
explicit `SseReconnectPolicy` takes precedence and counts consecutive failed
connections; receiving an event resets the failure count.

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
final orders = document.embeddedList('orders', Order.fromJson);
final next = await framework.hateoas.follow(
  document,
  'next',
  variables: {'page': 2, 'size': 20},
);
```

URI template support currently covers simple path variables (`{id}`) and query
expressions (`{?page,size}` / `{&cursor}`).

## Cancellation

Completing a request's abort trigger asks supported HTTP clients to stop at any
point in the request/response lifecycle:

```dart
final abort = Completer<void>();
final pending = framework.rest.get('/slow', abortTrigger: abort.future);

abort.complete();

try {
  await pending;
} on TransportAbortedException {
  // Intentional cancellation is distinct from network failure.
}
```

The same field is available on `GraphqlOperation`, `SseAdapter.connect`, and
`HateoasAdapter.follow`. SSE aborts also interrupt reconnect delays and are not
retried.

## Middleware

`TransportMiddleware.intercept` handles request/response transports and
`interceptStream` handles streaming. Default implementations pass through, so
a middleware can opt into only the lifecycle it needs. Middleware should avoid
logging authorization headers or raw sensitive response bodies.

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
