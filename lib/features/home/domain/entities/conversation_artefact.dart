/// A concrete artefact produced at the end of an improv session.
///
/// Unlike the rigid five-field [BrainstormResult], an artefact is free-form
/// markdown content chosen to match what the conversation actually needs.
library;

import 'artefact_type.dart';

class ConversationArtefact {

  const ConversationArtefact({
    required this.artefactType,
    required this.title,
    required this.content,
    this.followUpQuestions = const [],
  });

  /// The chosen format for this artefact.
  final ArtefactType artefactType;

  /// A short, descriptive title.
  final String title;

  /// Markdown-friendly body content.
  final String content;

  /// Optional sparks the user can follow next.
  final List<String> followUpQuestions;

  ConversationArtefact copyWith({
    ArtefactType? artefactType,
    String? title,
    String? content,
    List<String>? followUpQuestions,
  }) {
    return ConversationArtefact(
      artefactType: artefactType ?? this.artefactType,
      title: title ?? this.title,
      content: content ?? this.content,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
    );
  }

  @override
  String toString() => 'ConversationArtefact(${artefactType.id}, "$title")';
}
