/// Rich, category-specific prompt configuration.
///
/// Each [BrainstormCategory] gets a profile that defines:
/// - The AI persona for that category
/// - What the final output should accomplish
/// - Step-by-step synthesis instructions
/// - Quality criteria for the output
/// - A template for the copy-paste-ready "ready prompt"
/// - Common pitfalls to avoid
library;

import '../entities/artefact_type.dart';
import '../entities/brainstorm_category.dart';
import '../entities/riff_style.dart';

class CategoryPromptProfile {
  const CategoryPromptProfile({
    required this.category,
    required this.persona,
    required this.voice,
    required this.riffStyle,
    required this.outputFormats,
    required this.goal,
    required this.synthesisSteps,
    required this.qualityCriteria,
    required this.readyPromptTemplate,
    required this.commonPitfalls,
    this.lenses = const [],
    this.examples = const {},
  });

  final BrainstormCategory category;

  /// Domain expertise the AI can draw on, e.g. "Senior Staff Engineer".
  final String persona;

  /// Short tone description for spoken responses, e.g. "curious sparring partner".
  final String voice;

  /// Default improvisation tactic for this category.
  final RiffStyle riffStyle;

  /// Artefact formats this category can produce at the end of a session.
  final List<ArtefactType> outputFormats;

  /// One-sentence goal for the final output.
  final String goal;

  /// Ordered steps the model should follow to synthesize the brainstorm.
  final List<String> synthesisSteps;

  /// Checklist the final output must satisfy.
  final List<String> qualityCriteria;

  /// Template for the ready_prompt field.
  /// Use [bracketed] placeholders for values extracted from the brainstorm.
  final String readyPromptTemplate;

  /// Common mistakes for this category that the model should avoid.
  final List<String> commonPitfalls;

  /// Optional cross-domain lenses this category can borrow from.
  final List<String> lenses;

  /// Optional example snippets (key -> short example text).
  final Map<String, String> examples;
}
