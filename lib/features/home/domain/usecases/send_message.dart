/// Use case: Send a message to the AI brainstorming agent.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_response.dart';
import '../entities/artefact_type.dart';
import '../entities/brainstorm_category.dart';
import '../entities/chat_message.dart';
import '../entities/conversation_artefact.dart';
import '../entities/conversation_mode.dart';
import '../repositories/brainstorm_repository.dart';

class SendMessageUseCase {

  const SendMessageUseCase(this.repository);
  final BrainstormRepository repository;

  Future<Either<Failure, AIResponse>> call(SendMessageParams params) {
    // Count exchanges (pairs of user + assistant messages)
    final exchangeCount = params.messages.length ~/ 2;
    if (exchangeCount >= AppConstants.maxExchangesBeforeWrap) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Maximum conversation length reached. Please wrap up or start a new session.',
          ),
        ),
      );
    }

    return repository.sendMessage(
      params.messages,
      requestFinalOutput: params.requestFinalOutput,
      category: params.category,
      mode: params.mode,
      requestedArtefact: params.requestedArtefact,
      previousArtefacts: params.previousArtefacts,
      contextSummary: params.contextSummary,
    );
  }
}

class SendMessageParams {

  const SendMessageParams({
    required this.messages,
    this.requestFinalOutput = false,
    required this.category,
    this.mode = ConversationMode.riff,
    this.requestedArtefact,
    this.previousArtefacts = const [],
    this.contextSummary,
  });
  final List<ChatMessage> messages;
  final bool requestFinalOutput;
  final BrainstormCategory category;
  final ConversationMode mode;
  final ArtefactType? requestedArtefact;

  /// Artefacts created earlier in this session — sent as prompt context.
  final List<ConversationArtefact> previousArtefacts;

  /// Optional short summary of the conversation so far.
  final String? contextSummary;
}
