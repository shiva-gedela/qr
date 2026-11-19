class SocialCommentModel {
  final String id;
  final String userName;
  final String text;
  final DateTime createdAt;

  SocialCommentModel({
    required this.id,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory SocialCommentModel.fromJson(Map<String, dynamic> json) {
    return SocialCommentModel(
      id: json['id'] ?? '',
      userName: json['user_name'] ?? 'User',
      text: json['text'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_name': userName,
    'text': text,
    'created_at': createdAt.toIso8601String(),
  };
}

class SocialPostModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String? eventTitle;
  final String? eventTag;
  final String caption;
  final String? imageUrl;
  int likesCount;
  bool isLiked;
  final List<SocialCommentModel> comments;
  final DateTime createdAt;

  SocialPostModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    this.eventTitle,
    this.eventTag,
    required this.caption,
    this.imageUrl,
    this.likesCount = 0,
    this.isLiked = false,
    this.comments = const [],
    required this.createdAt,
  });

  factory SocialPostModel.fromJson(Map<String, dynamic> json) {
    final rawComments = json['comments'] as List? ?? [];
    return SocialPostModel(
      id: json['id']?.toString() ?? '',
      userName: json['user_name'] ?? 'Celebration Host',
      userAvatar: json['user_avatar'] ?? '',
      eventTitle: json['event_title'],
      eventTag: json['event_tag'],
      caption: json['caption'] ?? '',
      imageUrl: json['image_url'],
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      comments: rawComments.map((c) => SocialCommentModel.fromJson(Map<String, dynamic>.from(c))).toList(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_name': userName,
    'user_avatar': userAvatar,
    'event_title': eventTitle,
    'event_tag': eventTag,
    'caption': caption,
    'image_url': imageUrl,
    'likes_count': likesCount,
    'is_liked': isLiked,
    'comments': comments.map((c) => c.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };
}
