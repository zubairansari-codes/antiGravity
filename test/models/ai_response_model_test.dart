import 'dart:convert';

import 'package:antigravity/features/home/data/models/ai_response_model.dart';
import 'package:antigravity/features/home/domain/entities/artefact_type.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_result.dart';
import 'package:antigravity/features/home/domain/entities/conversation_artefact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AIResponseModel.fromContent — conversation mode', () {
    test('wraps text when isFinal is false', () {
      const text = 'Hello there!';
      final model = AIResponseModel.fromContent(text, isFinal: false);

      expect(model.text, text);
      expect(model.isFinal, false);
      expect(model.structuredResult, isNull);
      expect(model.artefacts, isEmpty);
    });
  });

  group('AIResponseModel.fromContent — artefact JSON (final mode)', () {
    test('parses single artefact JSON into artefacts and legacy result', () {
      final json = {
        'artefact_type': 'actionPlan',
        'title': 'Launch plan for the habit tracker',
        'content': '1. Define the core loop\n2. Build the streak UI\n3. Add reminders',
        'follow_up_questions': ['What is the trigger?', 'How will users recover from a miss?'],
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.personal,
      );

      expect(model.isFinal, true);
      expect(model.artefacts.length, 1);
      expect(model.artefacts.first.artefactType, ArtefactType.actionPlan);
      expect(model.artefacts.first.title, 'Launch plan for the habit tracker');
      expect(model.structuredResult, isNotNull);
      expect(model.structuredResult!.refinedIdea, 'Launch plan for the habit tracker');
      expect(model.structuredResult!.actionPlan.length, 3);
    });

    test('parses artefacts list', () {
      final json = {
        'artefacts': [
          {
            'artefact_type': 'ideaOnePager',
            'title': 'Idea A',
            'content': 'Content A',
            'follow_up_questions': ['Q1'],
          },
          {
            'artefact_type': 'pitchThread',
            'title': 'Thread hook',
            'content': 'Hook body',
            'follow_up_questions': ['Q2'],
          },
        ],
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.general,
      );

      expect(model.artefacts.length, 2);
      expect(model.artefacts.first.artefactType, ArtefactType.ideaOnePager);
      expect(model.artefacts.last.artefactType, ArtefactType.pitchThread);
    });

    test('falls back to rawNotes for unknown artefact_type', () {
      final json = {
        'artefact_type': 'futureType',
        'title': 'Future',
        'content': 'Body',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.general,
      );

      expect(model.artefacts.first.artefactType, ArtefactType.rawNotes);
    });
  });

  group('AIResponseModel.fromContent — legacy JSON parsing (final mode)', () {
    test('parses Coding JSON correctly', () {
      final json = {
        'system_architecture': 'Use microservices with Redis caching',
        'tech_stack': ['Flutter', 'Dart', 'Firebase'],
        'implementation_plan': [
          {'title': 'Set up CI/CD', 'description': 'Automate builds', 'priority': 'high'},
          {'title': 'Auth flow', 'description': 'OAuth integration', 'priority': 'medium'},
        ],
        'edge_cases': ['Offline mode', 'Slow network'],
        'riskiest_assumption': 'Users will tolerate 3s latency',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.coding,
      );

      expect(model.isFinal, true);
      expect(model.structuredResult, isNotNull);
      expect(model.structuredResult!.refinedIdea, 'Use microservices with Redis caching');
      expect(model.structuredResult!.actionPlan.length, 2);
      expect(model.structuredResult!.actionPlan.first.title, 'Set up CI/CD');
      expect(model.structuredResult!.riskiestAssumption, 'Users will tolerate 3s latency');
      expect(model.artefacts, isEmpty);
    });

    test('parses Marketing JSON correctly', () {
      final json = {
        'positioning': 'A productivity tool for remote teams',
        'viral_hooks': ['Free tier that goes viral', 'Referral rewards'],
        'distribution_plan': [
          {'title': 'Launch on Product Hunt', 'description': 'Target early adopters', 'priority': 'high'},
        ],
        'alternative_channels': ['LinkedIn ads', 'Twitter threads'],
        'riskiest_assumption': 'Remote teams care about this problem',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.marketing,
      );

      expect(model.structuredResult!.refinedIdea, 'A productivity tool for remote teams');
      expect(model.structuredResult!.alternatives, contains('LinkedIn ads'));
    });

    test('parses Business JSON correctly', () {
      final json = {
        'business_model': 'SaaS for SMBs, \$29/mo seat',
        'unfair_advantage': 'Proprietary data pipeline',
        'action_plan': [
          {'title': 'Validate pricing', 'description': 'Interview 10 prospects', 'priority': 'high'},
        ],
        'pivot_angles': ['Enterprise focus', 'API-first'],
        'riskiest_assumption': 'SMBs will pay \$29/mo',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.business,
      );

      expect(model.structuredResult!.readyPrompt, 'Unfair advantage: Proprietary data pipeline');
      expect(model.structuredResult!.alternatives, contains('Enterprise focus'));
    });

    test('parses Writing JSON correctly', () {
      final json = {
        'narrative_arc': 'From burnout to breakthrough',
        'headline_ideas': ['The Quiet Quitting Myth', 'Burnout Is a Feature, Not a Bug'],
        'drafting_plan': [
          {'title': 'Write hook', 'description': 'Open with a story', 'priority': 'high'},
        ],
        'alternative_angles': ['Personal essay', 'Data-driven piece'],
        'riskiest_assumption': 'Readers have experienced burnout',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.writing,
      );

      expect(model.structuredResult!.refinedIdea, 'From burnout to breakthrough');
      expect(model.structuredResult!.alternatives, contains('Personal essay'));
    });

    test('parses Design JSON correctly', () {
      final json = {
        'core_experience': 'One-tap meditation with haptic feedback',
        'key_screens': ['Home', 'Session', 'Stats'],
        'design_plan': [
          {'title': 'Wireframe home', 'description': 'Single CTA', 'priority': 'high'},
        ],
        'alternative_patterns': ['Bottom sheet', 'Full-screen modal'],
        'riskiest_assumption': 'Users want haptic feedback',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.design,
      );

      expect(model.structuredResult!.readyPrompt, 'Key screens: Home, Session, Stats');
    });

    test('parses Personal JSON correctly', () {
      final json = {
        'refined_goal': 'Run 5K in under 25 minutes by December',
        'habit_loop': {
          'trigger': 'Morning alarm',
          'action': '15-min jog',
          'reward': 'Coffee + podcast',
        },
        'action_plan': [
          {'title': 'Buy shoes', 'description': 'Get fitted at a running store', 'priority': 'high'},
        ],
        'fail_state_protocols': ['If raining, run on treadmill'],
        'riskiest_assumption': 'Morning energy stays high',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.personal,
      );

      expect(model.structuredResult!.refinedIdea, 'Run 5K in under 25 minutes by December');
      expect(model.structuredResult!.readyPrompt, contains('Morning alarm'));
      expect(model.structuredResult!.alternatives, contains('If raining, run on treadmill'));
    });

    test('parses General JSON correctly', () {
      final json = {
        'refined_idea': 'A meal-planning app for busy parents',
        'ready_prompt': 'Write a meal plan for a working parent with 2 kids...',
        'action_plan': [
          {'title': 'Survey parents', 'description': 'Ask 5 friends', 'priority': 'high'},
        ],
        'alternative_angles': ['Grocery delivery integration', 'Dietitian marketplace'],
        'riskiest_assumption': 'Parents want to plan meals',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.general,
      );

      expect(model.structuredResult!.refinedIdea, 'A meal-planning app for busy parents');
      expect(model.structuredResult!.readyPrompt, contains('meal plan'));
      expect(model.structuredResult!.actionPlan.length, 1);
    });
  });

  group('AIResponseModel.fromContent — JSON wrapped in markdown code block', () {
    test('extracts JSON from ```json fence', () {
      final json = {
        'artefact_type': 'ideaOnePager',
        'title': 'Test idea',
        'content': 'Prompt text',
        'follow_up_questions': ['Next?'],
      };

      final content = '```json\n${jsonEncode(json)}\n```';
      final model = AIResponseModel.fromContent(
        content,
        isFinal: true,
        category: BrainstormCategory.general,
      );

      expect(model.artefacts, isNotNull);
      expect(model.artefacts.first.title, 'Test idea');
    });
  });

  group('AIResponseModel.parseResult — fallback chain', () {
    test('throws ParseException when JSON is missing required fields', () {
      final badJson = {'refined_idea': 'Missing action_plan'};

      expect(
        () => AIResponseModel.parseResult(
          jsonEncode(badJson),
          category: BrainstormCategory.general,
        ),
        throwsA(isA<ParseException>()),
      );
    });

    test('falls back to markdown when JSON is not present', () {
      const markdown = '''
## THE REFINED IDEA
A meal-planning app for busy parents.

## YOUR READY-TO-USE PROMPT
Write a meal plan...

## ACTION PLAN
1. Survey parents — Ask 5 friends
2. Build MVP — One week sprint
3. Launch — Post on social media

## ALTERNATIVE ANGLES
- Grocery delivery integration
- Dietitian marketplace

## RISKIEST ASSUMPTION
Parents want to plan meals.
''';

      final result = AIResponseModel.parseResult(markdown, category: BrainstormCategory.general);

      expect(result, isNotNull);
      expect(result!.legacyResult.refinedIdea, 'A meal-planning app for busy parents.');
      expect(result.legacyResult.actionPlan.length, 3);
      expect(result.legacyResult.actionPlan.first.title, 'Survey parents');
      expect(result.legacyResult.alternatives.length, 2);
    });

    test('returns null when both JSON and markdown fail', () {
      final result = AIResponseModel.parseResult(
        'This is just plain text with no structure.',
        category: BrainstormCategory.general,
      );
      expect(result, isNull);
    });
  });

  group('Schema validation — descriptive errors', () {
    test('Coding missing system_architecture throws ParseException', () {
      final json = {
        'implementation_plan': [],
        'riskiest_assumption': 'test',
      };

      expect(
        () => AIResponseModel.fromContent(
          jsonEncode(json),
          isFinal: true,
          category: BrainstormCategory.coding,
        ),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('system_architecture'),
          ),
        ),
      );
    });

    test('Business missing action_plan throws ParseException', () {
      final json = {
        'business_model': 'test',
        'riskiest_assumption': 'test',
      };

      expect(
        () => AIResponseModel.fromContent(
          jsonEncode(json),
          isFinal: true,
          category: BrainstormCategory.business,
        ),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('action_plan'),
          ),
        ),
      );
    });

    test('Personal missing habit_loop fields defaults to empty strings', () {
      final json = {
        'refined_goal': 'Goal',
        'habit_loop': {},
        'action_plan': [],
        'fail_state_protocols': [],
        'riskiest_assumption': 'Assumption',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.personal,
      );

      expect(model.structuredResult!.readyPrompt, contains('Trigger:'));
    });
  });

  group('Edge cases', () {
    test('handles empty action plan gracefully', () {
      final json = {
        'refined_idea': 'Idea',
        'ready_prompt': 'Prompt',
        'action_plan': [],
        'alternative_angles': [],
        'riskiest_assumption': 'Assumption',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.general,
      );

      expect(model.structuredResult!.actionPlan, isEmpty);
    });

    test('handles camelCase JSON keys as fallback', () {
      final json = {
        'refinedIdea': 'Camel case idea',
        'readyPrompt': 'Prompt',
        'actionPlan': [
          {'title': 'Step', 'description': 'Desc', 'priority': 'medium'},
        ],
        'alternativeAngles': ['Alt'],
        'riskiestAssumption': 'Assumption',
      };

      final model = AIResponseModel.fromContent(
        jsonEncode(json),
        isFinal: true,
        category: BrainstormCategory.general,
      );

      expect(model.structuredResult!.refinedIdea, 'Camel case idea');
      expect(model.structuredResult!.actionPlan.length, 1);
    });

    test('handles malformed JSON with markdown fallback', () {
      const content = '''
## THE REFINED IDEA
A test idea.

## ACTION PLAN
1. Step one — Do this
2. Step two — Do that

## RISKIEST ASSUMPTION
Users will care.
''';

      final result = AIResponseModel.parseResult(
        content,
        category: BrainstormCategory.general,
      );

      expect(result, isNotNull);
      expect(result!.legacyResult.actionPlan.length, 2);
    });

    test('toEntity maps correctly', () {
      const model = AIResponseModel(
        text: 'Hello',
        isFinal: false,
        structuredResult: null,
      );

      final entity = model.toEntity();
      expect(entity.text, 'Hello');
      expect(entity.isFinal, false);
      expect(entity.structuredResult, isNull);
      expect(entity.artefacts, isEmpty);
    });

    test('toEntity with structured result maps correctly', () {
      const result = BrainstormResult(
        refinedIdea: 'Idea',
        readyPrompt: 'Prompt',
        actionPlan: [ActionStep(stepNumber: 1, title: 'T', description: 'D')],
        alternatives: ['Alt'],
        riskiestAssumption: 'Assumption',
      );

      const model = AIResponseModel(
        text: 'Raw text',
        isFinal: true,
        structuredResult: result,
        artefacts: [
          ConversationArtefact(
            artefactType: ArtefactType.ideaOnePager,
            title: 'Idea',
            content: 'Content',
          ),
        ],
      );

      final entity = model.toEntity();
      expect(entity.structuredResult!.refinedIdea, 'Idea');
      expect(entity.structuredResult!.actionPlan.first.title, 'T');
      expect(entity.artefacts.first.artefactType, ArtefactType.ideaOnePager);
    });
  });
}
