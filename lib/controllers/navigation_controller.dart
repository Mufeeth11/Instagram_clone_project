import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/navigation_state.dart';

final navigationControllerProvider = Provider<NavigationController>(
  (ref) => NavigationController(
    ref,
    ref.watch(reelsOpenRequestProvider),
  ),
);

class NavigationController {
  const NavigationController(this.ref, this.reelsOpenRequest);

  final Ref ref;
  final int? reelsOpenRequest;

  void openReels(int index) =>
      ref.read(reelsOpenRequestProvider.notifier).open(index);

  void clearReelsRequest() =>
      ref.read(reelsOpenRequestProvider.notifier).clear();
}