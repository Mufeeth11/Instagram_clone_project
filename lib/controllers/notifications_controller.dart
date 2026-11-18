import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'base_controller.dart';

final notificationsControllerProvider = Provider<NotificationsController>(
  (ref) => NotificationsController(ref, ref.watch(appProvider)),
);

class NotificationsController extends AppController {
  const NotificationsController(super.ref, super.state);

  void markNotificationRead(String id) => actions.markNotificationRead(id);

  void markAllNotificationsRead() => actions.markAllNotificationsRead();

  void toggleFollow(String userId) => actions.toggleFollow(userId);
}