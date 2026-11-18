import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set when a screen wants the shell to open the Reels tab.
/// The value is the reel index to show; null means no pending request.
final reelsOpenRequestProvider =
    NotifierProvider<ReelsOpenRequestNotifier, int?>(
      ReelsOpenRequestNotifier.new,
    );

class ReelsOpenRequestNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void open(int index) => state = index;

  void clear() => state = null;
}
