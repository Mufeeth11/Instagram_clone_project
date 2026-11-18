import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';

/// Base for every MVC controller. Holds the current immutable model state and
/// delegates writes to the existing persisted notifier.
abstract class AppController {
  const AppController(this.ref, this.state);

  final Ref ref;
  final AppState state;

  AppNotifier get actions => ref.read(appProvider.notifier);

  bool get isLoggedIn => state.isLoggedIn;
}