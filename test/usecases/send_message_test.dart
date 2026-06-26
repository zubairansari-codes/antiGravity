import 'package:antigravity/core/errors/failures.dart';
import 'package:antigravity/features/home/domain/entities/ai_response.dart';
import 'package:antigravity/features/home/domain/entities/artefact_type.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:antigravity/features/home/domain/entities/chat_message.dart';
import 'package:antigravity/features/home/domain/entities/conversation_mode.dart';
import 'package:antigravity/features/home/domain/repositories/brainstorm_repository.dart';
import 'package:antigravity/features/home/domain/usecases/send_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBrainstormRepository extends Mock implements BrainstormRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(BrainstormCategory.general);
    registerFallbackValue(ConversationMode.riff);
    registerFallbackValue(ArtefactType.actionPlan);
  });

  late SendMessageUseCase useCase;
  late MockBrainstormRepository mockRepository;

  setUp(() {
    mockRepository = MockBrainstormRepository();
    useCase = SendMessageUseCase(mockRepository);
  });

  group('SendMessageUseCase', () {
    test('returns Right on success', () async {
      const response = AIResponse(
        text: 'Hello!',
        isFinal: false,
      );

      when(() => mockRepository.sendMessage(
            any(),
            requestFinalOutput: any(named: 'requestFinalOutput'),
            category: any(named: 'category'),
            mode: any(named: 'mode'),
            requestedArtefact: any(named: 'requestedArtefact'),
          )).thenAnswer((_) async => const Right(response));

      final result = await useCase(
        SendMessageParams(
          messages: [
            ChatMessage.user('Hello'),
            ChatMessage.assistant('Hi!'),
          ],
          category: BrainstormCategory.general,
        ),
      );

      expect(result.isRight(), true);
      final entity = result.getOrElse((_) => throw Exception('Expected Right'));
      expect(entity.text, 'Hello!');
    });

    test('returns ValidationFailure when max exchanges exceeded', () async {
      // Create 20 messages = 10 exchanges, which is the limit
      final messages = <ChatMessage>[];
      for (int i = 0; i < 20; i++) {
        messages.add(
          i % 2 == 0
              ? ChatMessage.user('Message $i')
              : ChatMessage.assistant('Response $i'),
        );
      }

      final result = await useCase(
        SendMessageParams(
          messages: messages,
          category: BrainstormCategory.general,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Maximum conversation length'));

      // Verify repository was never called
      verifyNever(() => mockRepository.sendMessage(
            any(),
            requestFinalOutput: any(named: 'requestFinalOutput'),
            category: any(named: 'category'),
            mode: any(named: 'mode'),
            requestedArtefact: any(named: 'requestedArtefact'),
          ));
    });

    test('returns ValidationFailure when messages exceed limit by one', () async {
      final messages = <ChatMessage>[];
      for (int i = 0; i < 21; i++) {
        messages.add(
          i % 2 == 0
              ? ChatMessage.user('Message $i')
              : ChatMessage.assistant('Response $i'),
        );
      }

      final result = await useCase(
        SendMessageParams(
          messages: messages,
          category: BrainstormCategory.general,
        ),
      );

      expect(result.isLeft(), true);
    });

    test('allows exactly 9 exchanges (18 messages)', () async {
      const response = AIResponse(text: 'OK', isFinal: false);

      final messages = <ChatMessage>[];
      for (int i = 0; i < 18; i++) {
        messages.add(
          i % 2 == 0
              ? ChatMessage.user('Message $i')
              : ChatMessage.assistant('Response $i'),
        );
      }

      when(() => mockRepository.sendMessage(
            any(),
            requestFinalOutput: any(named: 'requestFinalOutput'),
            category: any(named: 'category'),
            mode: any(named: 'mode'),
            requestedArtefact: any(named: 'requestedArtefact'),
          )).thenAnswer((_) async => const Right(response));

      final result = await useCase(
        SendMessageParams(
          messages: messages,
          category: BrainstormCategory.general,
        ),
      );

      expect(result.isRight(), true);
    });

    test('passes requestFinalOutput to repository', () async {
      const response = AIResponse(text: 'Final', isFinal: true);

      when(() => mockRepository.sendMessage(
            any(),
            requestFinalOutput: any(named: 'requestFinalOutput'),
            category: any(named: 'category'),
            mode: any(named: 'mode'),
            requestedArtefact: any(named: 'requestedArtefact'),
          )).thenAnswer((_) async => const Right(response));

      final result = await useCase(
        SendMessageParams(
          messages: [ChatMessage.user('Wrap it up')],
          requestFinalOutput: true,
          category: BrainstormCategory.coding,
        ),
      );

      expect(result.isRight(), true);

      final captured = verify(() => mockRepository.sendMessage(
            any(),
            requestFinalOutput: captureAny(named: 'requestFinalOutput'),
            category: captureAny(named: 'category'),
            mode: captureAny(named: 'mode'),
            requestedArtefact: captureAny(named: 'requestedArtefact'),
          )).captured;

      expect(captured[0], true); // requestFinalOutput
      expect(captured[1], BrainstormCategory.coding); // category
      expect(captured[2], ConversationMode.riff); // mode default
      expect(captured[3], isNull); // requestedArtefact default
    });

    test('propagates repository failures', () async {
      when(() => mockRepository.sendMessage(
            any(),
            requestFinalOutput: any(named: 'requestFinalOutput'),
            category: any(named: 'category'),
          )).thenAnswer((_) async => const Left(ServerFailure('API down')));

      final result = await useCase(
        SendMessageParams(
          messages: [ChatMessage.user('Hello')],
          category: BrainstormCategory.general,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.fold((l) => l, (_) => throw Exception('Expected Left'));
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'API down');
    });
  });
}
