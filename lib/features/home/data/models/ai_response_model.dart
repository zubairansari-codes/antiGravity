/// AI response DTO — parses OpenAI output into domain objects.
///
/// Supports two parsing modes:
/// 1. **JSON mode** (preferred for final output) — structured JSON with
///    schema validation per category.
/// 2. **Markdown fallback** — legacy regex-based parsing for backward compat.
///
/// When JSON parsing fails, a [ParseException] is thrown with a
/// descriptive message so the repository can trigger a corrective retry.
library;

import 'dart:convert';

import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/brainstorm_result.dart';
import '../../domain/entities/ai_response.dart';

// ───────────────────────────────────────────────────────────
//  AIResponseModel
// ───────────────────────────────────────────────────────────

class AIResponseModel {

  const AIResponseModel({
    required this.text,
    required this.isFinal,
    this.structuredResult,
  });

  /// Parse raw AI content into a model.
  ///
  /// For conversational mode, just wraps the text.
  /// For final output, tries JSON first, then markdown fallback.
  factory AIResponseModel.fromContent(
    String content, {
    required bool isFinal,
    BrainstormCategory? category,
  }) {
    if (!isFinal) {
      return AIResponseModel(text: content, isFinal: false);
    }

    final result = parseResult(content, category: category);
    if (result == null) {
      throw const ParseException(
        'Failed to parse final output. Text was neither valid JSON nor structured markdown.',
      );
    }

    return AIResponseModel(
      text: content,
      isFinal: true,
      structuredResult: result,
    );
  }
  final String text;
  final bool isFinal;
  final BrainstormResult? structuredResult;

  /// Convert to domain entity.
  AIResponse toEntity() => AIResponse(
        text: text,
        isFinal: isFinal,
        structuredResult: structuredResult,
      );

  // ── Parsing entry point ─────────────────────────────────

  /// Try JSON first, then markdown fallback.
  ///
  /// Throws [ParseException] if neither format can be parsed, so the caller
  /// can decide to retry with a corrective prompt or show raw text.
  static BrainstormResult? parseResult(
    String content, {
    BrainstormCategory? category,
  }) {
    // 1. Try JSON mode
    try {
      final json = _extractJson(content);
      if (json != null && category != null) {
        return _parseJsonResult(json, category);
      }
    } on ParseException {
      rethrow; // propagate validation errors so we can retry
    } catch (_) {
      // Not valid JSON — fall through to markdown
    }

    // 2. Markdown fallback (legacy)
    try {
      return _parseMarkdownResult(content);
    } catch (_) {
      // ignore markdown failures
    }

    // 3. Nothing worked — caller handles raw text display
    return null;
  }

  // ── JSON helpers ──────────────────────────────────────────

