import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/post_model.dart';
import '../state/app_state.dart';
import 'base_controller.dart';

final feedControllerProvider = Provider<FeedController>(
  (ref) => FeedController(ref, ref.watch(appProvider)),
);

class FeedController extends AppController {
  const FeedController(super.ref, super.state);

  void addPost(PostModel post) => actions.addPost(post);

  void toggleLikePost(String id) => actions.toggleLikePost(id);

  void toggleSavePost(String id) => actions.toggleSavePost(id);

  void addComment({
    required String targetId,
    required String targetType,
    required String text,
  }) =>
      actions.addComment(
        targetId: targetId,
        targetType: targetType,
        text: text,
      );

  void deleteComment(String id) => actions.deleteComment(id);

  void toggleFollow(String userId) => actions.toggleFollow(userId);
}