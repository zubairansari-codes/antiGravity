/// Remote data source — sends messages to the Groq API (OpenAI-compatible).
///
/// Contains the two system prompts:
/// 1. Conversation mode (short, one-question-at-a-time)
/// 2. Final output mode (structured JSON result with schema validation)
///
/// Also enforces input validation, PII redaction, and content moderation.
library;

import 'package:dio/dio.dart';

import '../../domain/entities/artefact_type.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/conversation_artefact.dart';
import '../../domain/entities/conversation_mode.dart';
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

const String _caringResponse = '''
It sounds like things feel heavy right now. I'm here to riff with you, and I also want to gently note that talking with a mental health professional or someone you trust can make a real difference. If you're in crisis, reach out to your local emergency number or a crisis line. Whenever you're ready, we can keep creating together — or switch topics whenever you like.
''';

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
    ConversationMode mode = ConversationMode.riff,
    ArtefactType? requestedArtefact,
    List<ConversationArtefact> previousArtefacts = const [],
    String? contextSummary,
  }) async {
    // Validate the most recent user message
    final lastUserMessage = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => throw const ValidationException('No user message found.'),
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

    // For mental-health warnings, respond with a caring improvisational message
    // without calling the API or exposing the user's raw input further.
    if (moderation.shouldWarn) {
      return const AIResponseModel(
        text: _caringResponse,
        isFinal: false,
        isWarning: true,
      );
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

    _lastRequestTime = DateTime.now();

    final model = requestFinal ? _finalOutputModel : _conversationModel;

    // Build the messages array with system prompt first.
    final apiMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': PromptFactory.getSystemPrompt(
          category: category,
          isFinal: requestFinal,
          mode: mode,
          requestedArtefact: requestedArtefact,
          contextSummary: contextSummary,
          previousArtefacts: previousArtefacts,
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

    final response = await _dio.post(
      '/chat/completions',
      data: requestData,
    );

    final content = _extractContent(response);

    return AIResponseModel.fromContent(
      content,
      isFinal: requestFinal,
      category: category,
    );
  }

  @override
  Future<AIResponseModel> sendRaw(
    List<MessageModel> messages, {
    required bool requestFinal,
    required BrainstormCategory category,
  }) async {
    final model = requestFinal ? _finalOutputModel : _conversationModel;

    final requestData = requestFinal
        ? {
            'model': model,
            'messages': messages.map((m) => m.toJson()).toList(),
            'temperature': 0.5,
            'max_tokens': 2000,
            'response_format': {'type': 'json_object'},
          }
        : {
            'model': model,
            'messages': messages.map((m) => m.toJson()).toList(),
            'temperature': 0.5,
            'max_tokens': 500,
          };

    final response = await _dio.post(
      '/chat/completions',
      data: requestData,
    );

    final content = _extractContent(response);

    return AIResponseModel.fromContent(
      content,
      isFinal: requestFinal,
      category: category,
    );
  }

  /// Extract the assistant's content from a Groq/OpenAI-format response.
  String _extractContent(Response response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException(
        'Unexpected response format: response data is not a JSON object.',
      );
    }

    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const ParseException(
        'Unexpected response format: choices missing or empty.',
      );
    }

    final firstChoice = choices[0];
    if (firstChoice is! Map<String, dynamic>) {
      throw const ParseException(
        'Unexpected response format: first choice is not an object.',
      );
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      throw const ParseException(
        'Unexpected response format: message missing.',
      );
    }

    final content = message['content'] as String?;
    if (content == null || content.isEmpty) {
      throw const ParseException(
        'Unexpected response format: content missing or empty.',
      );
    }

    return content;
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
