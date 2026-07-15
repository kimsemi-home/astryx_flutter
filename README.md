# Astryx Flutter

Astryx-inspired atomic UI and a pluggable transport layer for Flutter.

`astryx_flutter` ports the public **Astryx neutral design tokens** into a
Flutter `ThemeExtension`, organizes reusable widgets with **Atomic Design**, and
offers one runtime registry for **REST, GraphQL, Server-Sent Events, and
HATEOAS**.

> Experimental `0.1.0`. This is an independent community project, not an
> official Meta or Astryx Flutter port.

## Why this shape?

UI composition and backend transport evolve at different speeds. This package
keeps them connected by explicit contracts without coupling widgets to a
specific cache, state-management package, generated GraphQL client, or server
format.

| Area | Included |
| --- | --- |
| Theme | Astryx neutral light/dark semantic and categorical tokens |
| Atomic UI | atoms → molecules → organisms → templates → pages |
| REST | injectable `package:http` client, JSON decoding, dynamic headers |
| GraphQL | query/mutation envelopes and separate HTTP/GraphQL errors |
| SSE | incremental parser, `Last-Event-ID`, server retry, reconnection |
| HATEOAS | HAL `_links`, generic `links`, URI templates, relation following |
| Runtime | capability-aware registry, middleware, cancellation, composition root |

## Quick start

Until a pub.dev release, depend on the repository:

```yaml
dependencies:
  astryx_flutter:
    git:
      url: https://github.com/kimsemi-home/astryx_flutter.git
```

Install the theme at the app root:

```dart
MaterialApp(
  theme: AstryxTheme.light(),
  darkTheme: AstryxTheme.dark(),
  home: const MyPage(),
);
```

Compose the transport runtime:

```dart
final framework = AstryxFramework.standard(
  restBaseUri: Uri.parse('https://api.example.com/'),
  graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
  defaultHeaders: {'x-client': 'my-app'},
  headerProvider: () async => {'authorization': 'Bearer $token'},
  middleware: [CorrelationIdMiddleware()],
);

final users = await framework.rest.get('/users');

final viewer = await framework.graphql.execute(
  const GraphqlOperation(document: r'query { viewer { id name } }'),
);

await for (final event in framework.sse.connect('/events')) {
  print(event.data);
}

final root = await framework.hateoas.send(
  TransportRequest(
    protocol: AstryxProtocol.hateoas,
    uri: Uri.parse('/orders/42'),
  ),
);
final document = framework.hateoas.document(root);
final next = await framework.hateoas.follow(document, 'next');

framework.close();
```

All adapters accept an external `http.Client`, so applications can select
platform-native clients, test doubles, retry clients, or tracing wrappers.

## Cross-protocol behavior

Middleware runs in registration order for REST, GraphQL, SSE, and HATEOAS
without erasing their protocol-specific APIs:

```dart
class CorrelationIdMiddleware extends TransportMiddleware {
  @override
  Future<TransportResponse> intercept(
    TransportRequest request,
    TransportNext next,
  ) {
    return next(request.copyWith(headers: {
      ...request.headers,
      'x-correlation-id': createCorrelationId(),
    }));
  }
}
```

Requests also accept an `abortTrigger` compatible with
`package:http`'s abortable request lifecycle. SSE can use constant, linear, or
exponential reconnect policies and never retries an intentional abort.

Decoded payloads remain application-owned through `TransportResponse.decode`,
`GraphqlResponse.parseData`, and `HypermediaDocument.embeddedList`.

## Atomic Design

```text
lib/src/atomic/
├── atoms/       badge, button, status dot, surface
├── molecules/   metric card, protocol tile
├── organisms/   responsive transport board
├── templates/   responsive dashboard shell
└── pages/       runnable framework showcase
```

The public library exports each layer. Product code can stop at atoms, assemble
its own organisms, or use the complete showcase as a reference implementation.

## Run the showcase

```sh
cd example
flutter run -d chrome
```

The example has Android, iOS, Linux, macOS, web, and Windows runners and does
not make external network calls.

## Architecture and guides

- [Architecture](doc/architecture.md)
- [Transport guide](doc/transports.md)
- [Astryx token mapping and provenance](doc/astryx-mapping.md)
- [Ecosystem learnings and design decisions](doc/ecosystem-learnings.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## Verification

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test

cd example
flutter pub get
flutter test
flutter build web --release
```

## 한국어 요약

Astryx neutral 디자인 토큰을 Flutter 테마로 옮기고, UI는 Atomic Design
5단계로 구성했습니다. 데이터 계층은 REST·GraphQL·SSE·HATEOAS를 하나의
registry에서 선택할 수 있지만 각 프로토콜의 의미는 억지로 동일하게 만들지
않습니다. 앱에서는 필요한 adapter만 교체하거나 추가하면 됩니다.

## Attribution

The token values are derived from Meta's open-source
[Astryx](https://github.com/facebook/astryx) neutral theme, licensed under MIT.
The port is pinned to upstream version `0.1.5` and commit
`c4c1f5b4430b5b83470219bd382465ff1bc7b69e`. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for details.

This repository's original Dart and Flutter code is MIT licensed.
