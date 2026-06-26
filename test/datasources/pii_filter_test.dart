import 'package:antigravity/features/home/data/datasources/pii_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PiiFilter.redact', () {
    test('detects and redacts email addresses', () {
      const input = 'Contact me at john.doe@example.com please';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.redactedText, contains('[email#'));
      expect(result.redactedText, isNot(contains('john.doe@example.com')));
      expect(result.mapping.values, contains('john.doe@example.com'));
    });

    test('detects and redacts multiple emails', () {
      const input = 'Email alice@test.com or bob@work.org';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.mapping.length, 2);
      expect(result.mapping.values, contains('alice@test.com'));
      expect(result.mapping.values, contains('bob@work.org'));
    });

    test('detects and redacts US phone numbers', () {
      const input = 'Call me at 555-123-4567';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.redactedText, contains('[phone_number#'));
      expect(result.redactedText, isNot(contains('555-123-4567')));
    });

    test('detects and redacts phone with parentheses', () {
      const input = 'My number is (555) 123-4567';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.mapping.values, contains('(555) 123-4567'));
    });

    test('detects and redacts SSN', () {
      const input = 'SSN: 123-45-6789';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.redactedText, contains('[ssn#'));
      expect(result.redactedText, isNot(contains('123-45-6789')));
    });

    test('detects and redacts credit card number', () {
      const input = 'Card: 4111-1111-1111-1111';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.redactedText, contains('[credit_card#'));
      expect(result.redactedText, isNot(contains('4111-1111-1111-1111')));
    });

    test('detects and redacts API keys', () {
      const input = 'Key: sk-antigravity12345678901234567890';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.redactedText, contains('[api_key#'));
      expect(result.redactedText, isNot(contains('sk-antigravity')));
    });

    test('detects gsk- API keys', () {
      const input = 'Groq key: gsk-abcdef1234567890abcdef';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.mapping.values, contains('gsk-abcdef1234567890abcdef'));
    });

    test('returns no redaction for clean text', () {
      const input = 'I want to build a todo app';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, false);
      expect(result.redactedText, input);
      expect(result.mapping, isEmpty);
    });

    test('redacts mixed PII in one pass', () {
      const input =
          'Email me at user@domain.com or call 555-123-4567. SSN is 123-45-6789';
      final result = PiiFilter.redact(input);

      expect(result.wasRedacted, true);
      expect(result.mapping.length, 3);
      expect(result.redactedText, isNot(contains('@')));
      expect(result.redactedText, isNot(contains('555-123-4567')));
      expect(result.redactedText, isNot(contains('123-45-6789')));
    });
  });

  group('PiiFilter.restore', () {
    test('restores redacted PII from mapping', () {
      const input = 'Contact me at john.doe@example.com';
      final redaction = PiiFilter.redact(input);

      final restored = PiiFilter.restore(redaction.redactedText, redaction.mapping);
      expect(restored, input);
    });

    test('restore with multiple replacements', () {
      const input = 'A: alice@test.com B: bob@work.org';
      final redaction = PiiFilter.redact(input);

      final restored = PiiFilter.restore(redaction.redactedText, redaction.mapping);
      expect(restored, input);
    });

    test('restore with no changes when mapping is empty', () {
      const text = 'No PII here';
      final restored = PiiFilter.restore(text, {});
      expect(restored, text);
    });
  });
}
