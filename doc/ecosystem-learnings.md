# Ecosystem learnings

This document records the public implementations reviewed before extending
Astryx Flutter's transport and atomic UI APIs. The patterns were independently
adapted to this package's contracts; source code was not copied.

The review was pinned on 2026-07-15 so future changes can compare the same
upstream state.

| Repository | Reviewed revision | Lesson applied here |
| --- | --- | --- |
| `dart-lang/http` | [`fe4aaa9`](https://github.com/dart-lang/http/commit/fe4aaa900d50f0423200dd333314729d2c0650b9) | Cancellation belongs to the complete request lifecycle, and intentional aborts should not be retried. |
| `graphql-flutter` | [`91e50cf`](https://github.com/zino-hofmann/graphql-flutter/commit/91e50cf611055edb29e4982ccb11b368cd4522ee) | Link-style request behavior composes cleanly when each layer can transform a request and call the next layer. |
| `EventFlux` | [`bd1bb77`](https://github.com/Imgkl/EventFlux/commit/bd1bb7727f79cb27bb3fa75c1f21bc2a50eb0d35) | Reconnection needs explicit policy, backoff progression, callbacks, and disconnect semantics. |
| `rest-resource-dart` | [`2af9e8b`](https://github.com/slyjeff/rest-resource-dart/commit/2af9e8b3fba82a22ae6e15b87a4c0c3c62c78710) | Hypermedia parsing can offer typed decoder hooks without owning application domain models. |
| `flutter-shadcn-ui` | [`a411b4d`](https://github.com/nank1ro/flutter-shadcn-ui/commit/a411b4d855056f43fcb3891e24c3aa55b3a3a7d1) | Common visual variants deserve discoverable named constructors while the base constructor remains an escape hatch. |
| `very_good_analysis` | [`78354f9`](https://github.com/VeryGoodOpenSource/very_good_analysis/commit/78354f938206bfee41d0c7ed87d0900130c99564) | CI benefits from randomized test order, coverage, publish validation, and cancellation of superseded runs. |

## Decisions adopted

- One immutable middleware list can be passed through `AstryxFramework` to all
  built-in adapters. Request/response and stream interception stay separate.
- `TransportRequest.abortTrigger` maps `package:http` abort failures to
  `TransportAbortedException`. REST, GraphQL, SSE, and HATEOAS expose it.
- `SseReconnectPolicy` supports constant, linear, and exponential delay,
  server `retry:` hints, a maximum delay, reconnect callbacks, and consecutive
  failure counting.
- Transport, GraphQL, and hypermedia responses expose small typed decoder
  hooks. Domain model generation remains outside this package.
- Badges and buttons expose named semantic constructors while keeping their
  original configurable constructors.

## Decisions deliberately not adopted

- No normalized GraphQL cache, generated query model, or WebSocket subscription
  runtime. Those choices are larger than a transport registry and can be added
  above or beside Astryx.
- No global SSE singleton. Stream ownership and shutdown remain explicit per
  adapter instance.
- No automatic request or response body logging. Middleware can implement
  observability, but secrets and personal data must be redacted by the app.
- No mandatory typed HATEOAS resource base class. Decoder callbacks avoid
  coupling domain models to a wire format.
- No new analysis meta-package dependency yet. The useful CI practices were
  adopted without expanding the public dependency surface.

## Revisit triggers

Reconsider the omitted features only when a concrete application requires
cache normalization, subscription protocols, code generation, or standardized
telemetry. At that point, prefer a separate optional package or adapter over
making the lightweight core mandatory for every consumer.
