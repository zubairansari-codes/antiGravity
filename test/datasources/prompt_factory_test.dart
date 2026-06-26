import 'package:flutter_test/flutter_test.dart';
import 'package:antigravity/features/home/data/datasources/prompt_factory.dart';
import 'package:antigravity/features/home/domain/entities/artefact_type.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:antigravity/features/home/domain/entities/conversation_mode.dart';

void main() {
  group('PromptFactory conversation prompts', () {
    for (final category in BrainstormCategory.values) {
      test('returns non-empty conversation prompt for ${category.id}', () {
        final prompt = PromptFactory.getSystemPrompt(
          category: category,
          isFinal: false,
        );
        expect(prompt, isNotEmpty);
        expect(prompt, contains('improvisation'));
        expect(prompt, contains('YES-AND'));
        expect(prompt, contains('<user_input>{{user_message}}</user_input>'));
      });
    }

    test('includes mode instruction for deepDive', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.general,
        isFinal: false,
        mode: ConversationMode.deepDive,
      );
      expect(prompt, contains('Deep dive'));
      expect(prompt.toLowerCase(), contains('drill'));
    });

    test('includes mode instruction for flip', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.general,
        isFinal: false,
        mode: ConversationMode.flip,
      );
      expect(prompt, contains('Flip it'));
      expect(prompt.toLowerCase(), contains('invert'));
    });
  });

  group('PromptFactory final prompts', () {
    for (final category in BrainstormCategory.values) {
      test('returns non-empty final prompt for ${category.id}', () {
        final prompt = PromptFactory.getSystemPrompt(
          category: category,
          isFinal: true,
        );
        expect(prompt, isNotEmpty);
        expect(prompt.toLowerCase(), contains('artefact'));
        expect(prompt, contains('artefact_type'));
        expect(prompt, contains('title'));
        expect(prompt, contains('content'));
        expect(prompt, contains('follow_up_questions'));
        expect(prompt, contains('Respond ONLY with a valid JSON object'));
        expect(prompt, contains('<user_input>{{user_message}}</user_input>'));
      });
    }

    test('coding prompt contains technical guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.coding,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('system'));
      expect(prompt.toLowerCase(), contains('edge'));
      expect(prompt.toLowerCase(), contains('tech'));
    });

    test('marketing prompt contains growth guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.marketing,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('viral'));
      expect(prompt.toLowerCase(), contains('position'));
      expect(prompt.toLowerCase(), contains('distribution'));
    });

    test('business prompt contains startup guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.business,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('unit economics'));
      expect(prompt.toLowerCase(), contains('unfair advantage'));
      expect(prompt.toLowerCase(), contains('business model'));
    });

    test('writing prompt contains narrative guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.writing,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('narrative'));
      expect(prompt.toLowerCase(), contains('headline'));
      expect(prompt.toLowerCase(), contains('audience'));
    });

    test('design prompt contains UX guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.design,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('user'));
      expect(prompt.toLowerCase(), contains('friction'));
      expect(prompt.toLowerCase(), contains('accessibility'));
    });

    test('personal prompt contains habit guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.personal,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('habit'));
      expect(prompt.toLowerCase(), contains('trigger'));
      expect(prompt.toLowerCase(), contains('fail-state'));
    });

    test('general prompt contains inversion guidance', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.general,
        isFinal: true,
      );
      expect(prompt.toLowerCase(), contains('inversion'));
      expect(prompt.toLowerCase(), contains('assumption'));
      expect(prompt.toLowerCase(), contains('action'));
    });

    test('requested artefact is reflected in final prompt', () {
      final prompt = PromptFactory.getSystemPrompt(
        category: BrainstormCategory.coding,
        isFinal: true,
        requestedArtefact: ArtefactType.actionPlan,
      );
      expect(prompt, contains('Action plan'));
      expect(prompt.toLowerCase(), contains('requested'));
    });
  });
}
