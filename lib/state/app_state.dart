import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/storage_service.dart';
import '../data/dummy_data/dummy_data.dart';
import '../models/chat_message_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../models/reel_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';

List<T> _decodeList<T>(dynamic raw, T Function(Map<String, dynamic>) decoder) {
  if (raw is! List) return <T>[];
  return raw
      .whereType<Map>()
      .map((e) => decoder(Map<String, dynamic>.from(e)))
      .toList();
}

Set<String> _decodeSet(dynamic raw) =>
    (raw is List ? raw : const []).map((e) => e.toString()).toSet();

class AppState {
  final String? currentUserId;
  final List<UserModel> users;
  final List<PostModel> posts;
  final List<ReelModel> reels;
  final List<StoryModel> stories;
  final List<CommentModel> comments;
  final List<NotificationModel> notifications;
  final List<ChatMessageModel> chatMessages;
  final Set<String> likedPosts;
  final Set<String> savedPosts;
  final Set<String> likedReels;
  final Set<String> savedReels;
  final Set<String> viewedStories;
  final Set<String> blockedUsers;
  final List<String> searchHistory;
  final ThemeMode themeMode;
  final Map<String, dynamic> settings;

  const AppState({
    this.currentUserId,
    required this.users,
    required this.posts,
    required this.reels,
    required this.stories,
    required this.comments,
    required this.notifications,
    required this.chatMessages,
    this.likedPosts = const {},
    this.savedPosts = const {},
    this.likedReels = const {},
    this.savedReels = const {},
    this.viewedStories = const {},
    this.blockedUsers = const {},
    this.searchHistory = const [],
    this.themeMode = ThemeMode.system,
    this.settings = const {},
  });

  factory AppState.initial() => AppState(
        users: AppDummyData.buildUsers(),
        posts: AppDummyData.buildPosts(),
        reels: AppDummyData.buildReels(),
        stories: AppDummyData.buildStories(),
        comments: AppDummyData.buildComments(),
        notifications: AppDummyData.buildNotifications(),
        chatMessages: const [],
        likedPosts: {'p2', 'p5'},
        savedPosts: {'p3'},
        likedReels: {'r1'},
        settings: const {
          'notifications': true,
          'privateAccount': false,
          'activityStatus': true,
          'commentControls': 'Everyone',
          'language': 'English',
          'archive': false,
        },
      );

  bool get isLoggedIn => currentUserId != null;

  UserModel? get currentUser {
    final id = currentUserId;
    if (id == null) return null;
    return users.where((u) => u.id == id).firstOrNull;
  }

  UserModel? userById(String id) =>
      users.where((u) => u.id == id).firstOrNull;

  List<CommentModel> commentsFor(String targetId) => comments
      .where((c) => c.targetId == targetId)
      .toList()
      .reversed
      .toList();

  int commentCountFor(String targetId) =>
      comments.where((c) => c.targetId == targetId).length;

  int effectiveLikeCount(PostModel post) =>
      post.likeCount + (likedPosts.contains(post.id) ? 1 : 0);

  int effectiveReelLikeCount(ReelModel reel) =>
      reel.likeCount + (likedReels.contains(reel.id) ? 1 : 0);

  bool isFollowing(String userId) =>
      currentUser?.following.contains(userId) ?? false;

  T setting<T>(String key, T fallback) {
    final value = settings[key];
    return value is T ? value : fallback;
  }

