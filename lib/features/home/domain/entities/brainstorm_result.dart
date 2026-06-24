/// The final deliverable from a brainstorming session.
///
/// Contains everything the user gets at the end:
/// refined idea, ready prompt, 3-step action plan,
/// alternative angles, and riskiest assumption.
library;

class BrainstormResult {
  final String refinedIdea;
  final String readyPrompt;
  final List<ActionStep> actionPlan;
  final List<String> alternatives;
  final String riskiestAssumption;

  const BrainstormResult({
    required this.refinedIdea,
    required this.readyPrompt,
    required this.actionPlan,
    required this.alternatives,
    required this.riskiestAssumption,
  });

  @override
  String toString() => 'BrainstormResult(idea: ${refinedIdea.length > 30 ? '${refinedIdea.substring(0, 30)}…' : refinedIdea})';
}

/// A single step in the 3-step action plan.
class ActionStep {
  final int stepNumber;
  final String title;
  final String description;

  const ActionStep({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  @override
  String toString() => 'ActionStep($stepNumber: $title)';
}
