import 'package:flutter/material.dart';

import '../../core/widgets/app_image.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  /// When provided, the tapped post image zooms into this viewer instead of
  /// using the plain route transition.
  final String? heroId;

  const FullScreenImageViewer({
    super.key,
    required this.urls,
    this.initialIndex = 0,
    this.heroId,
  });

  /// Shared tag used by the feed card and the viewer for the same image.
  static String heroTag(String heroId, int index) =>
      'post-image-$heroId-$index';

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} of ${widget.urls.length}'),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final image = AppImage(
                url: widget.urls[index],
                fit: BoxFit.contain,
                errorWidget: const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 60,
                ),
              );
              final viewerImage = widget.heroId != null
                  ? Hero(
                      tag: FullScreenImageViewer.heroTag(widget.heroId!, index),
                      child: image,
                    )
                  : image;
              return InteractiveViewer(
                minScale: .8,
                maxScale: 4,
                child: Center(child: viewerImage),
              );
            },
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.urls.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: .4),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
