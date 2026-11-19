import 'dart:async';

import 'package:video_player/video_player.dart';

/// Keeps the next reel's video controller initialised so the following page
/// can start playing without the usual network/decoder delay.
class ReelVideoPreloader {
  ReelVideoPreloader._();

  static final Map<String, _PreloadEntry> _entries = {};

  static Future<void> preload(String url) {
    if (url.isEmpty || _entries.containsKey(url)) return Future<void>.value();

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    final entry = _PreloadEntry(controller);
    _entries[url] = entry;

    entry.ready = controller.initialize().then((_) => true).catchError((
      Object _,
    ) {
      if (_entries.remove(url) == entry) {
        controller.dispose();
      }
      return false;
    });

    // If the user never reaches this reel, release the controller eventually.
    Timer(const Duration(seconds: 30), () {
      if (_entries.remove(url) == entry) {
        entry.ready?.then((ok) {
          if (ok) controller.dispose();
        });
      }
    });

    return entry.ready!.then((_) {});
  }

  /// Takes ownership of a preloaded controller. The caller must dispose it.
  static Future<VideoPlayerController?> take(String url) async {
    final entry = _entries.remove(url);
    if (entry == null) return null;
    final ok = await (entry.ready ?? Future<bool>.value(false));
    if (!ok) return null;
    return entry.controller;
  }
}

class _PreloadEntry {
  _PreloadEntry(this.controller);

  final VideoPlayerController controller;
  Future<bool>? ready;
}
