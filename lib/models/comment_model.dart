class CommentModel {
  final String id;
  final String targetId;
  final String targetType; // 'post' or 'reel'
  final String userId;
  final String text;
  final DateTime createdAt;
  final int likeCount;

  /// The comment this one replies to, or null for a top-level comment.
  final String? parentId;

  const CommentModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.likeCount = 0,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'targetType': targetType,
    'userId': userId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'likeCount': likeCount,
    'parentId': parentId,
  };

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'] as String? ?? '',
    targetId: json['targetId'] as String? ?? '',
    targetType: json['targetType'] as String? ?? 'post',
    userId: json['userId'] as String? ?? '',
    text: json['text'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    likeCount: json['likeCount'] as int? ?? 0,
    parentId: json['parentId'] as String?,
  );
}
