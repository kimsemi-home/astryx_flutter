import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../core/transport.dart';
import '../rest/rest_adapter.dart';

/// A relation from a HAL or generic HATEOAS document.
@immutable
class HypermediaLink {
  const HypermediaLink({
    required this.relation,
    required this.href,
    this.method = HttpMethod.get,
    this.templated = false,
    this.title,
    this.type,
  });

  factory HypermediaLink.fromJson(
    String relation,
    Map<String, Object?> json,
  ) {
    final method = json['method']?.toString();
    return HypermediaLink(
      relation: relation,
      href: json['href']?.toString() ??
          (throw const FormatException('Hypermedia link is missing href.')),
      method: method == null ? HttpMethod.get : HttpMethod.parse(method),
      templated:
          json['templated'] == true || json['href'].toString().contains('{'),
      title: json['title']?.toString(),
      type: json['type']?.toString(),
    );
  }

  final String relation;
  final String href;
  final HttpMethod method;
  final bool templated;
  final String? title;
  final String? type;

  Uri resolve(Uri baseUri, [Map<String, Object?> variables = const {}]) {
    final expanded = _expandTemplate(href, variables);
    final uri = Uri.parse(expanded);
    return uri.hasScheme ? uri : baseUri.resolveUri(uri);
  }

  String _expandTemplate(String template, Map<String, Object?> variables) {
    final expression = RegExp(r'\{([?&]?)([^}]+)\}');
    return template.replaceAllMapped(expression, (match) {
      final operator = match.group(1)!;
      final names = match.group(2)!.split(',');
      if (operator == '?' || operator == '&') {
        final pairs = <String>[];
        for (final name in names) {
          final value = variables[name];
          if (value != null) {
            pairs.add(
              '${Uri.encodeQueryComponent(name)}='
              '${Uri.encodeQueryComponent(value.toString())}',
            );
          }
        }
        if (pairs.isEmpty) return '';
        return '$operator${pairs.join('&')}';
      }
      if (names.length != 1 || !variables.containsKey(names.single)) {
        throw ArgumentError('Missing URI template value: ${names.join(', ')}');
      }
      return Uri.encodeComponent(variables[names.single].toString());
    });
  }
}

/// Parsed links and embedded payload from a hypermedia response.
@immutable
class HypermediaDocument {
  const HypermediaDocument({
    required this.source,
    required this.baseUri,
    required this.links,
    this.embedded = const {},
  });

  factory HypermediaDocument.fromResponse(TransportResponse response) {
    return HypermediaDocument.fromJson(
      response.requireJsonObject(),
      baseUri: response.request.uri,
    );
  }

  factory HypermediaDocument.fromJson(
    Map<String, Object?> json, {
    required Uri baseUri,
  }) {
    final links = <String, List<HypermediaLink>>{};
    final halLinks = json['_links'];
    if (halLinks is Map) {
      for (final entry in halLinks.entries) {
        final relation = entry.key.toString();
        final value = entry.value;
        final values = value is List ? value : [value];
        for (final item in values.whereType<Map>()) {
          links.putIfAbsent(relation, () => []).add(
                HypermediaLink.fromJson(
                  relation,
                  item.cast<String, Object?>(),
                ),
              );
        }
      }
    }
    final genericLinks = json['links'];
    if (genericLinks is List) {
      for (final item in genericLinks.whereType<Map>()) {
        final map = item.cast<String, Object?>();
        final relation = map['rel']?.toString();
        if (relation == null) continue;
        links
            .putIfAbsent(relation, () => [])
            .add(HypermediaLink.fromJson(relation, map));
      }
    }
    return HypermediaDocument(
      source: json,
      baseUri: baseUri,
      links: Map.unmodifiable({
        for (final entry in links.entries)
          entry.key: List<HypermediaLink>.unmodifiable(entry.value),
      }),
      embedded:
          (json['_embedded'] as Map?)?.cast<String, Object?>() ?? const {},
    );
  }

  final Map<String, Object?> source;
  final Uri baseUri;
  final Map<String, List<HypermediaLink>> links;
  final Map<String, Object?> embedded;

  Iterable<String> get relations => links.keys;

  List<HypermediaLink> linksFor(String relation) => links[relation] ?? const [];

  HypermediaLink requireLink(String relation, {int index = 0}) {
    final matches = linksFor(relation);
    if (index < 0 || index >= matches.length) {
      throw StateError('No hypermedia link for relation "$relation".');
    }
    return matches[index];
  }
}

/// REST-backed HATEOAS adapter that understands HAL and generic link arrays.
class HateoasAdapter extends TransportAdapter {
  HateoasAdapter({
    this.baseUri,
    http.Client? client,
    Map<String, String> defaultHeaders = const {},
    HeaderProvider? headerProvider,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null {
    _rest = RestAdapter(
      baseUri: baseUri,
      client: _client,
      ownsClient: false,
      defaultHeaders: {
        'accept': 'application/hal+json, application/json',
        ...defaultHeaders,
      },
      headerProvider: headerProvider,
    );
  }

  final Uri? baseUri;
  final http.Client _client;
  final bool _ownsClient;
  late final RestAdapter _rest;

  @override
  AstryxProtocol get protocol => AstryxProtocol.hateoas;

  @override
  Set<TransportCapability> get capabilities => const {
        TransportCapability.requestResponse,
        TransportCapability.hypermedia,
      };

  @override
  Future<TransportResponse> send(TransportRequest request) {
    return _rest.send(request.copyWith(protocol: protocol));
  }

  HypermediaDocument document(TransportResponse response) {
    return HypermediaDocument.fromResponse(response);
  }

  Future<TransportResponse> follow(
    HypermediaDocument document,
    String relation, {
    int index = 0,
    Map<String, Object?> variables = const {},
    Map<String, String> headers = const {},
    Object? body,
  }) {
    final link = document.requireLink(relation, index: index);
    return send(
      TransportRequest(
        protocol: protocol,
        uri: link.resolve(document.baseUri, variables),
        method: link.method,
        headers: headers,
        body: body,
        metadata: {'relation': relation},
      ),
    );
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
