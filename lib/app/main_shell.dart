import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme/app_theme.dart';
import '../views/create_post/create_post_screen.dart';
import '../views/explore/explore_screen.dart';
import '../views/home/home_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/reels/reels_screen.dart';
import '../controllers/navigation_controller.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  int _index = 0;
  int _direction = 1;
  int _reelsInitialIndex = 0;
  int _reelsOpenCount = 0;

  /// Drives the short screen-in animation on every tab change.
  late final AnimationController _transition;

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.search_outlined, Icons.search, 'Search'),
    (Icons.add_box_outlined, Icons.add_box, 'Create'),
    (Icons.movie_outlined, Icons.movie, 'Reels'),
    (Icons.account_circle_outlined, Icons.account_circle, 'Profile'),
  ];

  void _select(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute<bool>(
          fullscreenDialog: true,
          builder: (_) => const CreatePostScreen(),
        ),
      );
      return;
    }
    setState(() {
      _direction = index > _index ? 1 : -1;
      _index = index;
    });
    _transition.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod only allows ref.listen during build, not in initState.
    ref.listen(navigationControllerProvider, (_, next) {
      final request = next.reelsOpenRequest;
      if (request == null) return;
      setState(() {
        _reelsInitialIndex = request;
        _reelsOpenCount++;
        if (_index != 3) {
          _direction = 1;
          _index = 3;
        }
      });
      _transition.forward(from: 0);
      ref.read(navigationControllerProvider).clearReelsRequest();
    });

    return Scaffold(
      body: AnimatedBuilder(
        animation: _transition,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_transition.value);
          return Transform.translate(
            offset: Offset(0, (1 - t) * 18 * _direction),
            child: Opacity(opacity: .25 + .75 * t, child: child),
          );
        },
        child: IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            const ExploreScreen(),
            const SizedBox.shrink(),
            ReelsScreen(
              key: ValueKey('$_reelsInitialIndex-$_reelsOpenCount'),
              initialIndex: _reelsInitialIndex,
              active: _index == 3,
            ),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: _AnimatedNavBar(
        items: _items,
        index: _index,
        onTap: _select,
        transition: _transition,
      ),
    );
  }
}

class _AnimatedNavBar extends StatelessWidget {
  final List<(IconData, IconData, String)> items;
  final int index;
  final ValueChanged<int> onTap;
  final Animation<double> transition;

  const _AnimatedNavBar({
    required this.items,
    required this.index,
    required this.onTap,
    required this.transition,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0B0B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .35 : .08),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtle Instagram-gradient accent line on top of the dock.
          Container(
            height: 2,
            decoration: const BoxDecoration(gradient: AppColors.storyGradient),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = constraints.maxWidth / items.length;
                  return SizedBox(
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedAlign(
                          alignment: Alignment(-1 + (index * 2 / 4), 0),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          child: AnimatedBuilder(
                            animation: transition,
                            builder: (context, child) => Transform.scale(
                              scale: 1 + (1 - transition.value) * .08,
                              child: child,
                            ),
                            child: Container(
                              width: cellWidth - 10,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.storyGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.instagramPink.withValues(
                                      alpha: .28,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                              foregroundDecoration: BoxDecoration(
                                color: scheme.surface.withValues(
                                  alpha: isDark ? .78 : .9,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(
                                child: i == 2
                                    ? _CreateButton(
                                        label: items[i].$3,
                                        onTap: () => onTap(i),
                                      )
                                    : _NavButton(
                                        outlined: items[i].$1,
                                        filled: items[i].$2,
                                        label: items[i].$3,
                                        selected: index == i,
                                        onTap: () => onTap(i),
                                      ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData outlined;
  final IconData filled;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.outlined,
    required this.filled,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: label,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: AnimatedScale(
          scale: selected ? 1.1 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Icon(
                  selected ? filled : outlined,
                  key: ValueKey(selected),
                  size: 25,
                  color: Color.lerp(
                    color.withValues(alpha: .55),
                    AppColors.instagramPink,
                    selected ? 1 : 0,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: selected ? 16 : 8,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.instagramPink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CreateButton({required this.label, required this.onTap});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? .86 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.instagramPink.withValues(alpha: .4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 26, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
