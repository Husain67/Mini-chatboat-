import 'message.dart';

class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;

  ChatSession({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Chat',
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
