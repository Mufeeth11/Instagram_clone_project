class ReelModel {
  final String id;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String audioName;
  final int likeCount;
  final int shareCount;
  final DateTime createdAt;

  const ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    this.audioName = 'Original audio',
    this.likeCount = 0,
    this.shareCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'audioName': audioName,
        'likeCount': likeCount,
        'shareCount': shareCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReelModel.fromJson(Map<String, dynamic> json) => ReelModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        videoUrl: json['videoUrl'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
        caption: json['caption'] as String? ?? '',
        audioName: json['audioName'] as String? ?? 'Original audio',
        likeCount: json['likeCount'] as int? ?? 0,
        shareCount: json['shareCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
