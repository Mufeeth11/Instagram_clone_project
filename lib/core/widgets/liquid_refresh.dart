import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../app/theme/app_theme.dart';

/// App-wide liquid pull-to-refresh wrapper.
///
/// Keeps each screen's existing scroll behaviour and only adds the visual
/// liquid refresh gesture on top of it.
class LiquidRefresh extends StatelessWidget {
  const LiquidRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  /// A visual-only refresh for screens that do not need to change data.
  static Future<void> simple() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LiquidPullToRefresh(
      onRefresh: onRefresh,
      color: AppColors.instagramBlue,
      backgroundColor: scheme.surfaceContainerHighest,
      height: 90,
      springAnimationDurationInMilliseconds: 900,
      showChildOpacityTransition: false,
      animSpeedFactor: 1.1,
      child: child,
    );
  }
}