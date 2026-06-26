import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity/features/home/data/datasources/prompt_factory.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';

void main() {
  group('PromptFactory conversation prompts', () {
    for (final category in BrainstormCategory.values) {
      test('returns non-empty conversation prompt for ${category.id}', () {
        final prompt = PromptFactory.getSystemPrompt(
          category: category,
          isFinal: false,
        );
        expect(prompt, isNotEmpty);
        expect(prompt, contains('CONVERSATION MODE'));
        expect(prompt, contains('<user_input>{{user_message}}</user_input>'));
      });
    }
  });

  group('PromptFactory final prompts', () {
    for (final category in BrainstormCategory.values) {
      test('returns non-empty final prompt for ${category.id}', () {
        final prompt = PromptFactory.getSystemPrompt(
          category: category,
          isFinal: true,
        );
        expect(prompt, isNotEmpty);
        expect(prompt, contains('GOAL:'));
        expect(prompt, contains('SYNTHESIZE THE CONVERSATION HISTORY'));
        expect(prompt, contains('QUALITY CRITERIA'));
        expect(prompt, contains('COMMON PITFALLS TO AVOID'));
        expect(prompt, contains('READY PROMPT INSTRUCTIONS'));
        expect(prompt, contains('SAFETY RULES'));
        expect(prompt, contains('Respond ONLY with a valid JSON object'));
        expect(prompt, contains('<user_input>{{user_message}}</user_input>'));
      });
    }

    test('coding prompt contains technical guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.coding,
        isFinal: true,
      );
      expect(prompt, contains('system architecture'));
      expect(prompt.toLowerCase(), contains('edge cases'));
      expect(prompt, contains('tech stack'));
    });

    test('marketing prompt contains growth guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.marketing,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('viral'));
      expect(prompt, contains('positioning'));
      expect(prompt, contains('distribution'));
    });

    test('business prompt contains startup guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.business,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('unit economics'));
      expect(prompt, contains('unfair advantage'));
      expect(prompt, contains('business model'));
    });

    test('writing prompt contains narrative guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.writing,
        isFinal: true,
      );
      expect(prompt, contains('narrative arc'));
      expect(prompt, contains('headline'));
      expect(prompt.toLowerCase(), contains('audience'));
    });

    test('design prompt contains UX guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.design,
        isFinal: true,
      );
      expect(prompt, contains('user'));
      expect(prompt, contains('friction'));
      expect(prompt.toLowerCase(), contains('accessibility'));
    });

    test('personal prompt contains habit guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.personal,
        isFinal: true,
      );
      expect(prompt, contains('habit loop'));
      expect(prompt, contains('trigger'));
      expect(prompt.toLowerCase(), contains('fail-state'));
    });

    test('general prompt contains inversion guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.general,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('invert'));
      expect(prompt, contains('assumption'));
      expect(prompt, contains('action plan'));
    });

    test('each final prompt contains a ready prompt template', () {
      for (final category in BrainstormCategory.values) {
        final prompt = PromptFactory.getSystemPrompt(
          category: category,
          isFinal: true,
        );
        expect(
          prompt,
          contains('['),
          reason: '${category.id} prompt should contain ready prompt template placeholders',
        );
        expect(
          prompt,
          contains(']'),
          reason: '${category.id} prompt should contain ready prompt template placeholders',
        );
      }
    });
  });
}
