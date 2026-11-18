import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network / local-file image with a consistent placeholder and error state.
class AppImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = errorWidget ??
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(Icons.image_not_supported_outlined,
              size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant),
        );
    if (url.startsWith('/') || url.startsWith('file://')) {
      return Image.file(
        File(url.replaceFirst('file://', '')),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .35),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, _, _) => fallback,
      fadeInDuration: const Duration(milliseconds: 180),
    );
  }
}
