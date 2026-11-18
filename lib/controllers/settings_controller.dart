import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'base_controller.dart';

final settingsControllerProvider = Provider<SettingsController>(
  (ref) => SettingsController(ref, ref.watch(appProvider)),
);

class SettingsController extends AppController {
  const SettingsController(super.ref, super.state);

  void setTheme(ThemeMode mode) => actions.setTheme(mode);

  void setSetting(String key, dynamic value) =>
      actions.setSetting(key, value);

  void togglePrivateAccount() => actions.togglePrivateAccount();

  void toggleBlockedUser(String userId) => actions.toggleBlockedUser(userId);

  String? changePassword({required String current, required String next}) =>
      actions.changePassword(current: current, next: next);

  void logout() => actions.logout();
}