import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../widgets/app_image.dart';
import '../widgets/user_avatar.dart';
import '../../models/story_model.dart';
import '../../controllers/messages_controller.dart';
import '../../controllers/story_controller.dart';

class StoryViewer extends ConsumerStatefulWidget {
  final int initialIndex;

  const StoryViewer({super.key, required this.initialIndex});

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  Ticker? _ticker;
  final Stopwatch _watch = Stopwatch();
  Timer? _advanceTimer;
  late int _index;
  bool _paused = false;
  bool _holdPaused = false;
  bool _focusPaused = false;
  final _replyController = TextEditingController();
  final _replyFocus = FocusNode();
  String? _floatingReaction;

  /// One single source of truth for both the bar and the auto-advance timer.
  double get _progressValue {
    final elapsed = _watch.elapsedMilliseconds;
    return (elapsed > 10000 ? 10000 : elapsed) / 10000;
  }

  /// Stories from blocked users are never shown or navigated into.
  List<StoryModel> get _stories =>
      ref.read(storyControllerProvider).state.visibleStories;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _ticker = createTicker((_) => setState(() {}));
    _replyFocus.addListener(_handleReplyFocus);
    _start();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _ticker?.dispose();
    _pageController.dispose();
    _replyFocus.removeListener(_handleReplyFocus);
    _replyFocus.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _scheduleAdvance() {
    final remainingMs = 10000 - _watch.elapsedMilliseconds;
    _advanceTimer = Timer(
      Duration(milliseconds: remainingMs > 0 ? remainingMs : 0),
      () {
        if (mounted && !_paused) _next();
      },
    );
  }

  void _start() {
    _advanceTimer?.cancel();
    final controller = ref.read(storyControllerProvider);
    final stories = _stories;
    if (_index < stories.length) {
      controller.markStoryViewed(stories[_index].id);
    }
    _paused = false;
    _holdPaused = false;
    _focusPaused = false;
    _watch
      ..reset()
      ..start();
    if (!_ticker!.isActive) _ticker!.start();
    _scheduleAdvance();
  }

  void _goTo(int index) {
    _replyFocus.unfocus();
    final count = _stories.length;
    if (index < 0 || index >= count) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    _start();
  }

  void _next() => _goTo(_index + 1);

  void _previous() {
    if (_progressValue > .2) {
      _watch
        ..reset()
        ..start();
      if (!_ticker!.isActive) _ticker!.start();
      _advanceTimer?.cancel();
      _scheduleAdvance();
    } else {
      _goTo(_index - 1);
    }
  }

  void _pause() {
    if (_paused) return;
    setState(() => _paused = true);
    _watch.stop();
    _ticker?.stop();
    _advanceTimer?.cancel();
  }

  void _resume() {
    if (!_paused) return;
    setState(() => _paused = false);
    _watch.start();
    if (!_ticker!.isActive) _ticker!.start();
    _scheduleAdvance();
  }

  void _togglePause() => _paused ? _resume() : _pause();

  void _handleReplyFocus() {
    if (_replyFocus.hasFocus) {
      if (!_paused) {
        _focusPaused = true;
        _pause();
      }
    } else if (_focusPaused) {
      _focusPaused = false;
      _resume();
    }
  }

  void _onHoldStart(LongPressStartDetails _) {
    if (_paused || _replyFocus.hasFocus) return;
    _holdPaused = true;
    _pause();
  }

  void _onHoldEnd(LongPressEndDetails _) {
    if (!_holdPaused) return;
    _holdPaused = false;
    _resume();
  }

