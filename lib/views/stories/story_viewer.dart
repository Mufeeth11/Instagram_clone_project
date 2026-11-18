import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../widgets/app_image.dart';
import '../widgets/user_avatar.dart';
import '../../models/story_model.dart';
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

  /// One single source of truth for both the bar and the auto-advance timer.
  double get _progressValue {
    final elapsed = _watch.elapsedMilliseconds;
    return (elapsed > 10000 ? 10000 : elapsed) / 10000;
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
    _ticker = createTicker((_) => setState(() {}));
    _start();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _ticker?.dispose();
    _pageController.dispose();
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
    final stories = controller.state.stories;
    if (_index < stories.length) {
      controller.markStoryViewed(stories[_index].id);
    }
    _paused = false;
    _watch
      ..reset()
      ..start();
    if (!_ticker!.isActive) _ticker!.start();
    _scheduleAdvance();
  }

  void _goTo(int index) {
    final count = ref.read(storyControllerProvider).state.stories.length;
    if (index < 0 || index >= count) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic);
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

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _watch.stop();
      _ticker?.stop();
      _advanceTimer?.cancel();
    } else {
      _watch.start();
      if (!_ticker!.isActive) _ticker!.start();
      _scheduleAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyControllerProvider).state;
    if (state.stories.isEmpty) {
      return const Scaffold(body: Center(child: Text('No stories yet')));
    }
    if (_index >= state.stories.length) _index = state.stories.length - 1;
    final story = state.stories[_index];
    final user = state.userById(story.userId);
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
              itemCount: state.stories.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                _start();
              },
              itemBuilder: (context, index) => _StoryMedia(
                story: state.stories[index],
                active: index == _index && !_paused,
              ),
            ),
            // Tap zones
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _previous,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .4,
                  child: GestureDetector(
                    onTap: _togglePause,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _next,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),
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
                            for (var i = 0; i < state.stories.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1.5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: i < _index
                                          ? 1
                                          : (i == _index ? _progressValue : 0),
                                      minHeight: 2.5,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: .35),
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
                        horizontal: 14, vertical: 12),
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
                                  Text(user?.username ?? 'unknown',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  if (user?.isVerified == true) ...[
                                    const SizedBox(width: 3),
                                    const Icon(Icons.verified,
                                        size: 13, color: AppColors.instagramBlue),
                                  ],
                                ],
                              ),
                              Text(Formatters.timeAgo(story.createdAt),
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: .7),
                                      fontSize: 11)),
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
                          horizontal: 20, vertical: 28),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(story.caption,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ),
                      ),
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
                      shape: BoxShape.circle),
                  child: const Icon(Icons.pause, color: Colors.white, size: 36),
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
      _video = VideoPlayerController.networkUrl(
          Uri.parse(widget.story.mediaUrl))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _video?.setLooping(true);
          if (widget.active) _video?.play();
        }).catchError((_) {});
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
                child: VideoPlayer(video)),
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
