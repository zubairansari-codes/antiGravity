/// AntiGravity app root — MaterialApp.router with GoRouter, theme, and onboarding gate.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/home/domain/entities/brainstorm_category.dart';
import 'features/home/domain/entities/brainstorm_result.dart';
import 'features/home/presentation/providers/settings_providers.dart';
import 'features/home/presentation/screens/brainstorm_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/result_screen.dart';
import 'features/home/presentation/screens/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

class AntiGravityApp extends ConsumerWidget {
  const AntiGravityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    // Show onboarding on first launch.
    if (!onboardingComplete) {
      return MaterialApp(
        title: 'AntiGravity',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: _darkTheme,
        themeMode: themeMode,
        home: const OnboardingScreen(),
      );
    }

    return MaterialApp.router(
      title: 'AntiGravity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

/// Dark theme — built here since core/theme/ is owned by Worker A.
/// Uses Material 3 dark color scheme with the existing brand colours.
final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryDark,
    secondary: AppColors.accent,
    surface: Color(0xFF1E1E2C),
    onSurface: Color(0xFFECECF5),
    onSurfaceVariant: Color(0xFF9A9AAF),
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: const Color(0xFF12121A),
  // Let Material 3 generate the dark text theme automatically.

  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: true,
    backgroundColor: Color(0xFF12121A),
    foregroundColor: Color(0xFFECECF5),
    titleTextStyle: TextStyle(
      color: Color(0xFFECECF5),
    ),
  ),

  cardTheme: CardTheme(
    elevation: 0,
    color: const Color(0xFF1E1E2C),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: const Color(0xFF2E2E3C).withOpacity(0.5),
      ),
    ),
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2E2E3C).withOpacity(0.4),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),

  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    backgroundColor: const Color(0xFFECECF5),
    contentTextStyle: const TextStyle(
      color: Color(0xFF12121A),
    ),
  ),

  dividerTheme: DividerThemeData(
    color: const Color(0xFF2E2E3C).withOpacity(0.5),
    thickness: 1,
  ),

  iconTheme: const IconThemeData(
    color: Color(0xFF9A9AAF),
    size: 24,
  ),

  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
);

/// App router — 4 routes: home, brainstorm, result, settings.
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/brainstorm',
      builder: (_, state) {
        final category = state.extra as BrainstormCategory? ?? BrainstormCategory.general;
        return BrainstormScreen(category: category);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (_, state) {
        final result = state.extra as BrainstormResult;
        return ResultScreen(result: result);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);
