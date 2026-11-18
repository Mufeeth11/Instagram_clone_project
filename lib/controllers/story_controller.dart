import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_model.dart';
import '../state/app_state.dart';
import 'base_controller.dart';

final storyControllerProvider = Provider<StoryController>(
  (ref) => StoryController(ref, ref.watch(appProvider)),
);

class StoryController extends AppController {
  const StoryController(super.ref, super.state);

  void markStoryViewed(String id) => actions.markStoryViewed(id);

  void addStory(StoryModel story) => actions.addStory(story);
}