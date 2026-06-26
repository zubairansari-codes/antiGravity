/// Onboarding preferences — simple Hive-backed boolean for first-launch check.
library;


import 'package:hive/hive.dart';

class OnboardingPreferences {
  static const String _boxName = 'onboarding';
  static const String _key = 'hasCompletedOnboarding';

  static Future<Box<bool>> _openBox() async {
    return await Hive.openBox<bool>(_boxName);
  }

  static Future<bool> hasCompletedOnboarding() async {
    final box = await _openBox();
    return box.get(_key, defaultValue: false) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final box = await _openBox();
    await box.put(_key, true);
  }

  static Future<void> reset() async {
    final box = await _openBox();
    await box.put(_key, false);
  }
}
