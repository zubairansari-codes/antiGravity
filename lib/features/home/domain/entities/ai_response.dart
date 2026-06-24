/// AI response wrapper — returned by the remote data source.
///
/// Sits in the domain layer because use cases need to know
/// whether the response is conversational or a final structured output.
library;

import 'brainstorm_result.dart';

class AIResponse {
  /// The raw text content from the AI.
  final String text;

  /// Whether this is the final structured output (vs conversation).
  final bool isFinal;

  /// Parsed result — only present when [isFinal] is true.
  final BrainstormResult? structuredResult;

  const AIResponse({
    required this.text,
    required this.isFinal,
    this.structuredResult,
  });

  @override
  String toString() => 'AIResponse(isFinal: $isFinal, len: ${text.length})';
}
