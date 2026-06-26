/// Modes that shape how the AI improvises with the user.
library;

enum ConversationMode {
  riff(
    id: 'riff',
    label: 'Riff',
    description: 'Free-flowing yes-and improvisation.',
  ),
  deepDive(
    id: 'deepDive',
    label: 'Deep dive',
    description: 'Explore one thread in depth before moving on.',
  ),
  flip(
    id: 'flip',
    label: 'Flip it',
    description: 'Invert, challenge, or reframe the current idea.',
  ),
  synthesise(
    id: 'synthesise',
    label: 'Synthesise',
    description: 'Distil the conversation into a concrete takeaway.',
  );

  const ConversationMode({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  static ConversationMode fromId(String id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => ConversationMode.riff,
    );
  }
}
