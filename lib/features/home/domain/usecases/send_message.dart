/// Use case: Send a message to the AI brainstorming agent.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ai_response.dart';
import '../entities/brainstorm_category.dart';
import '../entities/chat_message.dart';
import '../repositories/brainstorm_repository.dart';

class SendMessageUseCase {
  final BrainstormRepository repository;

  const SendMessageUseCase(this.repository);

  Future<Either<Failure, AIResponse>> call(SendMessageParams params) {
    return repository.sendMessage(
      params.messages,
      requestFinalOutput: params.requestFinalOutput,
      category: params.category,
    );
  }
}

class SendMessageParams {
  final List<ChatMessage> messages;
  final bool requestFinalOutput;
  final BrainstormCategory category;

  const SendMessageParams({
    required this.messages,
    this.requestFinalOutput = false,
    required this.category,
  });
}
