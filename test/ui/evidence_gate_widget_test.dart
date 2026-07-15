import 'package:astryx_flutter/astryx_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('evidence gate is legible in ${brightness.name}',
        (tester) async {
      var inspections = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.light
              ? AstryxTheme.light()
              : AstryxTheme.dark(),
          home: Scaffold(
            body: AstryxEvidenceGateCard(
              title: 'Publishing readiness',
              state: AstryxEvidenceState.passed,
              summary: 'All declared evidence criteria are bound.',
              evidenceDigest: 'sha256:0123456789abcdef0123456789abcdef',
              passedCriteria: 4,
              totalCriteria: 4,
              releasedSteps: const ['render', 'schedule'],
              onInspect: () => inspections++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Evidence passed'), findsOneWidget);
      expect(find.text('Released open-loop steps'), findsOneWidget);
      expect(find.text('render'), findsOneWidget);
      expect(find.text('schedule'), findsOneWidget);

      await tester.tap(find.text('Inspect evidence'));
      await tester.pump();
      expect(inspections, 1);
    });
  }

  testWidgets('non-passing evidence keeps the open loop closed',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AstryxTheme.light(),
        home: const Scaffold(
          body: AstryxEvidenceGateCard(
            title: 'Rights gate',
            state: AstryxEvidenceState.blocked,
            summary: 'A rights receipt is missing.',
            evidenceDigest: 'sha256:blocked',
            passedCriteria: 2,
            totalCriteria: 3,
            releasedSteps: ['must-not-render'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Evidence blocked'), findsOneWidget);
    expect(
      find.text('Open loop remains closed until evidence passes'),
      findsOneWidget,
    );
    expect(find.text('must-not-render'), findsNothing);
    expect(
      tester.getSemantics(find.byType(AstryxEvidenceGateCard)).label,
      contains('Open loop closed'),
    );
    semantics.dispose();
  });

  testWidgets('compact pages reserve space beneath mobile navigation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final framework = AstryxFramework.standard(
      restBaseUri: Uri.parse('https://api.example.com/'),
      graphqlEndpoint: Uri.parse('https://api.example.com/graphql'),
    );
    addTearDown(framework.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AstryxTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: AstryxShowcasePage(registry: framework.registry),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.padding == const EdgeInsets.fromLTRB(16, 28, 16, 112),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
