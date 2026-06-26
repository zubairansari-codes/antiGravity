/// Chat message entity — a single exchange in a brainstorming session.
///
/// Pure domain object. No Flutter imports. No serialisation logic.
library;

enum MessageRole { user, assistant }

class ChatMessage {

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  /// Convenience factory for user messages.
  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

  /// Convenience factory for assistant messages.
  factory ChatMessage.assistant(String content) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChatMessage($role: ${content.length > 40 ? '${content.substring(0, 40)}…' : content})';
}
