/// Sliding-window conversation context manager.
///
/// Keeps the last N turns verbatim and summarizes older turns
/// to stay within token limits and keep the API cost low.
library;

import '../../domain/entities/brainstorm_category.dart';
import '../models/message_model.dart';
import 'brainstorm_remote_ds_interface.dart';

class ConversationContextManager {

  const ConversationContextManager(this._remote);
  final IBrainstormRemoteDataSource _remote;

  /// Number of recent turns to keep verbatim (each turn = user + assistant).
  static const int _maxVerbatimTurns = 7;

  /// Threshold at which summarization kicks in.
  static const int _summarizeThreshold = 12;

  /// Build an optimized message list for the API.
  ///
  /// If the conversation is short, returns it verbatim.
  /// If long, summarizes older turns and appends recent ones.
  Future<List<MessageModel>> buildMessages(List<MessageModel> allMessages) async {
    if (allMessages.length <= _maxVerbatimTurns) {
      return allMessages;
    }

    final olderMessages = allMessages.sublist(0, allMessages.length - _maxVerbatimTurns);
    final recentMessages = allMessages.sublist(allMessages.length - _maxVerbatimTurns);

    final summary = await _summarize(olderMessages);

    return [
      MessageModel(
        role: 'system',
        content: 'Summary of earlier conversation: $summary',
      ),
      ...recentMessages,
    ];
  }

  /// Whether the conversation has grown long enough to need summarization.
  bool shouldSummarize(List<MessageModel> messages) =>
      messages.length > _summarizeThreshold;

  /// Summarize a list of older messages using the cheap conversation model.
  Future<String> _summarize(List<MessageModel> messages) async {
    const summarySystemPrompt =
        'You are a conversation summarizer. Summarize the following messages '
        'in 2-3 concise sentences. Extract only the key facts, decisions, and '
        'open questions. Do not include pleasantries or filler.';

    try {
      final response = await _remote.sendMessage(
        [
          const MessageModel(role: 'system', content: summarySystemPrompt),
          ...messages,
        ],
        requestFinal: false,
        category: BrainstormCategory.general,
      );
      return response.text;
    } catch (e) {
      // If summarization fails, return a truncated summary
      return 'Previous conversation context could not be summarized. '
          'Key topics: ${_extractKeywords(messages)}';
    }
  }

  /// Fallback keyword extraction when API summarization fails.
  String _extractKeywords(List<MessageModel> messages) {
    final words = messages
        .map((m) => m.content)
        .join(' ')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 4)
        .toList();
    final frequency = <String, int>{};
    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).join(', ');
  }
}
