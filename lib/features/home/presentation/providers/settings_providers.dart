/// App-wide preference providers — theme, TTS speed, haptics, onboarding.
library;


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../onboarding/onboarding_preferences.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_category.dart';
import 'daily_usage_tracker.dart';
import 'home_viewmodel.dart';

// ── Theme ─────────────────────────────────────────────────────────

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {

  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }
  static const String _boxName = 'settings_theme';
  static const String _key = 'themeMode';

  Future<void> _load() async {
    final box = await Hive.openBox<String>(_boxName);
    final value = box.get(_key);
    if (value != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = await Hive.openBox<String>(_boxName);
    await box.put(_key, mode.name);
  }
}

// ── TTS Speed ─────────────────────────────────────────────────────

final ttsSpeedProvider = StateNotifierProvider<TtsSpeedNotifier, double>(
  (ref) => TtsSpeedNotifier(),
);

class TtsSpeedNotifier extends StateNotifier<double> {

  TtsSpeedNotifier() : super(1.0) {
    _load();
  }
  static const String _boxName = 'settings_tts';
  static const String _key = 'ttsSpeed';

  Future<void> _load() async {
    final box = await Hive.openBox<double>(_boxName);
    final value = box.get(_key);
    if (value != null) {
      state = value;
    }
  }

  Future<void> setSpeed(double speed) async {
    state = speed;
    final box = await Hive.openBox<double>(_boxName);
    await box.put(_key, speed);
  }
}

// ── Haptics ───────────────────────────────────────────────────────

final hapticsEnabledProvider = StateNotifierProvider<HapticsNotifier, bool>(
  (ref) => HapticsNotifier(),
);

class HapticsNotifier extends StateNotifier<bool> {

  HapticsNotifier() : super(true) {
    _load();
  }
  static const String _boxName = 'settings_haptics';
  static const String _key = 'hapticsEnabled';

  Future<void> _load() async {
    final box = await Hive.openBox<bool>(_boxName);
    final value = box.get(_key);
    if (value != null) {
      state = value;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final box = await Hive.openBox<bool>(_boxName);
    await box.put(_key, enabled);
  }
}

// ── Onboarding ────────────────────────────────────────────────────

final onboardingCompleteProvider = StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) => OnboardingNotifier(),
);

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await OnboardingPreferences.hasCompletedOnboarding();
  }

  Future<void> completeOnboarding() async {
    await OnboardingPreferences.setOnboardingComplete();
    state = true;
  }

  Future<void> reset() async {
    await OnboardingPreferences.reset();
    state = false;
  }
}

// ── Daily Usage ───────────────────────────────────────────────────

final dailyUsageTrackerProvider = Provider<DailyUsageTracker>((ref) {
  return DailyUsageTracker();
});

final dailyCountProvider = FutureProvider<int>((ref) async {
  final tracker = ref.watch(dailyUsageTrackerProvider);
  return tracker.getDailyCount();
});

// ── Filtered brainstorms (for home screen search/filter) ──────────

final homeSearchQueryProvider = StateProvider<String>((ref) => '');
final homeCategoryFilterProvider = StateProvider<BrainstormCategory?>((ref) => null);

/// Filtered brainstorms provider for search + category filtering on the home screen.
final filteredBrainstormsProvider = Provider<AsyncValue<List<Brainstorm>>>((ref) {
  final asyncBrainstorms = ref.watch(homeViewModelProvider);
  final query = ref.watch(homeSearchQueryProvider).toLowerCase().trim();
  final category = ref.watch(homeCategoryFilterProvider);

  return asyncBrainstorms.when(
    data: (brainstorms) {
      var filtered = brainstorms;
      if (category != null) {
        filtered = filtered.where((b) => b.category == category).toList();
      }
      if (query.isNotEmpty) {
        filtered = filtered.where((b) {
          final titleMatch = b.title.toLowerCase().contains(query);
          final contentMatch = b.messages.any(
            (m) => m.content.toLowerCase().contains(query),
          );
          return titleMatch || contentMatch;
        }).toList();
      }
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
