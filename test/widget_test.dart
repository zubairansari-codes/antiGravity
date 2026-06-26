import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:antigravity/app.dart';
import 'package:antigravity/features/onboarding/onboarding_preferences.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('antigravity_widget_test');
    Hive.init(tempDir.path);
    // Mark onboarding complete so the app routes to the home screen.
    await OnboardingPreferences.setOnboardingComplete();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AntiGravityApp()),
    );

    // Wait for onboarding preference to load and the home screen to appear.
    await tester.pumpAndSettle();

    // Verify the app title is present in the home app bar.
    expect(find.text('AntiGravity'), findsOneWidget);
  });
}
