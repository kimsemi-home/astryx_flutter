import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ports the pinned Astryx neutral light and dark tokens', () {
    expect(AstryxSource.version, '0.1.5');
    expect(AstryxTokens.light.body, const Color(0xFFF1F1F1));
    expect(AstryxTokens.dark.body, const Color(0xFF1B1B1B));
    expect(
      AstryxTokens.light.category(AstryxCategory.teal).background,
      const Color(0xFFA5E3D6),
    );
  });

  testWidgets('composes and navigates the five atomic layers', (tester) async {
    final framework = AstryxFramework.standard(
      restBaseUri: Uri.parse('https://api.example.com/'),
      graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
    );
    addTearDown(framework.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AstryxTheme.light(),
        home: AstryxShowcasePage(registry: framework.registry),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atomic UI.\nAny backend shape.'), findsOneWidget);
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('GRAPHQL'), findsOneWidget);
    expect(find.text('SSE'), findsOneWidget);
    expect(find.text('HATEOAS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.widgets_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Atomic UI catalog'), findsOneWidget);
    expect(find.text('Atoms · badges'), findsOneWidget);
    expect(find.text('Molecules → organisms'), findsOneWidget);
  });
}
