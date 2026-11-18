import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../state/navigation_state.dart';
import 'base_controller.dart';

final exploreControllerProvider = Provider<ExploreController>(
  (ref) => ExploreController(ref, ref.watch(appProvider)),
);

class ExploreController extends AppController {
  const ExploreController(super.ref, super.state);

  void addSearch(String query) => actions.addSearch(query);

  void clearSearchHistory() => actions.clearSearchHistory();

  void toggleFollow(String userId) => actions.toggleFollow(userId);

  void openFirstReel() {
    if (state.reels.isEmpty) return;
    ref.read(reelsOpenRequestProvider.notifier).open(0);
  }
}