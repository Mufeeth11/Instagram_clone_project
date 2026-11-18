class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String website;
  final String profileImage;
  final bool isVerified;
  final bool isPrivate;
  final List<String> followers;
  final List<String> following;
  final String email;
  final String password;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.website = '',
    this.profileImage = '',
    this.isVerified = false,
    this.isPrivate = false,
    this.followers = const [],
    this.following = const [],
    this.email = '',
    this.password = '',
  });

  UserModel copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? website,
    String? profileImage,
    bool? isVerified,
    bool? isPrivate,
    List<String>? followers,
    List<String>? following,
    String? email,
    String? password,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'website': website,
        'profileImage': profileImage,
        'isVerified': isVerified,
        'isPrivate': isPrivate,
        'followers': followers,
        'following': following,
        'email': email,
        'password': password,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        website: json['website'] as String? ?? '',
        profileImage: json['profileImage'] as String? ?? '',
        isVerified: json['isVerified'] as bool? ?? false,
        isPrivate: json['isPrivate'] as bool? ?? false,
        followers: List<String>.from(json['followers'] as List? ?? const []),
        following: List<String>.from(json['following'] as List? ?? const []),
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );
}
