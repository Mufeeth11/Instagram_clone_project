class ChatMessageModel {
  final String id;
  final String threadUserId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.threadUserId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'threadUserId': threadUserId,
        'senderId': senderId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String? ?? '',
        threadUserId: json['threadUserId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
