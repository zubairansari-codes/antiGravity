/// Concrete repository — wires remote (OpenAI) and local (Hive) data sources.
///
/// Every method returns Either<Failure, T>.  
/// Catches DioException → ServerFailure, generic → CacheFailure.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/brainstorm_repository.dart';
import '../datasources/brainstorm_local_ds.dart';
import '../datasources/brainstorm_remote_ds.dart';
import '../models/brainstorm_model.dart';
import '../models/message_model.dart';

class BrainstormRepositoryImpl implements BrainstormRepository {
  final BrainstormRemoteDataSource _remote;
  final BrainstormLocalDataSource _local;

  const BrainstormRepositoryImpl(this._remote, this._local);

  @override
  Future<Either<Failure, AIResponse>> sendMessage(
    List<ChatMessage> messages, {
    bool requestFinalOutput = false,
    required BrainstormCategory category,
  }) async {
    try {
      final messageModels =
          messages.map(MessageModel.fromEntity).toList();
      final response = await _remote.sendMessage(
        messageModels,
        requestFinal: requestFinalOutput,
        category: category,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      debugPrint('[AG-REPO] DioException: status=$statusCode, type=${e.type}, msg=${e.message}');
      debugPrint('[AG-REPO] Response body: $body');
      return Left(ServerFailure(
        'API error ($statusCode): ${body ?? e.message ?? 'Unknown error'}',
      ));
    } catch (e) {
      debugPrint('[AG-REPO] Generic error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Brainstorm>>> getBrainstormHistory() async {
    try {
      final models = await _local.getAll();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(const CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> saveBrainstorm(Brainstorm brainstorm) async {
    try {
      await _local.save(BrainstormModel.fromEntity(brainstorm));
      return const Right(unit);
    } catch (e) {
      return Left(const CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteBrainstorm(String id) async {
    try {
      await _local.delete(id);
      return const Right(unit);
    } catch (e) {
      return Left(const CacheFailure());
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
      return Left(const CacheFailure());
    }
  }
}
