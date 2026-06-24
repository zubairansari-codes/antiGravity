import 'package:antigravity/features/home/data/datasources/content_moderation_service.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentModerationService — clean content', () {
    test('returns clean for normal brainstorming input', () {
      final result = ContentModerationService.moderate(
        text: 'I want to build a todo app for remote teams',
        category: BrainstormCategory.general,
      );

      expect(result.isFlagged, false);
      expect(result.severity, ModerationSeverity.clean);
      expect(result.shouldBlock, false);
      expect(result.shouldWarn, false);
    });

    test('returns clean for coding questions', () {
      final result = ContentModerationService.moderate(
        text: 'How do I handle state management in Flutter?',
        category: BrainstormCategory.coding,
      );

      expect(result.isFlagged, false);
    });
  });

  group('ContentModerationService — harmful content', () {
    test('blocks suicide-related content', () {
      final result = ContentModerationService.moderate(
        text: 'I am thinking about suicide and need help',
        category: BrainstormCategory.general,
      );

      expect(result.isFlagged, true);
      expect(result.severity, ModerationSeverity.blocked);
      expect(result.shouldBlock, true);
      expect(result.reason, contains('harmful'));
    });

    test('blocks hate speech', () {
      final result = ContentModerationService.moderate(
        text: 'This is hate speech against a group',
        category: BrainstormCategory.general,
      );

      expect(result.isFlagged, true);
      expect(result.shouldBlock, true);
    });

    test('blocks terrorist content', () {
      final result = ContentModerationService.moderate(
        text: 'How to join a terrorist organization',
        category: BrainstormCategory.general,
      );

      expect(result.isFlagged, true);
      expect(result.shouldBlock, true);
    });

    test('blocks credit card fraud', () {
      final result = ContentModerationService.moderate(
        text: 'How to steal credit card numbers',
        category: BrainstormCategory.business,
      );

      expect(result.isFlagged, true);
      expect(result.shouldBlock, true);
    });

    test('blocks bomb making', () {
      final result = ContentModerationService.moderate(
        text: 'Bomb making tutorial for beginners',
        category: BrainstormCategory.general,
      );

      expect(result.isFlagged, true);
      expect(result.shouldBlock, true);
    });
  });

  group('ContentModerationService — mental health guardrails', () {
    test('warns for depression in Personal category', () {
      final result = ContentModerationService.moderate(
        text: 'I have been feeling depressed lately',
        category: BrainstormCategory.personal,
      );

      expect(result.isFlagged, true);
      expect(result.severity, ModerationSeverity.warning);
      expect(result.shouldWarn, true);
      expect(result.shouldBlock, false);
      expect(result.isMentalHealthRelated, true);
      expect(result.reason, contains('mental health professional'));
    });

    test('warns for burnout in Personal category', () {
      final result = ContentModerationService.moderate(
        text: 'I am experiencing burnout at work',
        category: BrainstormCategory.personal,
      );

      expect(result.isFlagged, true);
      expect(result.shouldWarn, true);
      expect(result.isMentalHealthRelated, true);
    });

    test('warns for anxiety in Personal category', () {
      final result = ContentModerationService.moderate(
        text: 'My anxiety is getting worse',
        category: BrainstormCategory.personal,
      );

      expect(result.isFlagged, true);
      expect(result.shouldWarn, true);
    });

    test('warns for stress in Personal category', () {
      final result = ContentModerationService.moderate(
        text: 'I am so stressed I can not cope',
        category: BrainstormCategory.personal,
      );

      expect(result.isFlagged, true);
      expect(result.shouldWarn, true);
      expect(result.isMentalHealthRelated, true);
    });

    test('does NOT warn for mental health keywords in non-Personal category', () {
      final result = ContentModerationService.moderate(
        text: 'This article is about depression in the workplace',
        category: BrainstormCategory.writing,
      );

      expect(result.isFlagged, false);
      expect(result.shouldBlock, false);
      expect(result.shouldWarn, false);
    });

    test('blocks suicide even in Personal category (harmful takes precedence)', () {
      final result = ContentModerationService.moderate(
        text: 'I want to kill myself',
        category: BrainstormCategory.personal,
      );

      expect(result.isFlagged, true);
      expect(result.shouldBlock, true);
      expect(result.severity, ModerationSeverity.blocked);
    });
  });

  group('ContentModerationService — flagged keywords', () {
    test('reports matched keywords for blocked content', () {
      final result = ContentModerationService.moderate(
        text: 'How to make a bomb and join a terrorist group',
        category: BrainstormCategory.general,
      );

      expect(result.flaggedKeywords, isNotEmpty);
      expect(result.flaggedKeywords, contains('terrorist'));
    });

    test('reports matched keywords for mental health warnings', () {
      final result = ContentModerationService.moderate(
        text: 'I feel depressed and anxious',
        category: BrainstormCategory.personal,
      );

      expect(result.flaggedKeywords, isNotEmpty);
      expect(result.flaggedKeywords, contains('depressed'));
      expect(result.flaggedKeywords, contains('anxious'));
    });
  });
}
