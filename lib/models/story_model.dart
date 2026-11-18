class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final bool isVideo;
  final String caption;
  final DateTime createdAt;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    this.isVideo = false,
    this.caption = '',
    required this.createdAt,
  });

  StoryModel copyWith({
    String? mediaUrl,
    String? caption,
    bool? isVideo,
  }) {
    return StoryModel(
      id: id,
      userId: userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isVideo: isVideo ?? this.isVideo,
      caption: caption ?? this.caption,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'mediaUrl': mediaUrl,
        'isVideo': isVideo,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        mediaUrl: json['mediaUrl'] as String? ?? '',
        isVideo: json['isVideo'] as bool? ?? false,
        caption: json['caption'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
