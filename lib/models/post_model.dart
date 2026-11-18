class PostModel {
  final String id;
  final String userId;
  final String caption;
  final List<String> imageUrls;
  final String location;
  final DateTime createdAt;
  final int likeCount;
  final List<String> taggedUserIds;
  final bool isCreatedByUser;

  const PostModel({
    required this.id,
    required this.userId,
    required this.caption,
    required this.imageUrls,
    this.location = '',
    required this.createdAt,
    this.likeCount = 0,
    this.taggedUserIds = const [],
    this.isCreatedByUser = false,
  });

  PostModel copyWith({
    String? caption,
    List<String>? imageUrls,
    String? location,
    int? likeCount,
    List<String>? taggedUserIds,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      caption: caption ?? this.caption,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      taggedUserIds: taggedUserIds ?? this.taggedUserIds,
      isCreatedByUser: isCreatedByUser,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'caption': caption,
        'imageUrls': imageUrls,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'likeCount': likeCount,
        'taggedUserIds': taggedUserIds,
        'isCreatedByUser': isCreatedByUser,
      };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        imageUrls: List<String>.from(json['imageUrls'] as List? ?? const []),
        location: json['location'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        likeCount: json['likeCount'] as int? ?? 0,
        taggedUserIds:
            List<String>.from(json['taggedUserIds'] as List? ?? const []),
        isCreatedByUser: json['isCreatedByUser'] as bool? ?? false,
      );
}
