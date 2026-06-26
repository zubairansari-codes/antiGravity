/// Concrete repository — wires remote (OpenAI) and local (Hive) data sources.
///
/// Every method returns Either<Failure, T>.
/// Catches DioException → ServerFailure, ValidationException → ValidationFailure,
/// generic → CacheFailure.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/entities/artefact_type.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_mode.dart';
import '../../domain/repositories/brainstorm_repository.dart';
import '../datasources/brainstorm_local_ds_interface.dart';
import '../datasources/brainstorm_remote_ds_interface.dart';
import '../datasources/brainstorm_remote_ds.dart';
import '../models/ai_response_model.dart';
import '../models/brainstorm_model.dart';
import '../models/message_model.dart';

class BrainstormRepositoryImpl implements BrainstormRepository {

  const BrainstormRepositoryImpl(this._remote, this._local);
  final IBrainstormRemoteDataSource _remote;
  final IBrainstormLocalDataSource _local;

  @override
  Future<Either<Failure, AIResponse>> sendMessage(
    List<ChatMessage> messages, {
    bool requestFinalOutput = false,
    required BrainstormCategory category,
    ConversationMode mode = ConversationMode.riff,
    ArtefactType? requestedArtefact,
  }) async {
    try {
      final messageModels = messages.map(MessageModel.fromEntity).toList();
      final response = await _sendWithRetry(
        messageModels,
        requestFinal: requestFinalOutput,
        category: category,
        mode: mode,
        requestedArtefact: requestedArtefact,
      );
      return Right(response.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      debugPrint('[AG-REPO] DioException: status=$statusCode, type=${e.type}, msg=${e.message}');
      debugPrint('[AG-REPO] Response body: $body');

      // Map specific error types to appropriate failures
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Left(NetworkFailure());
      }

      if (statusCode != null) {
        if (statusCode == 429) {
          return Left(ServerFailure('Rate limit exceeded ($statusCode). Please wait a moment and try again.'));
        }
        if (statusCode == 502 || statusCode == 503) {
          return Left(ServerFailure('AI service temporarily unavailable ($statusCode). Please try again.'));
        }
        if (statusCode >= 400 && statusCode < 500) {
          return Left(ServerFailure('Client error ($statusCode): ${body ?? e.message ?? 'Invalid request'}'));
        }
      }

      return Left(ServerFailure(
        'API error ($statusCode): ${body ?? e.message ?? 'Unknown error'}',
      ));
    } on ParseException catch (e) {
      // JSON parsing failed — try once with a corrective prompt
      debugPrint('[AG-REPO] ParseException: $e');
      try {
        final messageModels = messages.map(MessageModel.fromEntity).toList();
        final correctiveResponse = await _sendWithRetry(
          [
            ...messageModels,
            const MessageModel(
              role: 'system',
              content: 'Your previous response was not valid JSON. Please output ONLY a valid JSON object matching the schema. No markdown, no explanation, just raw JSON.',
            ),
          ],
          requestFinal: requestFinalOutput,
          category: category,
          mode: mode,
          requestedArtefact: requestedArtefact,
        );
        return Right(correctiveResponse.toEntity());
      } catch (e) {
        debugPrint('[AG-REPO] Corrective retry also failed: $e');
        // Return raw text with a flag that the VM can use to show "Try Again"
        return Right(
          AIResponse(
            text: 'We received a response but could not parse it. Tap "Try Again" to retry.',
            isFinal: requestFinalOutput,
            structuredResult: null,
            artefacts: const [],
          ),
        );
      }
    } catch (e) {
      debugPrint('[AG-REPO] Generic error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Send with exponential backoff retry (3 retries).
  /// Only retries on transient network errors (timeout, 502, 503, 429).
  Future<AIResponseModel> _sendWithRetry(
    List<MessageModel> messages, {
    required bool requestFinal,
    required BrainstormCategory category,
    ConversationMode mode = ConversationMode.riff,
    ArtefactType? requestedArtefact,
  }) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _remote.sendMessage(
          messages,
          requestFinal: requestFinal,
          category: category,
          mode: mode,
          requestedArtefact: requestedArtefact,
        );
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        final isTransient = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            statusCode == 429 ||
            statusCode == 502 ||
            statusCode == 503;

        if (!isTransient || attempt == maxRetries) {
          rethrow;
        }

        // Exponential backoff: 1s, 2s, 4s
        final delay = baseDelay * (1 << attempt);
        debugPrint('[AG-REPO] Retry $attempt after ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }

    // Should never reach here, but satisfies the analyzer.
    throw StateError('Retry loop exhausted without success or exception');
  }

  @override
  Future<Either<Failure, List<Brainstorm>>> getBrainstormHistory() async {
    try {
      final models = await _local.getAll();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveBrainstorm(Brainstorm brainstorm) async {
    try {
      await _local.save(BrainstormModel.fromEntity(brainstorm));
      return const Right(unit);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBrainstorm(String id) async {
    try {
      await _local.delete(id);
      return const Right(unit);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Brainstorm>> createSession({BrainstormCategory category = BrainstormCategory.general}) async {
    try {
      final brainstorm = Brainstorm(
        id: const Uuid().v4(),
        title: 'New Brainstorm',
        category: category,
        messages: [],
        createdAt: DateTime.now(),
      );
      await _local.save(BrainstormModel.fromEntity(brainstorm));
      return Right(brainstorm);
    } catch (e) {
      return const Left(CacheFailure());
    }
  }
}
