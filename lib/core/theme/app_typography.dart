// Typography configuration using system fonts.
//
// Uses system fonts for reliability (no runtime font fetching).
// Falls back to the Material default font stack.
import 'package:flutter/material.dart';

abstract final class AppTypography {
  /// Base text theme — system fonts with refined weights.
  static TextTheme get textTheme => const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.25,
        ),

        // Headlines
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),

        // Titles
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),

        // Body
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );

  /// Returns a text theme scaled by the current [MediaQuery.textScaler].
  ///
  /// Flutter [Text] widgets automatically scale by default; this helper is
  /// useful when you need to pass an explicitly scaled [TextTheme] to a
  /// widget that does not read [MediaQuery] (e.g. custom painters).
  static TextTheme responsiveTextTheme(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    return textTheme.apply(fontSizeFactor: scale);
  }

  /// Monospace style for prompts.
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );
}
