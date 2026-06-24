/// AntiGravity app root — MaterialApp.router with GoRouter.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/domain/entities/brainstorm_category.dart';
import 'features/home/domain/entities/brainstorm_result.dart';
import 'features/home/presentation/screens/brainstorm_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/home/presentation/screens/result_screen.dart';

class AntiGravityApp extends StatelessWidget {
  const AntiGravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AntiGravity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}


/// App router — 3 routes: home, brainstorm, result.
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
  ],
);
