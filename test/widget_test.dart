import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serenify/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SerenifyApp()),
    );

    // Verify app title is shown
    expect(find.text('Serenify'), findsOneWidget);
  });
}
