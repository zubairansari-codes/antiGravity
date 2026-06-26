/// A saved brainstorming session.
///
/// Groups the conversation history, optional final result,
/// and metadata for display on the home screen.
library;

import 'brainstorm_category.dart';
import 'brainstorm_result.dart';
import 'chat_message.dart';
import 'conversation_artefact.dart';

class Brainstorm {

  const Brainstorm({
    required this.id,
    required this.title,
    this.category = BrainstormCategory.general,
    required this.messages,
    this.result,
    this.artefacts = const [],
    required this.createdAt,
  });
  final String id;
  final String title;
  final BrainstormCategory category;
  final List<ChatMessage> messages;

  /// Legacy structured result — kept for backward compatibility.
  final BrainstormResult? result;

  /// New flexible artefacts produced at the end of the session.
  final List<ConversationArtefact> artefacts;
  final DateTime createdAt;

  /// Create a copy with updated fields.
  Brainstorm copyWith({
    String? id,
    String? title,
    BrainstormCategory? category,
    List<ChatMessage>? messages,
    BrainstormResult? result,
    List<ConversationArtefact>? artefacts,
    DateTime? createdAt,
  }) {
    return Brainstorm(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      messages: messages ?? this.messages,
      result: result ?? this.result,
      artefacts: artefacts ?? this.artefacts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether this session has been completed with a final output.
  bool get isComplete => result != null || artefacts.isNotEmpty;

  /// Short preview text for the home screen card.
  String get preview {
    if (messages.isEmpty) return 'Empty brainstorm';
    final first = messages.first.content;
    return first.length > 80 ? '${first.substring(0, 80)}…' : first;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Brainstorm &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Brainstorm($id, "$title", ${messages.length} msgs)';
}
