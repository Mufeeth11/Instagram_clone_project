import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../widgets/app_image.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../../models/post_model.dart';
import '../../models/reel_model.dart';
import '../../controllers/profile_controller.dart';
import '../reels/reels_screen.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  final String? initialTab;

  const ProfileScreen({super.key, this.userId, this.initialTab});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      initialIndex: widget.initialTab == 'saved' ? 3 : 0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _peopleSheet(List<String> ids, String title) {
    final state = ref.read(profileControllerProvider).state;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ids.length,
                itemBuilder: (context, index) {
                  final user = state.userById(ids[index]);
                  if (user == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: UserAvatar(
                      imageUrl: user.profileImage,
                      size: 44,
                      viewed: true,
                    ),
                    title: Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(user.displayName),
                    trailing: state.currentUserId != user.id
                        ? TextButton(
                            onPressed: () => ref
                                .read(profileControllerProvider)
                                .toggleFollow(user.id),
                            child: Text(
                              state.isFollowing(user.id)
                                  ? 'Following'
                                  : 'Follow',
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile/${user.id}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReels(List<ReelModel> reels, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReelPreview(reels: reels, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider).state;
    final targetId = widget.userId ?? state.currentUserId;
    final user = targetId == null ? null : state.userById(targetId);
    final me = state.currentUser;
    final isMe = user != null && me?.id == user.id;
    final scheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const EmptyState(
          icon: Icons.person_off,
          title: 'Profile not found',
        ),
      );
    }

    final posts = state.posts.where((p) => p.userId == user.id).toList();
    final reels = state.reels.where((r) => r.userId == user.id).toList();
    final tagged = state.posts
        .where((p) => p.taggedUserIds.contains(user.id))
        .toList();
    final saved = isMe
        ? state.posts.where((p) => state.savedPosts.contains(p.id)).toList()
        : <PostModel>[];
    final savedReels = isMe
        ? state.reels.where((r) => state.savedReels.contains(r.id)).toList()
        : <ReelModel>[];

    return Scaffold(
      appBar: AppBar(
        leading: widget.userId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          user.username,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  ref
                      .read(profileControllerProvider)
                      .toggleBlockedUser(user.id);
                  FeedbackUtils.snack(
                    context,
                    '${state.blockedUsers.contains(user.id) ? 'Unblocked' : 'Blocked'} @${user.username}',
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    state.blockedUsers.contains(user.id) ? 'Unblock' : 'Block',
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: scheme.onSurface,
          labelColor: scheme.onSurface,
          unselectedLabelColor: scheme.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on, size: 22)),
            Tab(icon: Icon(Icons.movie_outlined, size: 22)),
            Tab(icon: Icon(Icons.perm_contact_cal_outlined, size: 22)),
            Tab(icon: Icon(Icons.bookmark_border, size: 22)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: user.profileImage,
                  size: 76,
                  hasStory: false,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(
                        label: 'posts',
                        value: posts.length,
                        onTap: () => _tabs.animateTo(0),
                      ),
                      _Stat(
                        label: 'followers',
                        value: user.followers.length,
                        onTap: () => _peopleSheet(user.followers, 'Followers'),
                      ),
                      _Stat(
                        label: 'following',
                        value: user.following.length,
                        onTap: () => _peopleSheet(user.following, 'Following'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (user.isVerified)
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.instagramBlue,
                      ),
                  ],
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(user.bio, style: const TextStyle(fontSize: 13)),
                ],
                if (user.website.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    user.website,
                    style: const TextStyle(
                      color: AppColors.instagramBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: isMe
                          ? OutlinedButton(
                              onPressed: () => showEditProfileSheet(context),
                              child: const Text('Edit profile'),
                            )
                          : FilledButton(
                              onPressed: () {
                                ref
                                    .read(profileControllerProvider)
                                    .toggleFollow(user.id);
                                FeedbackUtils.snack(
                                  context,
                                  '${state.isFollowing(user.id) ? 'Unfollowed' : 'Following'} @${user.username}',
                                );
                              },
                              child: Text(
                                state.isFollowing(user.id)
                                    ? 'Following'
                                    : 'Follow',
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isMe
                            ? () => context.go('/main')
                            : () => context.push('/messages', extra: user.id),
                        child: Text(isMe ? 'Share profile' : 'Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _PostGrid(
                  posts: posts,
                  emptyTitle: 'No posts yet',
                  onTap: (index) => context.push('/post/${posts[index].id}'),
                ),
                reels.isEmpty
                    ? const EmptyState(
                        icon: Icons.movie_outlined,
                        title: 'No reels yet',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                        itemCount: reels.length,
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => _openReels(reels, index),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppImage(url: reels[index].thumbnailUrl),
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: Icon(
                                  Icons.movie,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                _PostGrid(
                  posts: tagged,
                  emptyTitle: 'No tagged posts',
                  onTap: (index) => context.push('/post/${tagged[index].id}'),
                ),
                isMe
                    ? _SavedGrid(
                        posts: saved,
                        reels: savedReels,
                        emptyTitle: 'Nothing saved yet',
                        message: 'Bookmark posts or reels to find them here.',
                        onPostTap: (index) =>
                            context.push('/post/${saved[index].id}'),
                        onReelTap: (index) => _openReels(savedReels, index),
                      )
                    : const EmptyState(
                        icon: Icons.lock_outline,
                        title: 'Saved posts are private',
                        message: 'Only you can see your saved collection.',
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onTap;

  const _Stat({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _PostGrid extends StatelessWidget {
  final List<PostModel> posts;
  final String emptyTitle;
  final ValueChanged<int> onTap;

  const _PostGrid({
    required this.posts,
    required this.emptyTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return EmptyState(icon: Icons.grid_on, title: emptyTitle);
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => onTap(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(url: post.imageUrls.first),
              if (post.imageUrls.length > 1)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.auto_stories,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SavedGrid extends StatelessWidget {
  final List<PostModel> posts;
  final List<ReelModel> reels;
  final String emptyTitle;
  final String? message;
  final ValueChanged<int> onPostTap;
  final ValueChanged<int> onReelTap;

  const _SavedGrid({
    required this.posts,
    required this.reels,
    required this.emptyTitle,
    this.message,
    required this.onPostTap,
    required this.onReelTap,
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty && reels.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border,
        title: emptyTitle,
        message: message,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length + reels.length,
      itemBuilder: (context, index) {
        if (index >= posts.length) {
          final reelIndex = index - posts.length;
          final reel = reels[reelIndex];
          return GestureDetector(
            onTap: () => onReelTap(reelIndex),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(url: reel.thumbnailUrl),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.movie, size: 17, color: Colors.white),
                ),
              ],
            ),
          );
        }
        final post = posts[index];
        return GestureDetector(
          onTap: () => onPostTap(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(url: post.imageUrls.first),
              if (post.imageUrls.length > 1)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.auto_stories,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReelPreview extends ConsumerStatefulWidget {
  final List<ReelModel> reels;
  final int initialIndex;

  const _ReelPreview({required this.reels, required this.initialIndex});

  @override
  ConsumerState<_ReelPreview> createState() => _ReelPreviewState();
}

class _ReelPreviewState extends ConsumerState<_ReelPreview> {
  int _index = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: widget.reels.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) => ReelItem(
              reel: widget.reels[index],
              active: index == _index,
              muted: _muted,
              preloadUrl: index + 1 < widget.reels.length
                  ? widget.reels[index + 1].videoUrl
                  : null,
              onToggleMute: () => setState(() => _muted = !_muted),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
