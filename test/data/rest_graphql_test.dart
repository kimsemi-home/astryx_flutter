import 'dart:convert';

import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('RestAdapter', () {
    test('resolves paths, query parameters, headers, and JSON', () async {
      late http.Request captured;
      final adapter = RestAdapter(
        baseUri: Uri.parse('https://api.example.com/v1/'),
        defaultHeaders: const {'x-client': 'astryx'},
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({'ok': true}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final response = await adapter.get(
        'users',
        queryParameters: {'page': 2},
      );

      expect(
          captured.url.toString(), 'https://api.example.com/v1/users?page=2');
      expect(captured.headers['x-client'], 'astryx');
      expect(response.requireJsonObject(), {'ok': true});
      expect(response.isSuccess, isTrue);
    });

    test('keeps non-2xx responses inspectable until ensureSuccess', () async {
      final adapter = RestAdapter(
        baseUri: Uri.parse('https://api.example.com/'),
        client: MockClient((_) async => http.Response('missing', 404)),
      );

      final response = await adapter.get('missing');

      expect(response.statusCode, 404);
      expect(response.body, 'missing');
      expect(response.ensureSuccess, throwsA(isA<TransportException>()));
    });
  });

  group('GraphqlAdapter', () {
    test('encodes an operation and separates GraphQL errors', () async {
      late http.Request captured;
      final adapter = GraphqlAdapter(
        endpoint: Uri.parse('https://api.example.com/graphql'),
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'data': {'viewer': null},
              'errors': [
                {
                  'message': 'Not signed in',
                  'path': ['viewer']
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await adapter.execute(
        const GraphqlOperation(
          document: r'query Viewer($locale: String!) { viewer { id } }',
          operationName: 'Viewer',
          variables: {'locale': 'ko-KR'},
        ),
      );

      final body = jsonDecode(captured.body) as Map<String, Object?>;
      expect(captured.method, 'POST');
      expect(body['operationName'], 'Viewer');
      expect(body['variables'], {'locale': 'ko-KR'});
      expect(result.hasErrors, isTrue);
      expect(result.errors.single.message, 'Not signed in');
    });
  });
}
