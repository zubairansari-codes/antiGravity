/// Data source interface for remote Groq API calls.
///
/// Allows mocking in tests and decouples the repository
/// from concrete Dio implementations.
library;

import '../../domain/entities/brainstorm_category.dart';
import '../models/ai_response_model.dart';
import '../models/message_model.dart';

abstract class IBrainstormRemoteDataSource {
  /// Send conversation history to Groq and get a response.
  ///
  /// When [requestFinal] is true, uses the final output system prompt.
  /// Otherwise uses the conversational system prompt.
  Future<AIResponseModel> sendMessage(
    List<MessageModel> messages, {
    required bool requestFinal,
    required BrainstormCategory category,
  });
}
