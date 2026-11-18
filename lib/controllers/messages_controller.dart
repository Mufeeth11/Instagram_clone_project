import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'base_controller.dart';

final messagesControllerProvider = Provider<MessagesController>(
  (ref) => MessagesController(ref, ref.watch(appProvider)),
);

class MessagesController extends AppController {
  const MessagesController(super.ref, super.state);

  void sendMessage(String threadUserId, String text) =>
      actions.sendMessage(threadUserId, text);
}