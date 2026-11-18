import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../../models/post_model.dart';
import '../../controllers/feed_controller.dart';
import '../home/full_screen_image.dart';
import 'app_image.dart';
import 'comment_sheet.dart';
import 'share_sheet.dart';
import 'user_avatar.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final bool showCaption;

  /// Set by the home feed so the tapped image animates into the full-screen
  /// viewer. Other screens keep the original route transition.
  final String? heroId;

  const PostCard({
    super.key,
    required this.post,
    this.showCaption = true,
    this.heroId,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with TickerProviderStateMixin {
  final _commentController = TextEditingController();
  late final AnimationController _heartController;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;
  Timer? _singleTapTimer;
  Offset? _heartPosition;
  bool _showHeart = false;
  bool _expanded = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _heartController =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: 10),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _showHeart = false);
          }
        });
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _pressScale = Tween<double>(
      begin: 1,
      end: .97,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _commentController.dispose();
    _heartController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _like() {
    final controller = ref.read(feedControllerProvider);
    if (!controller.state.likedPosts.contains(widget.post.id)) {
      controller.toggleLikePost(widget.post.id);
      FeedbackUtils.tap();
    }
  }

  void _onImageTapDown(TapDownDetails _) => _pressController.forward();

  void _onImageTapUp(TapUpDetails _) => _pressController.reverse();

  void _onImageTapCancel() => _pressController.reverse();

  Widget _feedImage(int index) {
    final image = AppImage(
      url: widget.post.imageUrls[index],
      width: double.infinity,
      height: double.infinity,
    );
    final heroId = widget.heroId;
    if (heroId == null) return image;
    return Hero(
      tag: FullScreenImageViewer.heroTag(heroId, index),
      child: image,
    );
  }

  void _onImageTap() {
    _singleTapTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenImageViewer(
            urls: widget.post.imageUrls,
            initialIndex: _page,
            heroId: widget.heroId,
          ),
        ),
      );
    });
  }

  void _onDoubleTapDown(TapDownDetails details) =>
      _heartPosition = details.localPosition;

  void _onDoubleTap() {
    _singleTapTimer?.cancel();
    _like();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(feedControllerProvider)
        .addComment(targetId: widget.post.id, targetType: 'post', text: text);
    _commentController.clear();
    FeedbackUtils.tap();
  }

  void _menu(String value) {
    final controller = ref.read(feedControllerProvider);
    switch (value) {
      case 'save':
        controller.toggleSavePost(widget.post.id);
        FeedbackUtils.snack(context, 'Post saved locally');
      case 'copy':
        FeedbackUtils.copy('https://local.instagram.demo/p/${widget.post.id}');
        FeedbackUtils.snack(context, 'Link copied');
      case 'report':
        FeedbackUtils.snack(context, 'Report sent (demo)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider).state;
    final post = widget.post;
    final me = state.currentUser;
    final author = state.userById(post.userId);
    final liked = state.likedPosts.contains(post.id);
    final saved = state.savedPosts.contains(post.id);
    final commentCount = state.commentCountFor(post.id);
    final following = state.isFollowing(post.userId);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: author?.profileImage ?? '',
                size: 38,
                viewed: true,
                onTap: () => context.push('/profile/${post.userId}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/profile/${post.userId}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              author?.username ?? 'unknown',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (author?.isVerified == true) ...[
                            const SizedBox(width: 3),
                            const VerifiedBadge(size: 13),
                          ],
                          const SizedBox(width: 5),
                          Text(
                            '· ${Formatters.timeAgo(post.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (post.location.isNotEmpty)
                        Text(
                          post.location,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (me != null && me.id != post.userId && !following)
                TextButton(
                  onPressed: () {
                    ref.read(feedControllerProvider).toggleFollow(post.userId);
                    FeedbackUtils.snack(
                      context,
                      'Following @${author?.username ?? ''}',
                    );
                  },
                  child: const Text(
                    'Follow',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: _menu,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'save',
                    child: Text(saved ? 'Remove from saved' : 'Save post'),
                  ),
                  const PopupMenuItem(value: 'copy', child: Text('Copy link')),
                  const PopupMenuItem(value: 'report', child: Text('Report')),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTapDown: _onImageTapDown,
          onTapUp: _onImageTapUp,
          onTapCancel: _onImageTapCancel,
          onTap: _onImageTap,
          onDoubleTapDown: _onDoubleTapDown,
          onDoubleTap: _onDoubleTap,
          child: ScaleTransition(
            scale: _pressScale,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    itemCount: post.imageUrls.length,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemBuilder: (context, index) => _feedImage(index),
                  ),
                  if (post.imageUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_page + 1}/${post.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (post.imageUrls.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < post.imageUrls.length; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _page
                                    ? AppColors.instagramBlue
                                    : Colors.white.withValues(alpha: .6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_showHeart && _heartPosition != null)
                    Positioned(
                      left: (_heartPosition!.dx - 90)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                      top: (_heartPosition!.dy - 90)
                          .clamp(0.0, double.infinity)
                          .toDouble(),
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Lottie.asset(
                            'assets/lottie/love_particle.json',
                            controller: _heartController,
                            fit: BoxFit.contain,
                            onLoaded: (composition) {
                              _heartController.duration = const Duration(seconds: 10);
                              _heartController.forward(from: 0);
                            },
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  ref.read(feedControllerProvider).toggleLikePost(post.id);
                  FeedbackUtils.tap();
                },
                icon: AnimatedScale(
                  scale: liked ? 1.15 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    liked ? Icons.favorite : Icons.favorite_outline,
                    color: liked ? AppColors.likeRed : scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showCommentSheet(
                  context,
                  targetId: post.id,
                  targetType: 'post',
                ),
                icon: const Icon(Icons.mode_comment_outlined),
              ),
              IconButton(
                onPressed: () =>
                    showShareSheet(context, itemId: post.id, label: 'post'),
                icon: const Icon(Icons.send_outlined),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.read(feedControllerProvider).toggleSavePost(post.id);
                  FeedbackUtils.snack(
                    context,
                    saved ? 'Removed from saved' : 'Post saved',
                  );
                },
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${Formatters.count(state.effectiveLikeCount(post))} likes',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (widget.showCaption) ...[
                const SizedBox(height: 6),
                RichText(
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded
                      ? TextOverflow.clip
                      : TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(color: scheme.onSurface, fontSize: 13),
                    children: [
                      TextSpan(
                        text: '${author?.username ?? 'unknown'} ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: post.caption),
                    ],
                  ),
                ),
                if (post.caption.length > 60 ||
                    Formatters.hashtags(post.caption).isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _expanded ? 'less' : 'more',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
              if (commentCount > 0) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => showCommentSheet(
                    context,
                    targetId: post.id,
                    targetType: 'post',
                  ),
                  child: Text(
                    'View all $commentCount comments',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  if (me != null)
                    ClipOval(
                      child: AppImage(
                        url: me.profileImage,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  TextButton(
                    onPressed: _submitComment,
                    child: const Text(
                      'Post',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(
          height: 1,
          thickness: 6,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ],
    );
  }
}