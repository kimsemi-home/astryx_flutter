import 'package:astryx_flutter_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the framework showcase', (tester) async {
    await tester.pumpWidget(const AstryxExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Astryx Flutter'), findsOneWidget);
    expect(find.text('Atomic UI.\nAny backend shape.'), findsOneWidget);
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('GRAPHQL'), findsOneWidget);
    expect(find.text('SSE'), findsOneWidget);
    expect(find.text('HATEOAS'), findsOneWidget);
  });
}
