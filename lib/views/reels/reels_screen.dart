import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../widgets/app_image.dart';
import '../widgets/comment_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/share_sheet.dart';
import '../widgets/user_avatar.dart';
import '../../core/services/pixabay_service.dart';
import '../../core/services/reel_preloader.dart';
import '../../models/reel_model.dart';
import '../../controllers/controllers.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  /// The shell sets this to false while another tab is visible so that
  /// video controllers are released instead of playing in the background.
  final bool active;

  /// Reel to start on when the tab is opened from another screen.
  final int initialIndex;

  const ReelsScreen({super.key, this.active = true, this.initialIndex = 0});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  late final PageController _pageController;
  int _current = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    final reelCount =
        ref.read(reelsControllerProvider).state.visibleReels.length;
    _current = reelCount == 0
        ? 0
        : widget.initialIndex.clamp(0, reelCount - 1).toInt();
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final state = ref.watch(reelsControllerProvider).state;
    final pixabayAsync = ref.watch(pixabayVideosProvider);
    final pixabayVideos = pixabayAsync.value ?? const <PixabayVideo>[];
    final reels = state.visibleReels;
    if (_current >= reels.length) _current = 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (reels.isEmpty)
            const EmptyState(
              icon: Icons.movie_outlined,
              title: 'No reels yet',
              message: 'Check back later for new reels.',
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (context, index) {
                final reel = reels[index];
                final pixabay = pixabayVideos.isEmpty
                    ? null
                    : pixabayVideos[index % pixabayVideos.length];
                return ReelItem(
                  reel: pixabay == null ? reel : _reelWithVideo(reel, pixabay),
                  audioUrl: pixabay?.audioUrl,
                  audioTitle: pixabay?.audioTitle,
                  active: index == _current,
                  muted: _muted,
                  preloadUrl: index + 1 < reels.length
                      ? _videoUrlAt(reels, pixabayVideos, index + 1)
                      : null,
                  onToggleMute: () => setState(() => _muted = !_muted),
                );
              },
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reels',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pixabayAsync.isLoading
                              ? 'Loading Pixabay videos…'
                              : pixabayAsync.hasError
                              ? 'Pixabay unavailable · sample clips'
                              : 'Videos by Pixabay',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .55),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _videoUrlAt(
  List<ReelModel> reels,
  List<PixabayVideo> pixabayVideos,
  int index,
) {
  final reel = reels[index];
  final pixabay = pixabayVideos.isEmpty
      ? null
      : pixabayVideos[index % pixabayVideos.length];
  return pixabay?.videoUrl ?? reel.videoUrl;
}

/// Keeps the app's reel identity (id, likes, comments, user) and only swaps
/// the media URLs for a working Pixabay clip.
ReelModel _reelWithVideo(ReelModel reel, PixabayVideo video) => ReelModel(
  id: reel.id,
  userId: reel.userId,
  videoUrl: video.videoUrl,
  thumbnailUrl: video.thumbnailUrl.isNotEmpty
      ? video.thumbnailUrl
      : reel.thumbnailUrl,
  caption: reel.caption,
  audioName: reel.audioName,
  likeCount: reel.likeCount,
  shareCount: reel.shareCount,
  createdAt: reel.createdAt,
);

class ReelItem extends ConsumerStatefulWidget {
  final ReelModel reel;
  final String? audioUrl;
  final String? audioTitle;
  final bool active;
  final bool muted;
  final String? preloadUrl;
  final VoidCallback onToggleMute;

  const ReelItem({
    super.key,
    required this.reel,
    this.audioUrl,
    this.audioTitle,
    required this.active,
    required this.muted,
    this.preloadUrl,
    required this.onToggleMute,
  });

  @override
  ConsumerState<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends ConsumerState<ReelItem>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;
  bool _showHeart = false;
  bool _manuallyPaused = false;
  Timer? _tapTimer;
  int _initToken = 0;
  late final AnimationController _heartController;

