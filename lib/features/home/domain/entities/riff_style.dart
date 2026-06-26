/// Improvisation tactics the AI can use while riffing.
library;

enum RiffStyle {
  yesAnd('yesAnd', 'Yes, and…'),
  constraint('constraint', 'Constraint'),
  mirror('mirror', 'Mirror'),
  escalate('escalate', 'Escalate'),
  lateral('lateral', 'Lateral');

  const RiffStyle(this.id, this.label);

  final String id;
  final String label;

  static RiffStyle fromId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => RiffStyle.yesAnd,
    );
  }
}
