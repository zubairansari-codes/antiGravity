/// Home screen view model — manages the brainstorm history list with rename support.
library;


import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/brainstorm.dart';
import 'providers.dart';

/// Async state for the home screen brainstorm list.
final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<Brainstorm>>(
  HomeViewModel.new,
);

class HomeViewModel extends AsyncNotifier<List<Brainstorm>> {
  @override
  Future<List<Brainstorm>> build() async {
    return _loadHistory();
  }

  Future<List<Brainstorm>> _loadHistory() async {
    final useCase = ref.read(getBrainstormHistoryUseCaseProvider);
    final result = await useCase();
    return result.fold(
      (failure) => throw failure,
      (brainstorms) => brainstorms,
    );
  }

  /// Refresh the brainstorm list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadHistory);
  }

  /// Delete a brainstorm and refresh the list.
  Future<void> deleteBrainstorm(String id) async {
    final useCase = ref.read(deleteBrainstormUseCaseProvider);
    final result = await useCase(id);
    result.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (_) async => await refresh(),
    );
  }

  /// Rename a brainstorm by ID and refresh the list.
  Future<void> renameBrainstorm(String id, String newTitle) async {
    final repo = ref.read(brainstormRepositoryProvider);
    final history = await repo.getBrainstormHistory();
    history.fold(
      (failure) => state = AsyncError(failure, StackTrace.current),
      (sessions) async {
        final session = sessions.firstWhere(
          (s) => s.id == id,
          orElse: () => Brainstorm(
            id: id,
            title: 'Unknown',
            messages: const [],
            createdAt: DateTime.now(),
          ),
        );
        final updated = session.copyWith(title: newTitle);
        final saveResult = await repo.saveBrainstorm(updated);
        saveResult.fold(
          (failure) => state = AsyncError(failure, StackTrace.current),
          (_) async => await refresh(),
        );
      },
    );
  }
}
