import 'dart:async';
import 'dart:convert';

import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('middleware composes in registration order', () async {
    final trace = <String>[];
    late http.Request captured;
    final adapter = RestAdapter(
      baseUri: Uri.parse('https://api.example.com/'),
      middleware: [
        _TraceMiddleware('outer', trace),
        _TraceMiddleware('inner', trace),
      ],
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'value': 7}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await adapter.get('/value');

    expect(
      trace,
      ['outer:before', 'inner:before', 'inner:after', 'outer:after'],
    );
    expect(captured.headers['x-outer'], 'enabled');
    expect(captured.headers['x-inner'], 'enabled');
    expect(response.decode((body) => (body! as Map)['value']), 7);
  });

  test('shared middleware reaches GraphQL and HATEOAS once', () async {
    final protocols = <AstryxProtocol>[];
    final middleware = _ProtocolMiddleware(protocols);
    final client = MockClient((request) async {
      final body = request.url.path.endsWith('graphql')
          ? jsonEncode({
              'data': {'viewer': 'Ada'},
            })
          : jsonEncode({
              '_links': {
                'self': {'href': '/orders/1'},
              },
            });
      return http.Response(
        body,
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final framework = AstryxFramework.standard(
      restBaseUri: Uri.parse('https://api.example.com/'),
      graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
      sharedClient: client,
      middleware: [middleware],
    );
    addTearDown(framework.close);

    final graphql = await framework.graphql.execute(
      const GraphqlOperation(document: 'query { viewer }'),
    );
    final hypermedia = await framework.hateoas.send(
      TransportRequest(
        protocol: AstryxProtocol.hateoas,
        uri: Uri.parse('/orders/1'),
      ),
    );

    expect(graphql.parseData((data) => data['viewer']), 'Ada');
    expect(framework.hateoas.document(hypermedia).relations, contains('self'));
    expect(
      protocols,
      [AstryxProtocol.graphql, AstryxProtocol.hateoas],
    );
  });

  test('REST propagates abort triggers and normalizes abort failures',
      () async {
    final abort = Completer<void>();
    late http.AbortableRequest captured;
    final adapter = RestAdapter(
      baseUri: Uri.parse('https://api.example.com/'),
      client: MockClient.streaming((request, _) async {
        captured = request as http.AbortableRequest;
        throw http.RequestAbortedException(request.url);
      }),
    );

    await expectLater(
      adapter.get('/slow', abortTrigger: abort.future),
      throwsA(isA<TransportAbortedException>()),
    );
    expect(captured.abortTrigger, same(abort.future));
  });

  test('stream middleware transforms SSE requests', () async {
    final adapter = SseAdapter(
      baseUri: Uri.parse('https://api.example.com/'),
      middleware: const [_StreamHeaderMiddleware()],
      client: MockClient.streaming((request, _) async {
        expect(request.headers['x-stream-policy'], 'enabled');
        return http.StreamedResponse(
          Stream.value(utf8.encode('data: ready\n\n')),
          200,
        );
      }),
    );

    final event = await adapter.connect('/events', reconnect: false).single;

    expect(event.data, 'ready');
  });
}

class _TraceMiddleware extends TransportMiddleware {
  const _TraceMiddleware(this.name, this.trace);

  final String name;
  final List<String> trace;

  @override
  Future<TransportResponse> intercept(
    TransportRequest request,
    TransportNext next,
  ) async {
    trace.add('$name:before');
    final response = await next(
      request.copyWith(
        headers: {...request.headers, 'x-$name': 'enabled'},
      ),
    );
    trace.add('$name:after');
    return response;
  }
}

class _ProtocolMiddleware extends TransportMiddleware {
  const _ProtocolMiddleware(this.protocols);

  final List<AstryxProtocol> protocols;

  @override
  Future<TransportResponse> intercept(
    TransportRequest request,
    TransportNext next,
  ) {
    protocols.add(request.protocol);
    return next(request);
  }
}

class _StreamHeaderMiddleware extends TransportMiddleware {
  const _StreamHeaderMiddleware();

  @override
  Stream<TransportEvent> interceptStream(
    TransportRequest request,
    TransportStreamNext next,
  ) {
    return next(
      request.copyWith(
        headers: {...request.headers, 'x-stream-policy': 'enabled'},
      ),
    );
  }
}
