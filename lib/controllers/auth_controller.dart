import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'base_controller.dart';

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref, ref.watch(appProvider)),
);

class AuthController extends AppController {
  const AuthController(super.ref, super.state);

  String? login(String identifier, String password) =>
      actions.login(identifier, password);

  void demoLogin() => actions.demoLogin();

  String? signUp({
    required String username,
    required String email,
    required String password,
  }) =>
      actions.signUp(username: username, email: email, password: password);

  void logout() => actions.logout();

  String? changePassword({required String current, required String next}) =>
      actions.changePassword(current: current, next: next);
}