import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/media_picker_service.dart';
import '../widgets/app_image.dart';
import '../widgets/ig_logo.dart';
import '../widgets/post_card.dart';
import '../../data/dummy_data/dummy_data.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../controllers/controllers.dart';
import '../../state/app_state.dart';
import '../stories/story_viewer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Small, uneven offsets give the strip a hand-collaged feel.
  static const _storyTilts = <double>[-0.05, 0.035, -0.025, 0.05, -0.04, 0.02];
  static const _storyLifts = <double>[8, 0, 12, 3, 9, 1];

  Future<void> _refresh(WidgetRef ref, BuildContext context) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!context.mounted) return;
    final state = ref.read(feedControllerProvider).state;
    final me = state.currentUser;
    if (me == null) return;
    final authors = state.users
        .where((u) => u.id != me.id && !state.isBlocked(u.id))
        .toList();
    if (authors.isEmpty) return;
    final index = state.visiblePosts.length + 1;
    ref
        .read(feedControllerProvider)
        .addPost(
          PostModel(
            id: 'p_refresh_${DateTime.now().microsecondsSinceEpoch}',
            userId: authors[index % authors.length].id,
            caption: 'Fresh from the feed ✨ #new #discover',
            imageUrls: [AppDummyData.img('refresh$index')],
            location:
                AppDummyData.locations[index % AppDummyData.locations.length],
            createdAt: DateTime.now(),
            likeCount: 42 + index * 7,
          ),
        );
    FeedbackUtils.snack(context, 'Feed refreshed with a new post');
  }

  Future<void> _addStory(BuildContext context, WidgetRef ref) async {
    final me = ref.read(storyControllerProvider).state.currentUser;
    if (me == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add to your story'),
        content: const SizedBox(
          width: 320,
          child: Text(
            'Choose a picture from your gallery to share as a story.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final path = await MediaPickerService.pickImage();
              if (!context.mounted) return;
              if (path == null) {
                FeedbackUtils.snack(
                  context,
                  'Gallery unavailable or permission denied',
                  isError: true,
                );
                return;
              }
              ref
                  .read(storyControllerProvider)
                  .addStory(
                    StoryModel(
                      id: 's_local_${DateTime.now().microsecondsSinceEpoch}',
                      userId: me.id,
                      mediaUrl: path,
                      caption: 'A little moment ✨',
                      createdAt: DateTime.now(),
                    ),
                  );
              Navigator.pop(dialogContext);
              FeedbackUtils.snack(context, 'Story added');
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery'),
          ),
        ],
      ),
    );
  }

  /// Visual-only rewrite of the story strip: same items, same taps.
  Widget _buildStoryStrip(
    BuildContext context,
    WidgetRef ref,
    AppState state,
    String myImageUrl,
    List<StoryModel> stories,
  ) {
    return SizedBox(
      height: 176,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          final tilt = _storyTilts[index % _storyTilts.length];
          final lift = _storyLifts[index % _storyLifts.length];
          final card = index == 0
              ? _AddStoryTile(
                  imageUrl: myImageUrl,
                  onTap: () => _addStory(context, ref),
                )
              : _buildStoryTile(context, state, stories, index);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Transform.translate(
              offset: Offset(0, lift),
              child: Transform.rotate(angle: tilt, child: card),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryTile(
    BuildContext context,
    AppState state,
    List<StoryModel> stories,
    int index,
  ) {
    final storyIndex = index - 1;
    final story = stories[storyIndex];
    final user = state.userById(story.userId);
    return _StoryTile(
      imageUrl: story.mediaUrl,
      name: user?.username ?? '',
      number: index,
      viewed: state.viewedStories.contains(story.id),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryViewer(initialIndex: storyIndex),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedControllerProvider).state;
    final me = state.currentUser;
    final stories = state.visibleStories;
    final posts = state.visiblePosts;
    final unread = state.visibleNotifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const IgLogo(iconSize: 22, fontSize: 22),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.favorite_border),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/messages'),
            icon: const Icon(Icons.send_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref, context),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildStoryStrip(
                context,
                ref,
                state,
                me?.profileImage ?? '',
                stories,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Following',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${Formatters.count(posts.length)} posts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) => PostCard(
                post: posts[index],
                heroId: posts[index].id,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A paper-scrap style card for a story that has not been opened yet.
class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.imageUrl,
    required this.name,
    required this.number,
    required this.viewed,
    required this.onTap,
  });

  final String imageUrl;
  final String name;
  final int number;
  final bool viewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = AppImage(url: imageUrl);

    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                height: 112,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: viewed ? null : AppColors.storyGradient,
                  color: viewed
                      ? scheme.outlineVariant.withValues(alpha: .6)
                      : null,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: viewed
                              ? Opacity(opacity: .82, child: image)
                              : image,
                        ),
                        Positioned(
                          top: 7,
                          left: 7,
                          child: _MiniTag(
                            text: number.toString().padLeft(2, '0'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!viewed)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                ),
              if (!viewed) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: viewed ? FontWeight.w400 : FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: viewed ? .5 : .9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The first tile keeps the same add-story action, with a different face.
class _AddStoryTile extends StatelessWidget {
  const _AddStoryTile({required this.imageUrl, required this.onTap});

  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(17),
              child: Container(
                height: 112,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: .7),
                    width: 1.4,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: .22,
                          child: AppImage(url: imageUrl),
                        ),
                      ),
                      const Positioned(
                        top: 7,
                        left: 7,
                        child: _MiniTag(text: 'YOU'),
                      ),
                      Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your story',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: .9),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