  @override
  void initState() {
    super.initState();
    _heartController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _showHeart = false);
            }
          });
    _initVideo();
    if (widget.active) _preloadNext();
  }

  void _initVideo() {
    final token = ++_initToken;
    _startVideo(token);
  }

  Future<void> _startVideo(int token) async {
    final preloaded = await ReelVideoPreloader.take(widget.reel.videoUrl);
    if (!mounted || token != _initToken) {
      preloaded?.dispose();
      return;
    }
    if (preloaded != null) {
      _controller = preloaded;
      _initialized = true;
      _configureAndPlay(preloaded);
      setState(() {});
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.videoUrl),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || token != _initToken || _controller != controller) {
        return;
      }
      _initialized = true;
      _configureAndPlay(controller);
      setState(() {});
    } catch (_) {
      if (mounted && token == _initToken && _controller == controller) {
        setState(() => _error = true);
      }
    }
  }

  void _configureAndPlay(VideoPlayerController controller) {
    controller
      ..setLooping(true)
      ..setVolume(widget.muted ? 0 : 1);
    if (widget.active) controller.play();
  }

  void _preloadNext() {
    final url = widget.preloadUrl;
    if (url != null && url.isNotEmpty && url != widget.reel.videoUrl) {
      ReelVideoPreloader.preload(url);
    }
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reel.videoUrl != oldWidget.reel.videoUrl) {
      // Pixabay results arrived (or changed) after this item was built.
      _tapTimer?.cancel();
      _controller?.dispose();
      _controller = null;
      _initialized = false;
      _error = false;
      _manuallyPaused = false;
      _showHeart = false;
      _heartController.reset();
      _initVideo();
    }
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _manuallyPaused = false;
        if (_initialized) _controller?.play();
      } else {
        _controller?.pause();
      }
    }
    if (widget.muted != oldWidget.muted) {
      _controller?.setVolume(widget.muted ? 0 : 1);
    }
    if (widget.active &&
        (widget.reel.videoUrl != oldWidget.reel.videoUrl ||
            widget.preloadUrl != oldWidget.preloadUrl ||
            (!oldWidget.active && widget.active))) {
      _preloadNext();
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _initToken++;
    _controller?.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _onTap() {
    _tapTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final video = _controller;
      if (video == null || !video.value.isInitialized) return;
      setState(() => _manuallyPaused = !_manuallyPaused);
      if (_manuallyPaused) {
        video.pause();
      } else {
        video.play();
      }
    });
  }

  void _onDoubleTap() {
    _tapTimer?.cancel();
    final controller = ref.read(reelsControllerProvider);
    if (!controller.state.likedReels.contains(widget.reel.id)) {
      controller.toggleLikeReel(widget.reel.id);
      FeedbackUtils.tap();
    }
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelsControllerProvider).state;
    final reel = widget.reel;
    final user = state.userById(reel.userId);
    final liked = state.likedReels.contains(reel.id);
    final saved = state.savedReels.contains(reel.id);
    final following = state.isFollowing(reel.userId);
    final me = state.currentUser;
    final comments = state.commentCountFor(reel.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_initialized && _controller != null)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        else
          AppImage(
            url: reel.thumbnailUrl,
            fit: BoxFit.cover,
            errorWidget: Container(color: Colors.black),
          ),
        if (!_initialized && !_error)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (_error)
          const Positioned(
            top: 80,
            left: 16,
            child: Chip(
              label: Text(
                'Video unavailable · showing preview',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.black87],
              stops: [0, .35, 1],
            ),
          ),
        ),
        if (_initialized && _controller != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller!,
                builder: (context, value, _) {
                  final duration = value.duration.inMilliseconds;
                  final position = value.position.inMilliseconds;
                  final progress = duration <= 0
                      ? 0.0
                      : (position / duration).clamp(0.0, 1.0).toDouble();
                  return LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: .2),
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
        GestureDetector(
          onTap: _onTap,
          onDoubleTap: _onDoubleTap,
          behavior: HitTestBehavior.translucent,
        ),
        if (_showHeart)
          IgnorePointer(
            child: Center(
              child: Lottie.asset(
                'assets/lottie/love_particle.json',
                controller: _heartController,
                repeat: false,
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.favorite, color: Colors.white, size: 110),
              ),
            ),
          ),
        if (_manuallyPaused && widget.active)
          const Center(
            child: Icon(Icons.play_arrow, color: Colors.white70, size: 72),
          ),
        // Right action rail
        Positioned(
          right: 12,
          bottom: 108,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/profile/${reel.userId}'),
                    child: UserAvatar(
                      imageUrl: user?.profileImage ?? '',
                      size: 44,
                      viewed: true,
                    ),
                  ),
                  if (me != null && me.id != reel.userId && !following)
                    Positioned(
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(reelsControllerProvider)
                              .toggleFollow(reel.userId);
                          FeedbackUtils.snack(
                            context,
                            'Following @${user?.username ?? ''}',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.instagramBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _ActionButton(
                icon: liked ? Icons.favorite : Icons.favorite_outline,
                color: liked ? AppColors.likeRed : Colors.white,
                label: Formatters.count(state.effectiveReelLikeCount(reel)),
                onTap: () {
                  ref.read(reelsControllerProvider).toggleLikeReel(reel.id);
                  FeedbackUtils.tap();
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.mode_comment_outlined,
                label: '$comments',
                onTap: () => showCommentSheet(
                  context,
                  targetId: reel.id,
                  targetType: 'reel',
                ),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.send_outlined,
                label: Formatters.count(reel.shareCount),
                onTap: () =>
                    showShareSheet(context, itemId: reel.id, label: 'reel'),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: saved ? Icons.bookmark : Icons.bookmark_border,
                label: 'Save',
                onTap: () {
                  ref.read(reelsControllerProvider).toggleSaveReel(reel.id);
                  FeedbackUtils.snack(
                    context,
                    saved ? 'Removed from saved' : 'Reel saved',
                  );
                },
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: widget.muted ? Icons.volume_off : Icons.volume_up,
                label: widget.muted ? 'Muted' : 'Sound',
                onTap: widget.onToggleMute,
              ),
            ],
          ),
        ),
        // Bottom info
        Positioned(
          left: 16,
          right: 84,
          bottom: 86,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push('/profile/${reel.userId}'),
                child: Row(
                  children: [
                    Text(
                      '@${user?.username ?? 'unknown'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (user?.isVerified == true) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.instagramBlue,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reel.caption,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.music_note, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reel.audioName,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
