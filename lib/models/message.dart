class Message {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? attachmentUri; // Optional attachment label/uri

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachmentUri,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp,
        'attachmentUri': attachmentUri,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        timestamp: json['timestamp'] as String? ?? '',
        attachmentUri: json['attachmentUri'] as String?,
      );
}
