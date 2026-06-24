import 'package:antigravity/features/home/data/datasources/brainstorm_local_ds.dart';
import 'package:antigravity/features/home/data/datasources/brainstorm_local_ds_interface.dart';
import 'package:antigravity/features/home/data/models/brainstorm_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';

class MockHiveBox extends Mock implements Box<BrainstormModel> {}

class FakeBrainstormModel extends Fake implements BrainstormModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBrainstormModel());
  });

  late IBrainstormLocalDataSource dataSource;
  late MockHiveBox mockBox;

  final testModel = BrainstormModel(
    id: 'test-id',
    title: 'Test Brainstorm',
    categoryId: 'general',
    messagesJson: [
      {'id': '1', 'content': 'Hello', 'role': 'user', 'timestamp': '2024-01-01T00:00:00Z'},
    ],
    createdAt: DateTime(2024, 1, 1),
  );

  final testModel2 = BrainstormModel(
    id: 'test-id-2',
    title: 'Older Brainstorm',
    categoryId: 'coding',
    messagesJson: [],
    createdAt: DateTime(2023, 12, 1),
  );

  setUp(() {
    mockBox = MockHiveBox();
    dataSource = BrainstormLocalDataSource(mockBox);
  });

  group('getAll', () {
    test('returns empty list when box is empty', () async {
      when(() => mockBox.values).thenReturn([]);

      final result = await dataSource.getAll();
      expect(result, isEmpty);
    });

    test('returns all brainstorms sorted by most recent first', () async {
      when(() => mockBox.values).thenReturn([testModel2, testModel]);

      final result = await dataSource.getAll();
      expect(result.length, 2);
      expect(result.first.id, 'test-id'); // more recent
      expect(result.last.id, 'test-id-2'); // older
    });

    test('returns single item when box has one entry', () async {
      when(() => mockBox.values).thenReturn([testModel]);

      final result = await dataSource.getAll();
      expect(result.length, 1);
      expect(result.first.title, 'Test Brainstorm');
    });
  });

  group('save', () {
    test('saves model with put', () async {
      when(() => mockBox.put('test-id', testModel)).thenAnswer((_) async {});

      await dataSource.save(testModel);
      verify(() => mockBox.put('test-id', testModel)).called(1);
    });

    test('propagates Hive errors', () async {
      when(() => mockBox.put('test-id', testModel)).thenThrow(Exception('Hive error'));

      expect(() => dataSource.save(testModel), throwsException);
    });
  });

  group('delete', () {
    test('deletes by id', () async {
      when(() => mockBox.delete('test-id')).thenAnswer((_) async {});

      await dataSource.delete('test-id');
      verify(() => mockBox.delete('test-id')).called(1);
    });

    test('propagates delete errors', () async {
      when(() => mockBox.delete('test-id')).thenThrow(Exception('Delete failed'));

      expect(() => dataSource.delete('test-id'), throwsException);
    });
  });

  group('exists', () {
    test('returns true when key exists', () {
      when(() => mockBox.containsKey('test-id')).thenReturn(true);

      expect(dataSource.exists('test-id'), true);
    });

    test('returns false when key does not exist', () {
      when(() => mockBox.containsKey('missing')).thenReturn(false);

      expect(dataSource.exists('missing'), false);
    });
  });

  group('implements interface', () {
    test('BrainstormLocalDataSource implements IBrainstormLocalDataSource', () {
      expect(dataSource, isA<IBrainstormLocalDataSource>());
    });
  });
}