  static Map<String, dynamic>? _extractJson(String text) {
    // Try to find a JSON object in the text (the model may wrap it in markdown)
    final codeBlock = RegExp(
      r'```json\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    ).firstMatch(text);
    if (codeBlock != null) {
      text = codeBlock.group(1)!;
    }

    // Find the first { and last }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;

    final jsonStr = text.substring(start, end + 1);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  static BrainstormResult _parseJsonResult(
    Map<String, dynamic> json,
    BrainstormCategory category,
  ) {
    switch (category) {
      case BrainstormCategory.coding:
        return _CodingResult.fromJson(json).toBrainstormResult();
      case BrainstormCategory.marketing:
        return _MarketingResult.fromJson(json).toBrainstormResult();
      case BrainstormCategory.business:
        return _BusinessResult.fromJson(json).toBrainstormResult();
      case BrainstormCategory.writing:
        return _WritingResult.fromJson(json).toBrainstormResult();
      case BrainstormCategory.design:
        return _DesignResult.fromJson(json).toBrainstormResult();
      case BrainstormCategory.personal:
        return _PersonalResult.fromJson(json).toBrainstormResult();
      case BrainstormCategory.general:
        return _GeneralResult.fromJson(json).toBrainstormResult();
    }
  }

  // ── Markdown fallback (legacy) ────────────────────────────

  static BrainstormResult? _parseMarkdownResult(String content) {
    final result = BrainstormResult(
      refinedIdea: _extractSection(content, 'THE REFINED IDEA'),
      readyPrompt: _extractSection(content, 'YOUR READY-TO-USE PROMPT'),
      actionPlan: _extractActionPlan(content),
      alternatives: _extractList(content, 'ALTERNATIVE ANGLES'),
      riskiestAssumption: _extractSection(content, 'RISKIEST ASSUMPTION'),
    );

    // If nothing meaningful was extracted, consider it a failure
    if (result.refinedIdea.isEmpty &&
        result.readyPrompt.isEmpty &&
        result.actionPlan.isEmpty &&
        result.alternatives.isEmpty &&
        result.riskiestAssumption.isEmpty) {
      return null;
    }

    return result;
  }

  static String _extractSection(String text, String header) {
    final pattern = RegExp(
      r'(?:#{1,3}\s*|(?:\*\*))' +
          RegExp.escape(header) +
          r'(?:\*\*)?\s*\n([\s\S]+?)(?=\n(?:#{1,3}\s|\*\*[A-Z])|\Z)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  static List<String> _extractList(String text, String header) {
    final section = _extractSection(text, header);
    if (section.isEmpty) return [];

    return section
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*[-*•\d.]+\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static List<ActionStep> _extractActionPlan(String text) {
    var section = _extractSection(text, 'ACTION PLAN');
    if (section.isEmpty) {
      section = _extractSection(text, 'DO THESE 3 THINGS TODAY');
    }
    if (section.isEmpty) return [];

    final lines = section
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && RegExp(r'^[\d.\-*]').hasMatch(l))
        .toList();

    return lines.asMap().entries.map((entry) {
      final clean = entry.value.replaceFirst(RegExp(r'^\s*[\d.]+\s*'), '');
      final parts = clean.split(RegExp(r'\s*[—–-]\s*'));
      return ActionStep(
        stepNumber: entry.key + 1,
        title: parts[0].replaceFirst(RegExp(r'^[\*\[\]]+\s*'), '').trim(),
        description: parts.length > 1 ? parts.sublist(1).join(' — ').trim() : '',
      );
    }).toList();
  }
}

// ───────────────────────────────────────────────────────────
//  ParseException
// ───────────────────────────────────────────────────────────

class ParseException implements Exception {
  const ParseException(this.message);
  final String message;

  @override
  String toString() => 'ParseException: $message';
}

// ───────────────────────────────────────────────────────────
//  CategoryResult helpers (internal)
// ───────────────────────────────────────────────────────────

void _requireField(Map<String, dynamic> json, String key) {
  if (_hasKey(json, key)) return;
  final camelCase = _snakeToCamel(key);
  if (_hasKey(json, camelCase)) return;
  throw ParseException('Missing required field: "$key"');
}

void _requireList(Map<String, dynamic> json, String key) {
  if (_hasKey(json, key)) {
    if (json[key] is! List) {
      throw ParseException('Field "$key" must be a List');
    }
    return;
  }
  final camelCase = _snakeToCamel(key);
  if (_hasKey(json, camelCase)) {
    if (json[camelCase] is! List) {
      throw ParseException('Field "$key" must be a List');
    }
    return;
  }
  throw ParseException('Missing required field: "$key"');
}

bool _hasKey(Map<String, dynamic> json, String key) {
  return json.containsKey(key) && json[key] != null;
}

String _snakeToCamel(String snake) {
  final parts = snake.split('_');
  if (parts.length <= 1) return snake;
  return parts[0] + parts.sublist(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

// ── Coding ────────────────────────────────────────────────

class _CodingResult {

  _CodingResult.fromJson(Map<String, dynamic> json)
      : systemArchitecture = (json['system_architecture'] ?? json['systemArchitecture'] ?? '') as String,
        techStack = _parseStringList(json['tech_stack'] ?? json['techStack']),
        implementationPlan = _parseImplList(json['implementation_plan'] ?? json['implementationPlan']),
        edgeCases = _parseStringList(json['edge_cases'] ?? json['edgeCases']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'system_architecture');
    _requireList(json, 'implementation_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String systemArchitecture;
  final List<String> techStack;
  final List<_ImplItem> implementationPlan;
  final List<String> edgeCases;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: systemArchitecture.isNotEmpty
            ? systemArchitecture
            : 'System architecture proposal',
        readyPrompt: 'Tech stack: ${techStack.join(', ')}',
        actionPlan: implementationPlan
            .map((i) => ActionStep(
                  stepNumber: i.priority == 'high'
                      ? 1
                      : i.priority == 'medium'
                          ? 2
                          : 3,
                  title: i.title,
                  description: i.description,
                ))
            .toList(),
        alternatives: edgeCases.isNotEmpty ? edgeCases : techStack,
        riskiestAssumption: riskiestAssumption,
      );
}

// ── Marketing ─────────────────────────────────────────────

class _MarketingResult {

  _MarketingResult.fromJson(Map<String, dynamic> json)
      : positioning = (json['positioning'] ?? '') as String,
        viralHooks = _parseStringList(json['viral_hooks'] ?? json['viralHooks']),
        distributionPlan = _parseImplList(json['distribution_plan'] ?? json['distributionPlan']),
        alternativeChannels = _parseStringList(json['alternative_channels'] ?? json['alternativeChannels']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'positioning');
    _requireList(json, 'distribution_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String positioning;
  final List<String> viralHooks;
  final List<_ImplItem> distributionPlan;
  final List<String> alternativeChannels;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: positioning,
        readyPrompt: 'Viral hooks: ${viralHooks.join('; ')}',
        actionPlan: distributionPlan
            .asMap()
            .entries
            .map((e) => ActionStep(
                  stepNumber: e.key + 1,
                  title: e.value.title,
                  description: e.value.description,
                ))
            .toList(),
        alternatives: alternativeChannels.isNotEmpty ? alternativeChannels : viralHooks,
        riskiestAssumption: riskiestAssumption,
      );
}

// ── Business ──────────────────────────────────────────────

class _BusinessResult {

  _BusinessResult.fromJson(Map<String, dynamic> json)
      : businessModel = (json['business_model'] ?? json['businessModel'] ?? '') as String,
        unfairAdvantage = (json['unfair_advantage'] ?? json['unfairAdvantage'] ?? '') as String,
        actionPlan = _parseImplList(json['action_plan'] ?? json['actionPlan']),
        pivotAngles = _parseStringList(json['pivot_angles'] ?? json['pivotAngles']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'business_model');
    _requireList(json, 'action_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String businessModel;
  final String unfairAdvantage;
  final List<_ImplItem> actionPlan;
  final List<String> pivotAngles;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: businessModel,
        readyPrompt: 'Unfair advantage: $unfairAdvantage',
        actionPlan: actionPlan
            .asMap()
            .entries
            .map((e) => ActionStep(
                  stepNumber: e.key + 1,
                  title: e.value.title,
                  description: e.value.description,
                ))
            .toList(),
        alternatives: pivotAngles,
        riskiestAssumption: riskiestAssumption,
      );
}

// ── Writing ───────────────────────────────────────────────

class _WritingResult {

  _WritingResult.fromJson(Map<String, dynamic> json)
      : narrativeArc = (json['narrative_arc'] ?? json['narrativeArc'] ?? '') as String,
        headlineIdeas = _parseStringList(json['headline_ideas'] ?? json['headlineIdeas']),
        draftingPlan = _parseImplList(json['drafting_plan'] ?? json['draftingPlan']),
        alternativeAngles = _parseStringList(json['alternative_angles'] ?? json['alternativeAngles']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'narrative_arc');
    _requireList(json, 'drafting_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String narrativeArc;
  final List<String> headlineIdeas;
  final List<_ImplItem> draftingPlan;
  final List<String> alternativeAngles;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: narrativeArc,
        readyPrompt: 'Headline ideas: ${headlineIdeas.join('; ')}',
        actionPlan: draftingPlan
            .asMap()
            .entries
            .map((e) => ActionStep(
                  stepNumber: e.key + 1,
                  title: e.value.title,
                  description: e.value.description,
                ))
            .toList(),
        alternatives: alternativeAngles,
        riskiestAssumption: riskiestAssumption,
      );
}

// ── Design ────────────────────────────────────────────────

class _DesignResult {

  _DesignResult.fromJson(Map<String, dynamic> json)
      : coreExperience = (json['core_experience'] ?? json['coreExperience'] ?? '') as String,
        keyScreens = _parseStringList(json['key_screens'] ?? json['keyScreens']),
        designPlan = _parseImplList(json['design_plan'] ?? json['designPlan']),
        alternativePatterns = _parseStringList(json['alternative_patterns'] ?? json['alternativePatterns']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'core_experience');
    _requireList(json, 'design_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String coreExperience;
  final List<String> keyScreens;
  final List<_ImplItem> designPlan;
  final List<String> alternativePatterns;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: coreExperience,
        readyPrompt: 'Key screens: ${keyScreens.join(', ')}',
        actionPlan: designPlan
            .asMap()
            .entries
            .map((e) => ActionStep(
                  stepNumber: e.key + 1,
                  title: e.value.title,
                  description: e.value.description,
                ))
            .toList(),
        alternatives: alternativePatterns,
        riskiestAssumption: riskiestAssumption,
      );
}

// ── Personal ──────────────────────────────────────────────

class _PersonalResult {

  _PersonalResult.fromJson(Map<String, dynamic> json)
      : refinedGoal = (json['refined_goal'] ?? json['refinedGoal'] ?? '') as String,
        habitLoop = _HabitLoop.fromJson(json['habit_loop'] ?? json['habitLoop']),
        actionPlan = _parseImplList(json['action_plan'] ?? json['actionPlan']),
        failStateProtocols = _parseStringList(json['fail_state_protocols'] ?? json['failStateProtocols']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'refined_goal');
    _requireList(json, 'action_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String refinedGoal;
  final _HabitLoop habitLoop;
  final List<_ImplItem> actionPlan;
  final List<String> failStateProtocols;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: refinedGoal,
        readyPrompt:
            'Habit loop — Trigger: ${habitLoop.trigger}, Action: ${habitLoop.action}, Reward: ${habitLoop.reward}',
        actionPlan: actionPlan
            .asMap()
            .entries
            .map((e) => ActionStep(
                  stepNumber: e.key + 1,
                  title: e.value.title,
                  description: e.value.description,
                ))
            .toList(),
        alternatives: failStateProtocols,
        riskiestAssumption: riskiestAssumption,
      );
}

class _HabitLoop {

  _HabitLoop.fromJson(dynamic json)
      : trigger = (json['trigger'] ?? '') as String,
        action = (json['action'] ?? '') as String,
        reward = (json['reward'] ?? '') as String;
  final String trigger;
  final String action;
  final String reward;
}

// ── General ───────────────────────────────────────────────

class _GeneralResult {

  _GeneralResult.fromJson(Map<String, dynamic> json)
      : refinedIdea = (json['refined_idea'] ?? json['refinedIdea'] ?? '') as String,
        readyPrompt = (json['ready_prompt'] ?? json['readyPrompt'] ?? '') as String,
        actionPlan = _parseImplList(json['action_plan'] ?? json['actionPlan']),
        alternativeAngles = _parseStringList(json['alternative_angles'] ?? json['alternativeAngles']),
        riskiestAssumption = (json['riskiest_assumption'] ?? json['riskiestAssumption'] ?? '') as String {
    _requireField(json, 'refined_idea');
    _requireList(json, 'action_plan');
    _requireField(json, 'riskiest_assumption');
  }
  final String refinedIdea;
  final String readyPrompt;
  final List<_ImplItem> actionPlan;
  final List<String> alternativeAngles;
  final String riskiestAssumption;

  BrainstormResult toBrainstormResult() => BrainstormResult(
        refinedIdea: refinedIdea,
        readyPrompt: readyPrompt,
        actionPlan: actionPlan
            .asMap()
            .entries
            .map((e) => ActionStep(
                  stepNumber: e.key + 1,
                  title: e.value.title,
                  description: e.value.description,
                ))
            .toList(),
        alternatives: alternativeAngles,
        riskiestAssumption: riskiestAssumption,
      );
}

// ── Shared parsers ────────────────────────────────────────

class _ImplItem {

  _ImplItem({required this.title, required this.description, this.priority = 'medium'});
  final String title;
  final String description;
  final String priority;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((v) => v.toString()).toList();
  return [];
}

List<_ImplItem> _parseImplList(dynamic value) {
  if (value == null) return [];
  if (value is! List) return [];
  return value.map((item) {
    if (item is Map<String, dynamic>) {
      return _ImplItem(
        title: (item['title'] ?? 'Step').toString(),
        description: (item['description'] ?? '').toString(),
        priority: (item['priority'] ?? 'medium').toString(),
      );
    }
    return _ImplItem(title: item.toString(), description: '');
  }).toList();
}

// ───────────────────────────────────────────────────────────
//  CategorySchema — JSON schema descriptions for prompts
// ───────────────────────────────────────────────────────────

class CategorySchema {

  const CategorySchema._({required this.category, required this.description});
  final BrainstormCategory category;
  final String description;

  /// Returns the JSON schema description for the given category.
  /// This text is injected into the final prompt so the model knows
  /// exactly what JSON structure to emit.
  static String forCategory(BrainstormCategory category) {
    switch (category) {
      case BrainstormCategory.coding:
        return _codingSchema;
      case BrainstormCategory.marketing:
        return _marketingSchema;
      case BrainstormCategory.business:
        return _businessSchema;
      case BrainstormCategory.writing:
        return _writingSchema;
      case BrainstormCategory.design:
        return _designSchema;
      case BrainstormCategory.personal:
        return _personalSchema;
      case BrainstormCategory.general:
        return _generalSchema;
    }
  }

  static const String _codingSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "system_architecture": "string — 2-3 sentence technical design summary",
  "tech_stack": ["string"],
  "implementation_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "edge_cases": ["string"],
  "riskiest_assumption": "string — one assumption that could ruin scalability"
}''';

  static const String _marketingSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "positioning": "string — 2-3 sentence value prop and target audience",
  "viral_hooks": ["string"],
  "distribution_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "alternative_channels": ["string"],
  "riskiest_assumption": "string — one audience assumption that could kill the campaign"
}''';

  static const String _businessSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "business_model": "string — 2-3 sentence summary of value prop, buyer, monetization",
  "unfair_advantage": "string — brief moat explanation",
  "action_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "pivot_angles": ["string"],
  "riskiest_assumption": "string — one willingness-to-pay assumption that could kill the business"
}''';

  static const String _writingSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "narrative_arc": "string — 2-3 sentence core message and emotional journey",
  "headline_ideas": ["string"],
  "drafting_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "alternative_angles": ["string"],
  "riskiest_assumption": "string — one narrative part that might fail to resonate"
}''';

  static const String _designSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "core_experience": "string — 2-3 sentence user journey and aesthetic vibe",
  "key_screens": ["string"],
  "design_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "alternative_patterns": ["string"],
  "riskiest_assumption": "string — one interaction users might fail to understand"
}''';

  static const String _personalSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "refined_goal": "string — 2-3 sentence specific, measurable, time-bound goal",
  "habit_loop": {
    "trigger": "string",
    "action": "string",
    "reward": "string"
  },
  "action_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "fail_state_protocols": ["string"],
  "riskiest_assumption": "string — one hidden excuse or constraint that usually causes failure"
}''';

  static const String _generalSchema = '''
Respond ONLY with a valid JSON object matching this schema:
{
  "refined_idea": "string — 2-3 sentence specific, narrowed idea",
  "ready_prompt": "string — a high-quality prompt the user can paste into ChatGPT/Claude/Gemini",
  "action_plan": [
    {"title": "string", "description": "string", "priority": "high|medium|low"}
  ],
  "alternative_angles": ["string"],
  "riskiest_assumption": "string — one thing that if wrong kills this idea"
}''';
}
