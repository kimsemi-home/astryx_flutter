import 'dart:convert';

import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('SseDecoder combines data lines and preserves event metadata', () async {
    final chunks = Stream<List<int>>.fromIterable([
      utf8.encode('id: 42\nevent: update\ndata: {"part":1}\n'),
      utf8.encode('data: {"part":2}\nretry: 1500\n\n'),
    ]);

    final events = await chunks.transform(const SseDecoder()).toList();

    expect(events, hasLength(1));
    expect(events.single.id, '42');
    expect(events.single.event, 'update');
    expect(events.single.data, '{"part":1}\n{"part":2}');
    expect(events.single.retry, const Duration(milliseconds: 1500));
  });

  test('SseAdapter exposes a normalized stream through the registry', () async {
    final adapter = SseAdapter(
      baseUri: Uri.parse('https://api.example.com/'),
      client: MockClient.streaming((request, _) async {
        expect(request.headers['accept'], 'text/event-stream');
        return http.StreamedResponse(
          Stream.value(utf8.encode('data: ready\n\n')),
          200,
        );
      }),
    );

    final event = await adapter.connect('events', reconnect: false).single;

    expect(event.data, 'ready');
  });

  test('parses HAL and follows a templated relation', () async {
    late http.Request captured;
    final adapter = HateoasAdapter(
      baseUri: Uri.parse('https://api.example.com/'),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            '_links': {
              'self': {'href': '/orders/7'},
              'next': {
                'href': '/orders{?page,size}',
                'templated': true,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/hal+json'},
        );
      }),
    );

    final root = await adapter.send(
      TransportRequest(
        protocol: AstryxProtocol.hateoas,
        uri: Uri.parse('/orders/7'),
      ),
    );
    final document = adapter.document(root);
    await adapter.follow(
      document,
      'next',
      variables: {'page': 2, 'size': 20},
    );

    expect(document.relations, containsAll(['self', 'next']));
    expect(captured.url.toString(),
        'https://api.example.com/orders?page=2&size=20');
  });

  test('parses generic links arrays and link methods', () {
    final document = HypermediaDocument.fromJson(
      {
        'links': [
          {'rel': 'update', 'href': '/items/3', 'method': 'PATCH'},
        ],
      },
      baseUri: Uri.parse('https://api.example.com/items/3'),
    );

    final update = document.requireLink('update');
    expect(update.method, HttpMethod.patch);
    expect(update.resolve(document.baseUri).toString(),
        'https://api.example.com/items/3');
  });
}
