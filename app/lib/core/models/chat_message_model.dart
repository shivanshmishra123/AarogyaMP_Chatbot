/// AarogyaMP — ChatMessage Dart model (mirrors schemas.py ChatMessageOut — FROZEN)
/// Person C owns this file.

class ChatMessage {
  final String id;
  final String consultationId;
  final String senderRole; // patient | doctor
  final String messageType; // text | voice | image | document
  final String? text;
  final String? filePath;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.consultationId,
    required this.senderRole,
    required this.messageType,
    this.text,
    this.filePath,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    consultationId: json['consultation_id'],
    senderRole: json['sender_role'],
    messageType: json['message_type'],
    text: json['text'],
    filePath: json['file_path'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
