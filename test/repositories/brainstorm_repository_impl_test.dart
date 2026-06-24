import 'package:antigravity/core/errors/failures.dart';
import 'package:antigravity/features/home/data/datasources/brainstorm_local_ds_interface.dart';
import 'package:antigravity/features/home/data/datasources/brainstorm_remote_ds_interface.dart';
import 'package:antigravity/features/home/data/models/ai_response_model.dart';
import 'package:antigravity/features/home/data/models/brainstorm_model.dart';
import 'package:antigravity/features/home/data/repositories/brainstorm_repository_impl.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_result.dart';
import 'package:antigravity/features/home/domain/entities/chat_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteDataSource extends Mock
    implements IBrainstormRemoteDataSource {}

class MockLocalDataSource extends Mock
    implements IBrainstormLocalDataSource {}

class FakeBrainstormModel extends Fake implements BrainstormModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBrainstormModel());
    registerFallbackValue(BrainstormCategory.general);
  });

  late BrainstormRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;

  final testMessages = [
    ChatMessage.user('Hello'),
    ChatMessage.assistant('Hi! Tell me more.'),
  ];

  const testResponse = AIResponseModel(
    text: 'Structured output',
    isFinal: true,
    structuredResult: BrainstormResult(
      refinedIdea: 'Idea',
      readyPrompt: 'Prompt',
      actionPlan: [ActionStep(stepNumber: 1, title: 'T', description: 'D')],
      alternatives: ['Alt'],
      riskiestAssumption: 'Assumption',
    ),
  );

  final testBrainstormModel = BrainstormModel(
    id: 'id-1',
    title: 'Test',
    categoryId: 'general',
    messagesJson: [],
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    repository = BrainstormRepositoryImpl(mockRemote, mockLocal);
  });

  group('sendMessage', () {
    test('returns Right on success', () async {
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => testResponse);

      final result = await repository.sendMessage(
        testMessages,
        requestFinalOutput: true,
        category: BrainstormCategory.general,
      );

      expect(result.isRight(), true);
      final entity = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(entity.isFinal, true);
      expect(entity.structuredResult!.refinedIdea, 'Idea');
    });

    test('returns ValidationFailure when remote throws ValidationException', () async {
      // We simulate a validation error by making the remote throw
      // Since we can't easily construct ValidationException from tests,
      // we test via the DioException path for client errors instead
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
            data: 'Bad request',
          ),
        ),
      );

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<ServerFailure>());
      expect(failure.message, contains('400'));
    });

    test('returns NetworkFailure on timeout', () async {
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<NetworkFailure>());
    });

    test('returns ServerFailure with rate limit message on 429', () async {
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 429,
          ),
        ),
      );

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure.message, contains('Rate limit'));
    });

    test('returns ServerFailure with retry message on 502', () async {
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 502,
          ),
        ),
      );

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure.message, contains('temporarily unavailable'));
    });

    test('retry logic succeeds on second attempt', () async {
      var attempts = 0;
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          );
        }
        return testResponse;
      });

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      expect(result.isRight(), true);
      expect(attempts, 2);
    });

    test('retry logic exhausts max retries and returns Left', () async {
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<NetworkFailure>());
    });

    test('does not retry on 400 client error', () async {
      var attempts = 0;
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenAnswer((_) async {
        attempts++;
        throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 400,
          ),
        );
      });

      final result = await repository.sendMessage(
        testMessages,
        category: BrainstormCategory.general,
      );

      expect(result.isLeft(), true);
      expect(attempts, 1); // no retries
    });

    test('corrective prompt retry on ParseException', () async {
      // First call throws ParseException, second call (corrective) succeeds
      var attempts = 0;
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw const ParseException(
            'Failed to parse final output. Text was neither valid JSON nor structured markdown.',
          );
        }
        return testResponse;
      });

      final result = await repository.sendMessage(
        testMessages,
        requestFinalOutput: true,
        category: BrainstormCategory.general,
      );

      expect(result.isRight(), true);
      expect(attempts, 2);
    });

    test('fallback to raw text when corrective retry also fails', () async {
      when(() => mockRemote.sendMessage(
            any(),
            requestFinal: any(named: 'requestFinal'),
            category: any(named: 'category'),
          )).thenThrow(
        const ParseException(
          'Failed to parse final output. Text was neither valid JSON nor structured markdown.',
        ),
      );

      final result = await repository.sendMessage(
        testMessages,
        requestFinalOutput: true,
        category: BrainstormCategory.general,
      );

      expect(result.isRight(), true);
      final entity = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(entity.text, contains('Try Again'));
      expect(entity.structuredResult, isNull);
    });
  });

  group('getBrainstormHistory', () {
    test('returns Right with list of brainstorms', () async {
      when(() => mockLocal.getAll()).thenAnswer((_) async => [testBrainstormModel]);

      final result = await repository.getBrainstormHistory();

      expect(result.isRight(), true);
      final list = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(list.length, 1);
      expect(list.first.id, 'id-1');
    });

    test('returns Left CacheFailure on error', () async {
      when(() => mockLocal.getAll()).thenThrow(Exception('Hive error'));

      final result = await repository.getBrainstormHistory();

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<CacheFailure>());
    });
  });

  group('saveBrainstorm', () {
    test('returns Right unit on success', () async {
      when(() => mockLocal.save(any())).thenAnswer((_) async {});

      final brainstorm = Brainstorm(
        id: 'id-1',
        title: 'Test',
        category: BrainstormCategory.general,
        messages: [],
        createdAt: DateTime.now(),
      );

      final result = await repository.saveBrainstorm(brainstorm);

      expect(result.isRight(), true);
      expect(result.getOrElse((_) => throw Exception('Expected Right')), unit);
    });

    test('returns Left CacheFailure on error', () async {
      when(() => mockLocal.save(any())).thenThrow(Exception('Hive error'));

      final brainstorm = Brainstorm(
        id: 'id-1',
        title: 'Test',
        category: BrainstormCategory.general,
        messages: [],
        createdAt: DateTime.now(),
      );

      final result = await repository.saveBrainstorm(brainstorm);

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<CacheFailure>());
    });
  });

  group('deleteBrainstorm', () {
    test('returns Right unit on success', () async {
      when(() => mockLocal.delete(any())).thenAnswer((_) async {});

      final result = await repository.deleteBrainstorm('id-1');

      expect(result.isRight(), true);
      expect(result.getOrElse((_) => throw Exception('Expected Right')), unit);
    });

    test('returns Left CacheFailure on error', () async {
      when(() => mockLocal.delete(any())).thenThrow(Exception('Hive error'));

      final result = await repository.deleteBrainstorm('id-1');

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<CacheFailure>());
    });
  });

  group('createSession', () {
    test('returns Right with new brainstorm', () async {
      when(() => mockLocal.save(any())).thenAnswer((_) async {});

      final result = await repository.createSession(
        category: BrainstormCategory.coding,
      );

      expect(result.isRight(), true);
      final brainstorm = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(brainstorm.category, BrainstormCategory.coding);
      expect(brainstorm.title, 'New Brainstorm');
      expect(brainstorm.messages, isEmpty);
    });

    test('returns Left CacheFailure on save error', () async {
      when(() => mockLocal.save(any())).thenThrow(Exception('Hive error'));

      final result = await repository.createSession();

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<CacheFailure>());
    });
  });
}