  AppState copyWith({
    String? currentUserId,
    bool clearCurrentUser = false,
    List<UserModel>? users,
    List<PostModel>? posts,
    List<ReelModel>? reels,
    List<StoryModel>? stories,
    List<CommentModel>? comments,
    List<NotificationModel>? notifications,
    List<ChatMessageModel>? chatMessages,
    Set<String>? likedPosts,
    Set<String>? savedPosts,
    Set<String>? likedReels,
    Set<String>? savedReels,
    Set<String>? viewedStories,
    Set<String>? blockedUsers,
    List<String>? searchHistory,
    ThemeMode? themeMode,
    Map<String, dynamic>? settings,
  }) {
    return AppState(
      currentUserId: clearCurrentUser ? null : (currentUserId ?? this.currentUserId),
      users: users ?? this.users,
      posts: posts ?? this.posts,
      reels: reels ?? this.reels,
      stories: stories ?? this.stories,
      comments: comments ?? this.comments,
      notifications: notifications ?? this.notifications,
      chatMessages: chatMessages ?? this.chatMessages,
      likedPosts: likedPosts ?? this.likedPosts,
      savedPosts: savedPosts ?? this.savedPosts,
      likedReels: likedReels ?? this.likedReels,
      savedReels: savedReels ?? this.savedReels,
      viewedStories: viewedStories ?? this.viewedStories,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      searchHistory: searchHistory ?? this.searchHistory,
      themeMode: themeMode ?? this.themeMode,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentUserId': currentUserId,
        'users': users.map((e) => e.toJson()).toList(),
        'posts': posts.map((e) => e.toJson()).toList(),
        'reels': reels.map((e) => e.toJson()).toList(),
        'stories': stories.map((e) => e.toJson()).toList(),
        'comments': comments.map((e) => e.toJson()).toList(),
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'chatMessages': chatMessages.map((e) => e.toJson()).toList(),
        'likedPosts': likedPosts.toList(),
        'savedPosts': savedPosts.toList(),
        'likedReels': likedReels.toList(),
        'savedReels': savedReels.toList(),
        'viewedStories': viewedStories.toList(),
        'blockedUsers': blockedUsers.toList(),
        'searchHistory': searchHistory,
        'themeMode': themeMode.index,
        'settings': settings,
      };

  factory AppState.fromJson(Map<String, dynamic> json) {
    final fallback = AppState.initial();
    return AppState(
      currentUserId: json['currentUserId'] as String?,
      users: _decodeList(json['users'], UserModel.fromJson),
      posts: _decodeList(json['posts'], PostModel.fromJson),
      reels: _decodeList(json['reels'], ReelModel.fromJson),
      stories: _decodeList(json['stories'], StoryModel.fromJson),
      comments: _decodeList(json['comments'], CommentModel.fromJson),
      notifications:
          _decodeList(json['notifications'], NotificationModel.fromJson),
      chatMessages:
          _decodeList(json['chatMessages'], ChatMessageModel.fromJson),
      likedPosts: _decodeSet(json['likedPosts']),
      savedPosts: _decodeSet(json['savedPosts']),
      likedReels: _decodeSet(json['likedReels']),
      savedReels: _decodeSet(json['savedReels']),
      viewedStories: _decodeSet(json['viewedStories']),
      blockedUsers: _decodeSet(json['blockedUsers']),
      searchHistory: (json['searchHistory'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      themeMode: ThemeMode.values[(json['themeMode'] as int?) ?? 0],
      settings: Map<String, dynamic>.from(
          (json['settings'] as Map?) ?? fallback.settings),
    );
  }
}

final storageProvider = Provider<StorageService>((ref) => StorageService.instance);

final appProvider = NotifierProvider<AppNotifier, AppState>(AppNotifier.new);

class AppNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final saved = ref.watch(storageProvider).readState();
    if (saved == null) return AppState.initial();
    try {
      return AppState.fromJson(saved);
    } catch (_) {
      return AppState.initial();
    }
  }

  void _persist() {
    unawaited(ref.read(storageProvider).writeState(state.toJson()));
  }

  void _update(AppState next) {
    state = next;
    _persist();
  }

  /// Returns null on success, otherwise a human readable error.
  String? login(String identifier, String password) {
    final key = identifier.trim().toLowerCase();
    UserModel? match;
    for (final user in state.users) {
      if (user.username.toLowerCase() == key ||
          user.email.toLowerCase() == key) {
        match = user;
        break;
      }
    }
    if (match == null) return 'No account found with that username or email.';
    if (match.password != password) return 'Incorrect password. Try again.';
    if (state.blockedUsers.contains(match.id)) {
      return 'This account is blocked locally.';
    }
    _update(state.copyWith(currentUserId: match.id));
    return null;
  }

  void demoLogin() {
    _update(state.copyWith(currentUserId: AppDummyData.currentUserId));
  }

  void logout() => _update(state.copyWith(clearCurrentUser: true));

  String? signUp({
    required String username,
    required String email,
    required String password,
  }) {
    final cleanUsername = username.trim().replaceAll(RegExp(r'\s+'), '_');
    if (cleanUsername.length < 3) return 'Username must be at least 3 characters.';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(cleanUsername)) {
      return 'Use only letters, numbers, dots and underscores.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (state.users.any((u) => u.username.toLowerCase() == cleanUsername.toLowerCase())) {
      return 'That username is already taken.';
    }
    if (state.users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase())) {
      return 'That email is already registered.';
    }
    final user = UserModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      username: cleanUsername,
      displayName: cleanUsername.replaceAll(RegExp(r'[._]'), ' '),
      bio: 'Hello from my local Instagram demo ✨',
      profileImage: AppDummyData.img('local${state.users.length}', size: 300),
      email: email.trim(),
      password: password,
      followers: const [],
      following: const ['u1', 'u2'],
    );
    _update(state.copyWith(
      users: [...state.users, user],
      currentUserId: user.id,
    ));
    return null;
  }

  String? changePassword({required String current, required String next}) {
    final user = state.currentUser;
    if (user == null) return 'You need to be signed in.';
    if (user.password != current) return 'Your current password is incorrect.';
    if (next.length < 6) return 'New password must be at least 6 characters.';
    _updateCurrentUser(password: next);
    return null;
  }

  void _updateCurrentUser({
    String? username,
    String? displayName,
    String? bio,
    String? website,
    String? profileImage,
    bool? isPrivate,
    String? password,
  }) {
    final user = state.currentUser;
    if (user == null) return;
    final updated = user.copyWith(
      username: username,
      displayName: displayName,
      bio: bio,
      website: website,
      profileImage: profileImage,
      isPrivate: isPrivate,
      password: password,
    );
    _update(state.copyWith(
      users: state.users.map((u) => u.id == user.id ? updated : u).toList(),
      settings: isPrivate == null
          ? state.settings
          : {...state.settings, 'privateAccount': isPrivate},
    ));
  }

  void updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? website,
    String? profileImage,
  }) =>
      _updateCurrentUser(
        username: username,
        displayName: displayName,
        bio: bio,
        website: website,
        profileImage: profileImage,
      );

  void togglePrivateAccount() {
    final next = !state.setting<bool>('privateAccount', false);
    _updateCurrentUser(isPrivate: next);
  }

  void toggleLikePost(String id) {
    final set = Set<String>.from(state.likedPosts);
    set.contains(id) ? set.remove(id) : set.add(id);
    _update(state.copyWith(likedPosts: set));
  }

  void toggleSavePost(String id) {
    final set = Set<String>.from(state.savedPosts);
    set.contains(id) ? set.remove(id) : set.add(id);
    _update(state.copyWith(savedPosts: set));
  }

  void toggleLikeReel(String id) {
    final set = Set<String>.from(state.likedReels);
    set.contains(id) ? set.remove(id) : set.add(id);
    _update(state.copyWith(likedReels: set));
  }

  void toggleSaveReel(String id) {
    final set = Set<String>.from(state.savedReels);
    set.contains(id) ? set.remove(id) : set.add(id);
    _update(state.copyWith(savedReels: set));
  }

  void addComment({
    required String targetId,
    required String targetType,
    required String text,
  }) {
    final me = state.currentUser;
    if (me == null || text.trim().isEmpty) return;
    final comment = CommentModel(
      id: 'c_local_${DateTime.now().microsecondsSinceEpoch}',
      targetId: targetId,
      targetType: targetType,
      userId: me.id,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    _update(state.copyWith(comments: [...state.comments, comment]));
  }

  void deleteComment(String id) {
    final me = state.currentUser;
    if (me == null) return;
    final target = state.comments.where((c) => c.id == id).firstOrNull;
    if (target == null || target.userId != me.id) return;
    _update(state.copyWith(
        comments: state.comments.where((c) => c.id != id).toList()));
  }

  void toggleFollow(String userId) {
    final me = state.currentUser;
    if (me == null || userId == me.id) return;
    final users = state.users.map((u) {
      if (u.id == me.id) {
        final following = List<String>.from(u.following);
        following.contains(userId)
            ? following.remove(userId)
            : following.add(userId);
        return u.copyWith(following: following);
      }
      if (u.id == userId) {
        final followers = List<String>.from(u.followers);
        followers.contains(me.id)
            ? followers.remove(me.id)
            : followers.add(me.id);
        return u.copyWith(followers: followers);
      }
      return u;
    }).toList();
    _update(state.copyWith(users: users));
  }

  void markStoryViewed(String id) {
    if (state.viewedStories.contains(id)) return;
    _update(state.copyWith(viewedStories: {...state.viewedStories, id}));
  }

  void addStory(StoryModel story) =>
      _update(state.copyWith(stories: [story, ...state.stories]));

  void addPost(PostModel post) =>
      _update(state.copyWith(posts: [post, ...state.posts]));

  void addReel(ReelModel reel) =>
      _update(state.copyWith(reels: [reel, ...state.reels]));

  void setTheme(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

  void setSetting(String key, dynamic value) =>
      _update(state.copyWith(settings: {...state.settings, key: value}));

  void toggleSetting(String key) =>
      setSetting(key, !state.setting<bool>(key, false));

  void addSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final history = [clean, ...state.searchHistory.where((q) => q != clean)]
        .take(12)
        .toList();
    _update(state.copyWith(searchHistory: history));
  }

  void clearSearchHistory() => _update(state.copyWith(searchHistory: const []));

  void toggleBlockedUser(String userId) {
    final set = Set<String>.from(state.blockedUsers);
    set.contains(userId) ? set.remove(userId) : set.add(userId);
    _update(state.copyWith(blockedUsers: set));
  }

  void markNotificationRead(String id) => _update(state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
      ));

  void markAllNotificationsRead() => _update(state.copyWith(
        notifications:
            state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      ));

  void sendMessage(String threadUserId, String text) {
    final me = state.currentUser;
    if (me == null || text.trim().isEmpty) return;
    final now = DateTime.now();
    addChatMessage(ChatMessageModel(
      id: 'm_${now.microsecondsSinceEpoch}',
      threadUserId: threadUserId,
      senderId: me.id,
      text: text.trim(),
      createdAt: now,
    ));
    final replies = [
      'Haha, love that! ✨',
      'Tell me more 👀',
      'Sounds good to me!',
      'Thanks for sharing 🙏',
      'Let\'s do it!',
    ];
    Timer(const Duration(milliseconds: 1400), () {
      addChatMessage(ChatMessageModel(
        id: 'm_${DateTime.now().microsecondsSinceEpoch}',
        threadUserId: me.id,
        senderId: threadUserId,
        text: replies[now.millisecond % replies.length],
        createdAt: DateTime.now(),
      ));
    });
  }

  void addChatMessage(ChatMessageModel message) =>
      _update(state.copyWith(chatMessages: [...state.chatMessages, message]));
}
