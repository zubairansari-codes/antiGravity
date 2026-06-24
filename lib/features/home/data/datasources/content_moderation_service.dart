/// Lightweight keyword-based content moderation for user input and AI output.
///
/// Checks for harmful/toxic content and flags mental health concerns
/// so the UI can show appropriate guardrails.
library;

import '../../domain/entities/brainstorm_category.dart';

class ContentModerationService {
  /// General harmful / toxic keywords.
  static final Set<String> _harmfulKeywords = {
    'kill yourself',
    'kill myself',
    'suicide',
    'self-harm',
    'hate speech',
    'terrorist',
    'bomb making',
    'child abuse',
    'illegal drugs',
    'hacking tutorial',
    'bypass security',
    'exploit vulnerability',
    'steal credit card',
    'credit card fraud',
  };

  /// Mental health related keywords (soft guardrails for Personal category).
  static final Set<String> _mentalHealthKeywords = {
    'depression',
    'depressed',
    'anxiety',
    'anxious',
    'burnout',
    'burned out',
    'overwhelmed',
    'hopeless',
    'suicidal',
    'self harm',
    'self-harm',
    'panic attack',
    ' ptsd ',
    'trauma',
    'grief',
    'lonely',
    'isolated',
    'can not cope',
    'can\'t cope',
  };

  /// Moderate both user input and AI output.
  static ModerationResult moderate({
    required String text,
    required BrainstormCategory category,
  }) {
    final lower = text.toLowerCase();

    // Check for harmful content
    final harmfulMatches = _harmfulKeywords
        .where((kw) => lower.contains(kw))
        .toList();

    if (harmfulMatches.isNotEmpty) {
      return ModerationResult(
        isFlagged: true,
        severity: ModerationSeverity.blocked,
        reason: 'Content contains harmful or unsafe topics.',
        flaggedKeywords: harmfulMatches,
        isMentalHealthRelated: false,
      );
    }

    // Check for mental health keywords (special handling for Personal category)
    final mentalHealthMatches = _mentalHealthKeywords
        .where((kw) => lower.contains(kw))
        .toList();

    final isMentalHealthRelated = mentalHealthMatches.isNotEmpty;

    if (isMentalHealthRelated && category == BrainstormCategory.personal) {
      return ModerationResult(
        isFlagged: true,
        severity: ModerationSeverity.warning,
        reason: 'It looks like you may be going through a difficult time. '
            'We\'re here to help with brainstorming, but if you need support, '
            'please reach out to a mental health professional or a crisis helpline.',
        flaggedKeywords: mentalHealthMatches,
        isMentalHealthRelated: true,
      );
    }

    return ModerationResult.clean();
  }
}

enum ModerationSeverity { clean, warning, blocked }

class ModerationResult {
  final bool isFlagged;
  final ModerationSeverity severity;
  final String reason;
  final List<String> flaggedKeywords;
  final bool isMentalHealthRelated;

  const ModerationResult({
    required this.isFlagged,
    required this.severity,
    required this.reason,
    required this.flaggedKeywords,
    required this.isMentalHealthRelated,
  });

  factory ModerationResult.clean() => const ModerationResult(
        isFlagged: false,
        severity: ModerationSeverity.clean,
        reason: '',
        flaggedKeywords: [],
        isMentalHealthRelated: false,
      );

  bool get shouldBlock => severity == ModerationSeverity.blocked;
  bool get shouldWarn => severity == ModerationSeverity.warning;
}
