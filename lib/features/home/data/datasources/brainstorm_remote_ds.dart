/// Remote data source — sends messages to the Groq API (OpenAI-compatible).
///
/// Contains the two system prompts:
/// 1. Conversation mode (short, one-question-at-a-time)
/// 2. Final output mode (structured JSON result with schema validation)
///
/// Also enforces input validation, PII redaction, and content moderation.
library;

import 'package:dio/dio.dart';

import '../../domain/entities/brainstorm_category.dart';
import '../models/ai_response_model.dart';
import '../models/message_model.dart';
import 'brainstorm_remote_ds_interface.dart';
import 'content_moderation_service.dart';
import 'pii_filter.dart';
import 'prompt_factory.dart';

/// Model constants — conversation uses a cheap/fast model,
/// final output uses a high-quality model.
const String _conversationModel = 'llama-3.1-8b-instant';
const String _finalOutputModel = 'llama-3.3-70b-versatile';

class BrainstormRemoteDataSource implements IBrainstormRemoteDataSource {

  BrainstormRemoteDataSource(this._dio);
  final Dio _dio;

  /// Rate-limiting: track last request timestamp.
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 3);

  /// Validate user input before sending to the API.
  ValidationError? validateInput(String message) {
    // Length check
    if (message.length > 1000) {
      return ValidationError(
        'Message too long (${message.length} chars). Max 1000 characters.',
      );
    }

    // Prompt injection patterns
    final lower = message.toLowerCase();
    final injectionPatterns = [
      'ignore all previous instructions',
      'ignore previous instructions',
      'forget everything',
      'forget all',
      'DAN',
      'do anything now',
      'system prompt',
      'you are now',
      'new instructions:',
      'override previous',
      'disregard',
    ];
    for (final pattern in injectionPatterns) {
      if (lower.contains(pattern)) {
        return const ValidationError('Input contains potentially unsafe patterns.');
      }
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        final remaining = _minRequestInterval.inSeconds - elapsed.inSeconds;
        return ValidationError(
          'Please wait $remaining seconds before sending another message.',
        );
      }
    }

    return null;
  }

  @override
  Future<AIResponseModel> sendMessage(
    List<MessageModel> messages, {
    required bool requestFinal,
    required BrainstormCategory category,
  }) async {
    // Validate the most recent user message
    final lastUserMessage = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => const MessageModel(role: 'user', content: ''),
    );

    final validationError = validateInput(lastUserMessage.content);
    if (validationError != null) {
      throw ValidationException(validationError.message);
    }

    // Content moderation
    final moderation = ContentModerationService.moderate(
      text: lastUserMessage.content,
      category: category,
    );
    if (moderation.shouldBlock) {
      throw ValidationException(moderation.reason);
    }

    // PII redaction
    final redaction = PiiFilter.redact(lastUserMessage.content);
    final sanitizedMessages = redaction.wasRedacted
        ? messages.map((m) {
            if (m.role == 'user' && m.content == lastUserMessage.content) {
              return MessageModel(
                role: m.role,
                content: redaction.redactedText,
              );
            }
            return m;
          }).toList()
        : messages;

    final model = requestFinal ? _finalOutputModel : _conversationModel;

    // Build the messages array with system prompt first.
    final apiMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': PromptFactory.getSystemPrompt(
          category: category,
          isFinal: requestFinal,
        ),
      },
      ...sanitizedMessages.map((m) => m.toJson()),
    ];

    // For final output, request JSON mode (Groq supports OpenAI response_format)
    final requestData = requestFinal
        ? {
            'model': model,
            'messages': apiMessages,
            'temperature': 0.7,
            'max_tokens': 2000,
            'response_format': {'type': 'json_object'},
          }
        : {
            'model': model,
            'messages': apiMessages,
            'temperature': 0.9,
            'max_tokens': 500,
          };

    _lastRequestTime = DateTime.now();

    final response = await _dio.post(
      '/chat/completions',
      data: requestData,
    );

    // Extract response text (OpenAI format).
    final choices = response.data['choices'] as List;
    final content = choices[0]['message']['content'] as String;

    return AIResponseModel.fromContent(
      content,
      isFinal: requestFinal,
      category: category,
    );
  }
}

/// Simple validation error wrapper.
class ValidationError {
  const ValidationError(this.message);
  final String message;
}

/// Custom exception for validation failures in the remote data source.
class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}
