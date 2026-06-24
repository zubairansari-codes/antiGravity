/// Remote data source — sends messages to the Groq API (OpenAI-compatible).
///
/// Contains the two system prompts:
/// 1. Conversation mode (short, one-question-at-a-time)
/// 2. Final output mode (structured result with sections)
library;

import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../models/ai_response_model.dart';
import '../models/message_model.dart';
import 'prompt_factory.dart';

class BrainstormRemoteDataSource {
  final Dio _dio;

  const BrainstormRemoteDataSource(this._dio);

  /// Send conversation history to Groq and get a response.
  ///
  /// When [requestFinal] is true, uses the final output system prompt.
  /// Otherwise uses the conversational system prompt.
  Future<AIResponseModel> sendMessage(
    List<MessageModel> messages, {
    required bool requestFinal,
    required BrainstormCategory category,
  }) async {
    final model = requestFinal
        ? AppConstants.finalOutputModel
        : AppConstants.conversationModel;

    // Build the messages array with system prompt first.
    final apiMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': PromptFactory.getSystemPrompt(category: category, isFinal: requestFinal),
      },
      ...messages.map((m) => m.toJson()),
    ];

    final response = await _dio.post(
      '/chat/completions',
      data: {
        'model': model,
        'messages': apiMessages,
        'temperature': requestFinal ? 0.7 : 0.9,
        'max_tokens': requestFinal ? 2000 : 500,
      },
    );

    // Extract response text (OpenAI format).
    final choices = response.data['choices'] as List;
    final content = choices[0]['message']['content'] as String;

    return AIResponseModel.fromContent(content, isFinal: requestFinal);
  }
}
