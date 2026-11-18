import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'app_image.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool hasStory;
  final bool viewed;
  final VoidCallback? onTap;
  final IconData? badgeIcon;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.hasStory = false,
    this.viewed = false,
    this.onTap,
    this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final ring = hasStory
        ? BoxDecoration(
            shape: BoxShape.circle,
            gradient: viewed
                ? LinearGradient(colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade600,
                  ])
                : AppColors.storyGradient,
          )
        : BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2.2),
        decoration: ring,
        child: Container(
          padding: hasStory ? const EdgeInsets.all(2) : EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Stack(
            children: [
              ClipOval(
                child: AppImage(
                  url: imageUrl,
                  width: size,
                  height: size,
                ),
              ),
              if (badgeIcon != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.instagramBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(badgeIcon, size: size * .26, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(
        Icons.verified,
        size: size,
        color: AppColors.instagramBlue,
      );
}
