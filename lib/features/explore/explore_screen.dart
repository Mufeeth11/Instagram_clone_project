import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/pixabay_service.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../state/app_state.dart';
import '../../state/navigation_state.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) => setState(() => _query = value.trim());

  void _openFeaturedReel(AppState state) {
    if (state.reels.isEmpty) return;
    ref
        .read(reelsOpenRequestProvider.notifier)
        .open(state.reels.indexOf(state.reels.first));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final scheme = Theme.of(context).colorScheme;
    final q = _query.toLowerCase();
    final users = q.isEmpty
        ? <UserModel>[]
        : state.users
              .where(
                (u) =>
                    u.username.toLowerCase().contains(q) ||
                    u.displayName.toLowerCase().contains(q),
              )
              .toList();
    final posts = q.isEmpty
        ? <PostModel>[]
        : state.posts
              .where(
                (p) =>
                    p.caption.toLowerCase().contains(q) ||
                    p.location.toLowerCase().contains(q),
              )
              .toList();
    final tags = <String>{};
    if (q.isNotEmpty) {
      for (final post in state.posts) {
        for (final tag in Formatters.hashtags(post.caption)) {
          if (tag.toLowerCase().contains(q)) tags.add(tag.toLowerCase());
        }
      }
    }
    final hasResults = users.isNotEmpty || posts.isNotEmpty || tags.isNotEmpty;
    final suggested = state.users
        .where(
          (u) =>
              u.id != state.currentUserId &&
              !state.isFollowing(u.id) &&
              !state.blockedUsers.contains(u.id),
        )
        .take(8)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: (value) {
            _setQuery(value);
            if (value.trim().isNotEmpty) {
              ref.read(appProvider.notifier).addSearch(value);
            }
          },
          decoration: InputDecoration(
            hintText: 'Search users, posts, hashtags',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _setQuery('');
                    },
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: .35),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: q.isEmpty
          ? _browse(state, suggested)
          : !hasResults
          ? EmptyState(
              icon: Icons.search_off,
              title: 'No results found',
              message: 'Try a different username, caption or hashtag.',
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (tags.isNotEmpty) ...[
                  const Text(
                    'Hashtags',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final tag in tags.take(12))
                        ActionChip(
                          label: Text(tag),
                          onPressed: () {
                            _controller.text = tag;
                            _setQuery(tag);
                            ref.read(appProvider.notifier).addSearch(tag);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (users.isNotEmpty) ...[
                  const Text(
                    'Accounts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  ...users
                      .take(8)
                      .map(
                        (user) => ListTile(
                          leading: UserAvatar(
                            imageUrl: user.profileImage,
                            size: 42,
                            viewed: true,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.username,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (user.isVerified)
                                const Icon(
                                  Icons.verified,
                                  size: 13,
                                  color: AppExploreBlue.color,
                                ),
                            ],
                          ),
                          subtitle: Text(
                            user.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              ref
                                  .read(appProvider.notifier)
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
                          onTap: () => context.push('/profile/${user.id}'),
                        ),
                      ),
                  const SizedBox(height: 18),
                ],
                if (posts.isNotEmpty) ...[
                  const Text(
                    'Posts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 3,
                          mainAxisSpacing: 3,
                        ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => context.push('/post/${posts[index].id}'),
                      child: AppImage(url: posts[index].imageUrls.first),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _browse(AppState state, List<UserModel> suggested) {
    final theme = Theme.of(context);
    // The Reels tab replaces demo thumbnails with Pixabay video thumbnails.
    // Use the same first video here so the preview matches what Reels shows.
    final pixabayVideos =
        ref.watch(pixabayVideosProvider).value ?? const <PixabayVideo>[];
    final featuredReel = state.reels.first;
    final featuredThumbnail = pixabayVideos.isEmpty
        ? featuredReel.thumbnailUrl
        : pixabayVideos.first.thumbnailUrl.isNotEmpty
        ? pixabayVideos.first.thumbnailUrl
        : featuredReel.thumbnailUrl;
    return CustomScrollView(
      slivers: [
        if (state.searchHistory.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  const Text(
                    'Recent',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(appProvider.notifier).clearSearchHistory();
                      FeedbackUtils.snack(context, 'Search history cleared');
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
          ),
        if (state.searchHistory.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: state.searchHistory.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  avatar: const Icon(Icons.history, size: 15),
                  label: Text(state.searchHistory[index]),
                  onPressed: () {
                    _controller.text = state.searchHistory[index];
                    _setQuery(state.searchHistory[index]);
                  },
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
            child: Text(
              'Suggested for you',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: suggested.length,
              itemBuilder: (context, index) {
                final user = suggested[index];
                return SizedBox(
                  width: 78,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${user.id}'),
                        child: UserAvatar(
                          imageUrl: user.profileImage,
                          size: 48,
                          viewed: true,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(appProvider.notifier).toggleFollow(user.id);
                          FeedbackUtils.snack(
                            context,
                            'Following @${user.username}',
                          );
                        },
                        child: Text(
                          'Follow',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
            child: Text(
              'Trending now',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => _openFeaturedReel(state),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(url: featuredThumbnail, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black87],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 14,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.movie,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reel of the day · @${state.userById(state.reels.first.userId)?.username ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = state.posts[index % state.posts.length];
              return GestureDetector(
                onTap: () => context.push('/post/${post.id}'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(url: post.imageUrls.first),
                    if (index % 7 == 0)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.movie, color: Colors.white, size: 16),
                      ),
                  ],
                ),
              );
            }, childCount: state.posts.length),
          ),
        ),
      ],
    );
  }
}

class AppExploreBlue {
  static const Color color = Color(0xFF0095F6);
}
