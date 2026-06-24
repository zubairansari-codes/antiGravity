/// Message DTO — converts between domain ChatMessage and OpenAI API format.
library;

import '../../domain/entities/chat_message.dart';

class MessageModel {
  final String role;
  final String content;

  const MessageModel({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        role: json['role'] as String,
        content: json['content'] as String,
      );

  factory MessageModel.fromEntity(ChatMessage msg) => MessageModel(
        role: msg.role == MessageRole.user ? 'user' : 'assistant',
        content: msg.content,
      );

  ChatMessage toEntity() => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        content: content,
        role: role == 'user' ? MessageRole.user : MessageRole.assistant,
        timestamp: DateTime.now(),
      );
}
