/// Lightweight PII detection and redaction for user input.
///
/// Detects common PII patterns before sending to the LLM API.
/// Redacts detected PII and optionally keeps a mapping for restoration.
library;

import 'package:flutter/foundation.dart';

class PiiFilter {
  /// Patterns for common PII types.
  static final List<RegExp> _patterns = [
    // API keys (common patterns: sk-, gsk-, AIza, etc.) — match FIRST before phone/cc
    RegExp(
      r'\b(?:sk-|gsk-|AIza|ghp_|gho_|ghu_|ghs_|ghr_)[a-zA-Z0-9_-]{20,}\b',
      caseSensitive: false,
    ),
    // Email addresses
    RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    ),
    // US phone numbers (various formats)
    RegExp(
      r'(?:\+1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}',
    ),
    // US Social Security Numbers
    RegExp(r'\b\d{3}[-.\s]?\d{2}[-.\s]?\d{4}\b'),
    // Credit card numbers (16 digits, with or without spaces/dashes)
    RegExp(
      r'(?:\d{4}[-.\s]?){3}\d{4}|\b\d{15,16}\b',
    ),
  ];

  /// Descriptive labels for each PII pattern (aligned with [_patterns]).
  static const List<String> _labels = [
    'api_key',
    'email',
    'phone_number',
    'ssn',
    'credit_card',
  ];

  /// Redact PII in [input] and return a [RedactionResult].
  static RedactionResult redact(String input) {
    var redacted = input;
    final Map<String, String> mapping = {};
    int placeholderCounter = 1;

    for (int i = 0; i < _patterns.length; i++) {
      final pattern = _patterns[i];
      final label = _labels[i];
      redacted = redacted.replaceAllMapped(pattern, (match) {
        final original = match.group(0)!;
        final placeholder = '[$label#$placeholderCounter]';
        placeholderCounter++;
        mapping[placeholder] = original;

        if (kDebugMode) {
          debugPrint('[PII] Redacted $label: ${original.substring(0, original.length > 4 ? 4 : original.length)}...');
        }
        return placeholder;
      });
    }

    return RedactionResult(
      redactedText: redacted,
      mapping: Map.unmodifiable(mapping),
      wasRedacted: mapping.isNotEmpty,
    );
  }

  /// Restore redacted PII placeholders back to original values.
  static String restore(String redactedText, Map<String, String> mapping) {
    var restored = redactedText;
    for (final entry in mapping.entries) {
      restored = restored.replaceAll(entry.key, entry.value);
    }
    return restored;
  }
}

/// Result of a PII redaction pass.
class RedactionResult {

  const RedactionResult({
    required this.redactedText,
    required this.mapping,
    required this.wasRedacted,
  });
  final String redactedText;
  final Map<String, String> mapping;
  final bool wasRedacted;
}
