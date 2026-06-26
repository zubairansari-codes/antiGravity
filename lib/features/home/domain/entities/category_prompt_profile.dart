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

import '../entities/brainstorm_category.dart';

class CategoryPromptProfile {
  const CategoryPromptProfile({
    required this.category,
    required this.persona,
    required this.goal,
    required this.synthesisSteps,
    required this.qualityCriteria,
    required this.readyPromptTemplate,
    required this.commonPitfalls,
    this.examples = const {},
  });

  final BrainstormCategory category;

  /// Short persona description, e.g. "Senior Staff Engineer".
  final String persona;

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

  /// Optional example snippets (key -> short example text).
  final Map<String, String> examples;
}
