/// Repository interface — the contract between domain and data layers.
///
/// Returns `Either<Failure, T>` for every operation so callers
/// MUST handle both success and error cases.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ai_response.dart';
import '../entities/artefact_type.dart';
import '../entities/brainstorm.dart';
import '../entities/brainstorm_category.dart';
import '../entities/chat_message.dart';
import '../entities/conversation_artefact.dart';
import '../entities/conversation_mode.dart';

abstract class BrainstormRepository {
  /// Send conversation history to Groq and get an AI response.
  /// Set [requestFinalOutput] to true to trigger the structured ending phase.
  Future<Either<Failure, AIResponse>> sendMessage(
    List<ChatMessage> messages, {
    bool requestFinalOutput = false,
    required BrainstormCategory category,
    ConversationMode mode = ConversationMode.riff,
    ArtefactType? requestedArtefact,
    List<ConversationArtefact> previousArtefacts = const [],
    String? contextSummary,
  });

  /// Load all saved brainstorms from local cache.
  Future<Either<Failure, List<Brainstorm>>> getBrainstormHistory();

  /// Persist a brainstorm session to local cache.
  Future<Either<Failure, Unit>> saveBrainstorm(Brainstorm brainstorm);

  /// Delete a brainstorm by ID.
  Future<Either<Failure, Unit>> deleteBrainstorm(String id);

  /// Create a new empty brainstorm session.
  Future<Either<Failure, Brainstorm>> createSession({BrainstormCategory category = BrainstormCategory.general});
}
