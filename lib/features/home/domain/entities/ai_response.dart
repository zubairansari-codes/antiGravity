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
  });
  /// The raw text content from the AI.
  final String text;

  /// Whether this is the final structured output (vs conversation).
  final bool isFinal;

  /// Parsed legacy result — kept for backward compatibility.
  final BrainstormResult? structuredResult;

  /// Flexible artefacts produced at the end of a session.
  final List<ConversationArtefact> artefacts;

  @override
  String toString() => 'AIResponse(isFinal: $isFinal, artefacts: ${artefacts.length})';
}
