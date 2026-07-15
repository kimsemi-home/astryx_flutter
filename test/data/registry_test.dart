import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry reports adapter capabilities', () {
    final registry = TransportRegistry([
      RestAdapter(baseUri: Uri.parse('https://api.example.com/')),
      SseAdapter(baseUri: Uri.parse('https://api.example.com/')),
    ]);
    addTearDown(registry.close);

    expect(
      registry.supports(
        AstryxProtocol.rest,
        TransportCapability.requestResponse,
      ),
      isTrue,
    );
    expect(
      registry.supports(AstryxProtocol.sse, TransportCapability.streaming),
      isTrue,
    );
    expect(
      registry.supports(AstryxProtocol.graphql),
      isFalse,
    );
  });

  test('registry prevents accidental adapter replacement', () {
    final registry = TransportRegistry([
      RestAdapter(baseUri: Uri.parse('https://api.example.com/')),
    ]);
    addTearDown(registry.close);

    expect(
      () => registry.register(
        RestAdapter(baseUri: Uri.parse('https://other.example.com/')),
      ),
      throwsStateError,
    );
  });
}
