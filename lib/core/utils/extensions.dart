// Convenience extensions for BuildContext, String, DateTime, and Duration.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ── BuildContext shortcuts ─────────────────────────────────────────
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  MediaQueryData get media => MediaQuery.of(this);
  double get screenWidth => media.size.width;
  double get screenHeight => media.size.height;

  /// Whether the current theme brightness is dark.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

// ── String helpers ─────────────────────────────────────────────────
extension StringX on String {
  /// Capitalise the first letter.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncate with ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  /// True if null or empty/whitespace-only.
  bool get isBlank => trim().isEmpty;

  /// True if non-null and not empty/whitespace-only.
  bool get isNotBlank => !isBlank;
}

// ── DateTime formatting ────────────────────────────────────────────
extension DateTimeX on DateTime {
  /// "Jun 22, 2026"
  String get formatted {
    return DateFormat('MMM d, y').format(this);
  }

  /// "2 hours ago", "Just now", etc.
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatted;
  }
}

// ── Duration formatting ────────────────────────────────────────────
extension DurationX on Duration {
  /// Formats as "2 minutes", "1 hour 30 minutes", or "45 seconds".
  String get formatted {
    if (inSeconds < 60) return '$inSeconds second${inSeconds == 1 ? '' : 's'}';
    if (inMinutes < 60) {
      return '$inMinutes minute${inMinutes == 1 ? '' : 's'}';
    }
    final hours = inHours;
    final minutes = inMinutes % 60;
    if (minutes == 0) return '$hours hour${hours == 1 ? '' : 's'}';
    return '$hours hour${hours == 1 ? '' : 's'} $minutes minute${minutes == 1 ? '' : 's'}';
  }
}
