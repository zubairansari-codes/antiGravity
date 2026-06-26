/// Central Riverpod provider definitions — dependency injection root.
///
/// All providers live here so the presentation layer can
/// access services, repositories, and use cases via `ref.read()`.
library;


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../services/speech_service.dart';
import '../../data/datasources/brainstorm_local_ds.dart';
import '../../data/datasources/brainstorm_remote_ds.dart';
import '../../data/datasources/conversation_context_manager.dart';
import '../../data/models/brainstorm_model.dart';
import '../../data/repositories/brainstorm_repository_impl.dart';
import '../../domain/repositories/brainstorm_repository.dart';
import '../../domain/usecases/delete_brainstorm.dart';
import '../../domain/usecases/get_brainstorm_history.dart';
import '../../domain/usecases/send_message.dart';

// ── Infrastructure ────────────────────────────────────────────────

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(Connectivity());
});

// ── Speech ────────────────────────────────────────────────────────

final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechServiceImpl();
});

// ── Data Sources ──────────────────────────────────────────────────

final brainstormRemoteDsProvider =
    Provider<BrainstormRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider).client;
  return BrainstormRemoteDataSource(dio);
});

final brainstormLocalDsProvider =
    Provider<BrainstormLocalDataSource>((ref) {
  final box = Hive.box<BrainstormModel>('brainstorms');
  return BrainstormLocalDataSource(box);
});

final conversationContextManagerProvider =
    Provider<ConversationContextManager>((ref) {
  return ConversationContextManager(ref.watch(brainstormRemoteDsProvider));
});

// ── Repository ────────────────────────────────────────────────────

final brainstormRepositoryProvider =
    Provider<BrainstormRepository>((ref) {
  return BrainstormRepositoryImpl(
    ref.watch(brainstormRemoteDsProvider),
    ref.watch(brainstormLocalDsProvider),
    ref.watch(conversationContextManagerProvider),
  );
});

// ── Use Cases ─────────────────────────────────────────────────────

final sendMessageUseCaseProvider =
    Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(brainstormRepositoryProvider));
});

final getBrainstormHistoryUseCaseProvider =
    Provider<GetBrainstormHistoryUseCase>((ref) {
  return GetBrainstormHistoryUseCase(
      ref.watch(brainstormRepositoryProvider));
});

final deleteBrainstormUseCaseProvider =
    Provider<DeleteBrainstormUseCase>((ref) {
  return DeleteBrainstormUseCase(
      ref.watch(brainstormRepositoryProvider));
});
