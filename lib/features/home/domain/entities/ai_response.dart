/// AI response wrapper — returned by the remote data source.
///
/// Sits in the domain layer because use cases need to know
/// whether the response is conversational or a final structured output.
library;

import 'brainstorm_result.dart';
import 'conversation_artefact.dart';

class AIResponse {

  const AIResponse({
    required this.text,
    required this.isFinal,
    this.structuredResult,
    this.artefacts = const [],
    this.isWarning = false,
    this.contextSummary,
  });
  /// The raw text content from the AI.
  final String text;

  /// Whether this is the final structured output (vs conversation).
  final bool isFinal;

  /// Parsed legacy result — kept for backward compatibility.
  final BrainstormResult? structuredResult;

  /// Flexible artefacts produced at the end of a session.
  final List<ConversationArtefact> artefacts;

  /// Whether this response was generated because of a soft moderation warning.
  final bool isWarning;

  /// Optional plain-text summary of the conversation context so far.
  final String? contextSummary;

  @override
  String toString() => 'AIResponse(isFinal: $isFinal, artefacts: ${artefacts.length})';

  AIResponse copyWith({
    String? text,
    bool? isFinal,
    BrainstormResult? structuredResult,
    List<ConversationArtefact>? artefacts,
    bool? isWarning,
    String? contextSummary,
  }) =>
      AIResponse(
        text: text ?? this.text,
        isFinal: isFinal ?? this.isFinal,
        structuredResult: structuredResult ?? this.structuredResult,
        artefacts: artefacts ?? this.artefacts,
        isWarning: isWarning ?? this.isWarning,
        contextSummary: contextSummary ?? this.contextSummary,
      );
}
