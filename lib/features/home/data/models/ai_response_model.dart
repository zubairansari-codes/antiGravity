/// AI response DTO — parses OpenAI output into domain objects.
///
/// For conversational mode, just wraps the text.
/// For final output mode, parses the structured markdown
/// into a [BrainstormResult] with action steps and alternatives.
library;

import '../../domain/entities/ai_response.dart';
import '../../domain/entities/brainstorm_result.dart';

class AIResponseModel {
  final String text;
  final bool isFinal;
  final BrainstormResult? structuredResult;

  const AIResponseModel({
    required this.text,
    required this.isFinal,
    this.structuredResult,
  });

  /// Parse raw AI content into a model.
  factory AIResponseModel.fromContent(
    String content, {
    required bool isFinal,
  }) {
    if (!isFinal) {
      return AIResponseModel(text: content, isFinal: false);
    }

    return AIResponseModel(
      text: content,
      isFinal: true,
      structuredResult: _parseResult(content),
    );
  }

  /// Convert to domain entity.
  AIResponse toEntity() => AIResponse(
        text: text,
        isFinal: isFinal,
        structuredResult: structuredResult,
      );

  // ── Parsing helpers ─────────────────────────────────────

  static BrainstormResult _parseResult(String content) {
    return BrainstormResult(
      refinedIdea: _extractSection(content, 'THE REFINED IDEA'),
      readyPrompt: _extractSection(content, 'YOUR READY-TO-USE PROMPT'),
      actionPlan: _extractActionPlan(content),
      alternatives: _extractList(content, 'ALTERNATIVE ANGLES'),
      riskiestAssumption: _extractSection(content, 'RISKIEST ASSUMPTION'),
    );
  }

  /// Extract a section by its header — grabs everything until the next header.
  static String _extractSection(String text, String header) {
    // Match "## HEADER" or "### HEADER" or "**HEADER**" patterns
    final pattern = RegExp(
      r'(?:#{1,3}\s*|(?:\*\*))' + RegExp.escape(header) + r'(?:\*\*)?\s*\n([\s\S]+?)(?=\n(?:#{1,3}\s|\*\*[A-Z])|\Z)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  /// Extract numbered list items from a section.
  static List<String> _extractList(String text, String header) {
    final section = _extractSection(text, header);
    if (section.isEmpty) return [];

    return section
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^\s*[-*•\d.]+\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Extract the 3-step action plan.
  static List<ActionStep> _extractActionPlan(String text) {
    // Try multiple header formats
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
      // Split on em dash or regular dash with spaces
      final parts = clean.split(RegExp(r'\s*[—–-]\s*'));
      return ActionStep(
        stepNumber: entry.key + 1,
        title: parts[0].replaceFirst(RegExp(r'^[*\[\]]+\s*'), '').trim(),
        description: parts.length > 1 ? parts.sublist(1).join(' — ').trim() : '',
      );
    }).toList();
  }
}
