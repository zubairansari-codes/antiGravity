import 'package:antigravity/features/home/data/datasources/brainstorm_remote_ds_interface.dart';
import 'package:antigravity/features/home/data/datasources/conversation_context_manager.dart';
import 'package:antigravity/features/home/data/models/ai_response_model.dart';
import 'package:antigravity/features/home/data/models/message_model.dart';
import 'package:antigravity/features/home/domain/entities/brainstorm_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteDataSource extends Mock
    implements IBrainstormRemoteDataSource {}

void main() {
  late ConversationContextManager manager;
  late MockRemoteDataSource mockRemote;

  setUpAll(() {
    registerFallbackValue(BrainstormCategory.general);
  });

  setUp(() {
    mockRemote = MockRemoteDataSource();
    manager = ConversationContextManager(mockRemote);
  });

  group('buildContext', () {
    test('returns verbatim messages and no summary for short conversations',
        () async {
      final messages = [
        const MessageModel(role: 'user', content: 'Hello'),
        const MessageModel(role: 'assistant', content: 'Hi!'),
      ];

      final result = await manager.buildContext(messages);

      expect(result.messages, messages);
      expect(result.summary, isNull);
      verifyNever(() => mockRemote.sendRaw(any(), requestFinal: any(named: 'requestFinal'), category: any(named: 'category')));
    });

    test('summarises older turns when conversation exceeds threshold', () async {
      final messages = [
        for (var i = 0; i < 16; i++)
          MessageModel(
            role: i % 2 == 0 ? 'user' : 'assistant',
            content: 'Message $i',
          ),
      ];

      when(() => mockRemote.sendRaw(any(), requestFinal: any(named: 'requestFinal'), category: any(named: 'category')))
          .thenAnswer((_) async => const AIResponseModel(
                text: 'Earlier we discussed testing and summarisation.',
                isFinal: false,
              ));

      final result = await manager.buildContext(messages);

      expect(result.summary, 'Earlier we discussed testing and summarisation.');
      expect(result.messages.length, lessThan(messages.length));
      expect(
        result.messages.any((m) => m.role == 'system'),
        isTrue,
      );
      verify(() => mockRemote.sendRaw(any(), requestFinal: false, category: any(named: 'category'))).called(1);
    });

    test('falls back to keyword summary when remote summary fails', () async {
      final messages = [
        for (var i = 0; i < 16; i++)
          MessageModel(
            role: i % 2 == 0 ? 'user' : 'assistant',
            content: 'Message $i',
          ),
      ];

      when(() => mockRemote.sendRaw(any(), requestFinal: any(named: 'requestFinal'), category: any(named: 'category')))
          .thenThrow(Exception('API error'));

      final result = await manager.buildContext(messages);

      expect(result.summary, isNotNull);
      expect(result.summary, contains('Key topics:'));
    });
  });
}
