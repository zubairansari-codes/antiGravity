/// Brainstorm model — Hive-storable representation of a session.
///
/// Manually handles Hive serialization (no hive_generator needed
/// since we avoid code generation complexity for storage models).
library;

import 'package:hive/hive.dart';

import '../../domain/entities/brainstorm.dart';
import '../../domain/entities/brainstorm_category.dart';
import '../../domain/entities/brainstorm_result.dart';
import '../../domain/entities/chat_message.dart';

class BrainstormModel {

  const BrainstormModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.messagesJson,
    this.resultJson,
    required this.createdAt,
  });

  /// From domain entity → storage model.
  factory BrainstormModel.fromEntity(Brainstorm b) => BrainstormModel(
        id: b.id,
        title: b.title,
        categoryId: b.category.id,
        messagesJson: b.messages
            .map((m) => {
                  'id': m.id,
                  'content': m.content,
                  'role': m.role == MessageRole.user ? 'user' : 'assistant',
                  'timestamp': m.timestamp.toIso8601String(),
                })
            .toList(),
        resultJson: b.result != null
            ? {
                'refinedIdea': b.result!.refinedIdea,
                'readyPrompt': b.result!.readyPrompt,
                'actionPlan': b.result!.actionPlan
                    .map((s) => {
                          'stepNumber': s.stepNumber,
                          'title': s.title,
                          'description': s.description,
                        })
                    .toList(),
                'alternatives': b.result!.alternatives,
                'riskiestAssumption': b.result!.riskiestAssumption,
              }
            : null,
        createdAt: b.createdAt,
      );

  /// Restore from a Hive Map.
  factory BrainstormModel.fromMap(Map<dynamic, dynamic> map) {
    return BrainstormModel(
      id: map['id'] as String,
      title: map['title'] as String,
      categoryId: map['categoryId'] as String? ?? 'general',
      messagesJson: (map['messages'] as List)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList(),
      resultJson: map['result'] != null
          ? Map<String, dynamic>.from(map['result'] as Map)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
  final String id;
  final String title;
  final String categoryId;
  final List<Map<String, dynamic>> messagesJson;
  final Map<String, dynamic>? resultJson;
  final DateTime createdAt;

  /// From storage → domain entity.
  Brainstorm toEntity() => Brainstorm(
        id: id,
        title: title,
        category: BrainstormCategory.fromId(categoryId),
        messages: messagesJson
            .map((m) => ChatMessage(
                  id: m['id'] as String,
                  content: m['content'] as String,
                  role: m['role'] == 'user'
                      ? MessageRole.user
                      : MessageRole.assistant,
                  timestamp: DateTime.parse(m['timestamp'] as String),
                ))
            .toList(),
        result: resultJson != null ? _parseResult(resultJson!) : null,
        createdAt: createdAt,
      );

  /// Convert to a Map for Hive storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'messages': messagesJson,
        'result': resultJson,
        'createdAt': createdAt.toIso8601String(),
      };

  static BrainstormResult _parseResult(Map<String, dynamic> json) {
    return BrainstormResult(
      refinedIdea: json['refinedIdea'] as String? ?? '',
      readyPrompt: json['readyPrompt'] as String? ?? '',
      actionPlan: (json['actionPlan'] as List?)
              ?.map((s) => ActionStep(
                    stepNumber: (s as Map)['stepNumber'] as int? ?? 0,
                    title: s['title'] as String? ?? '',
                    description: s['description'] as String? ?? '',
                  ))
              .toList() ??
          [],
      alternatives: (json['alternatives'] as List?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      riskiestAssumption: json['riskiestAssumption'] as String? ?? '',
    );
  }
}

/// Hive TypeAdapter for BrainstormModel — stores as a Map.
class BrainstormModelAdapter extends TypeAdapter<BrainstormModel> {
  @override
  final int typeId = 0;

  @override
  BrainstormModel read(BinaryReader reader) {
    final map = reader.readMap();
    return BrainstormModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, BrainstormModel obj) {
    writer.writeMap(obj.toMap());
  }
}
