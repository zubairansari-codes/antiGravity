import 'package:antigravity/core/errors/failures.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:antigravity/features/home/domain/entities/chat_message.dart';
import 'package:antigravity/features/home/domain/repositories/brainstorm_repository.dart';
import 'package:antigravity/features/home/domain/usecases/get_brainstorm_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBrainstormRepository extends Mock implements BrainstormRepository {}

void main() {
  late GetBrainstormHistoryUseCase useCase;
  late MockBrainstormRepository mockRepository;

  final testBrainstorms = [
    Brainstorm(
      id: 'id-1',
      title: 'First',
      category: BrainstormCategory.general,
      messages: [ChatMessage.user('Hello')],
      createdAt: DateTime(2024, 1, 1),
    ),
    Brainstorm(
      id: 'id-2',
      title: 'Second',
      category: BrainstormCategory.coding,
      messages: [],
      createdAt: DateTime(2024, 2, 1),
    ),
  ];

  setUp(() {
    mockRepository = MockBrainstormRepository();
    useCase = GetBrainstormHistoryUseCase(mockRepository);
  });

  group('GetBrainstormHistoryUseCase', () {
    test('returns Right with list of brainstorms', () async {
      when(() => mockRepository.getBrainstormHistory())
          .thenAnswer((_) async => Right(testBrainstorms));

      final result = await useCase();

      expect(result.isRight(), true);
      final list = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(list.length, 2);
      expect(list.first.id, 'id-1');
      expect(list.last.category, BrainstormCategory.coding);
    });

    test('returns Left CacheFailure on repository error', () async {
      when(() => mockRepository.getBrainstormHistory())
          .thenAnswer((_) async => const Left(CacheFailure()));

      final result = await useCase();

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<CacheFailure>());
    });

    test('returns Left ServerFailure on network error', () async {
      when(() => mockRepository.getBrainstormHistory())
          .thenAnswer((_) async => const Left(ServerFailure('Network error')));

      final result = await useCase();

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Network error');
    });

    test('returns empty list when no brainstorms exist', () async {
      when(() => mockRepository.getBrainstormHistory())
          .thenAnswer((_) async => const Right([]));

      final result = await useCase();

      expect(result.isRight(), true);
      final list = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(list, isEmpty);
    });
  });
}
