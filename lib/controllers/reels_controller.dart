import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reel_model.dart';
import '../state/app_state.dart';
import '../state/navigation_state.dart';
import 'base_controller.dart';

final reelsControllerProvider = Provider<ReelsController>(
  (ref) => ReelsController(ref, ref.watch(appProvider)),
);

class ReelsController extends AppController {
  const ReelsController(super.ref, super.state);

  void addReel(ReelModel reel) => actions.addReel(reel);

  void toggleLikeReel(String id) => actions.toggleLikeReel(id);

  void toggleSaveReel(String id) => actions.toggleSaveReel(id);

  void toggleFollow(String userId) => actions.toggleFollow(userId);

  void openReels(int index) =>
      ref.read(reelsOpenRequestProvider.notifier).open(index);
}