import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AntiGravityApp()),
    );

    // Verify the app title is present.
    expect(find.text('AntiGravity'), findsOneWidget);
  });
}