  Widget _tapZone({required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    onLongPressStart: _onHoldStart,
    onLongPressEnd: _onHoldEnd,
    behavior: HitTestBehavior.opaque,
    child: const SizedBox.expand(),
  );

  void _sendReaction(String emoji) {
    final state = ref.read(storyControllerProvider).state;
    final me = state.currentUser;
    if (me == null || _index >= state.visibleStories.length) return;
    final story = state.visibleStories[_index];
    if (story.userId == me.id || state.isBlocked(story.userId)) return;
    ref
        .read(messagesControllerProvider)
        .sendMessage(story.userId, emoji, autoReply: false);
    setState(() => _floatingReaction = emoji);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && _floatingReaction == emoji) {
        setState(() => _floatingReaction = null);
      }
    });
    FeedbackUtils.tap();
  }

  void _sendReply() {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final state = ref.read(storyControllerProvider).state;
    final me = state.currentUser;
    if (me == null || _index >= state.visibleStories.length) return;
    final story = state.visibleStories[_index];
    if (story.userId == me.id || state.isBlocked(story.userId)) return;
    ref
        .read(messagesControllerProvider)
        .sendMessage(
          story.userId,
          'Replied to your story: $text',
          autoReply: false,
        );
    _replyController.clear();
    _replyFocus.unfocus();
    FeedbackUtils.snack(context, 'Reply sent');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyControllerProvider).state;
    final stories = state.visibleStories;
    if (stories.isEmpty) {
      return const Scaffold(body: Center(child: Text('No stories yet')));
    }
    if (_index >= stories.length) _index = stories.length - 1;
    final story = stories[_index];
    final user = state.userById(story.userId);
    final me = state.currentUser;
    final isMyStory = me?.id == story.userId;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta != null && details.primaryDelta! > 12) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: stories.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                _start();
              },
              itemBuilder: (context, index) => _StoryMedia(
                story: stories[index],
                active: index == _index && !_paused,
              ),
            ),
            // Tap zones: tap for next/previous/pause, hold anywhere to pause.
            Row(
              children: [
                Expanded(child: _tapZone(onTap: _previous)),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .4,
                  child: _tapZone(onTap: _togglePause),
                ),
                Expanded(child: _tapZone(onTap: _next)),
              ],
            ),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < stories.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1.5,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: i < _index
                                          ? 1
                                          : (i == _index ? _progressValue : 0),
                                      minHeight: 2.5,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: .35,
                                      ),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          imageUrl: user?.profileImage ?? '',
                          size: 34,
                          hasStory: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user?.username ?? 'unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (user?.isVerified == true) ...[
                                    const SizedBox(width: 3),
                                    const Icon(
                                      Icons.verified,
                                      size: 13,
                                      color: AppColors.instagramBlue,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                Formatters.timeAgo(story.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (story.caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            story.caption,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (me != null &&
                      !isMyStory &&
                      !state.isBlocked(story.userId))
                    _StoryReplyBar(
                      controller: _replyController,
                      focusNode: _replyFocus,
                      onEmoji: _sendReaction,
                      onSend: _sendReply,
                    ),
                ],
              ),
            ),
            if (_paused)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: scheme.scrim.withValues(alpha: .5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause, color: Colors.white, size: 36),
                ),
              ),
            if (_floatingReaction != null)
              Positioned(
                right: 26,
                bottom: 148,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, value, child) => Opacity(
                      opacity: (1 - value).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, -36 * value),
                        child: Transform.scale(
                          scale: .7 + (.5 * value),
                          child: child,
                        ),
                      ),
                    ),
                    child: Text(
                      _floatingReaction!,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryMedia extends StatefulWidget {
  final StoryModel story;
  final bool active;

  const _StoryMedia({required this.story, required this.active});

  @override
  State<_StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends State<_StoryMedia> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    if (widget.story.isVideo) {
      _video =
          VideoPlayerController.networkUrl(Uri.parse(widget.story.mediaUrl))
            ..initialize()
                .then((_) {
                  if (!mounted) return;
                  setState(() {});
                  _video?.setLooping(true);
                  if (widget.active) _video?.play();
                })
                .catchError((_) {});
    }
  }

  @override
  void didUpdateWidget(covariant _StoryMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _video?.play();
      } else {
        _video?.pause();
      }
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.isVideo) {
      final video = _video;
      if (video != null && video.value.isInitialized) {
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: video.value.size.width,
              height: video.value.size.height,
              child: VideoPlayer(video),
            ),
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            url: 'https://picsum.photos/seed/storyfallback/800/1280',
            errorWidget: Container(color: Colors.black87),
          ),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }
    return SizedBox.expand(
      child: AppImage(
        url: widget.story.mediaUrl,
        fit: BoxFit.cover,
        errorWidget: Container(color: Colors.black87),
      ),
    );
  }
}

class _StoryReplyBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onEmoji;
  final VoidCallback onSend;

  const _StoryReplyBar({
    required this.controller,
    required this.focusNode,
    required this.onEmoji,
    required this.onSend,
  });

  static const _emojis = ['❤️', '😂', '😮', '😢', '👏', '🔥'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final emoji = _emojis[index];
                return GestureDetector(
                  onTap: () => onEmoji(emoji),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 21)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Send message',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: .6),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: .12),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
