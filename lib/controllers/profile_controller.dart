import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'base_controller.dart';

final profileControllerProvider = Provider<ProfileController>(
  (ref) => ProfileController(ref, ref.watch(appProvider)),
);

class ProfileController extends AppController {
  const ProfileController(super.ref, super.state);

  void updateProfile({
    String? username,
    String? displayName,
    String? bio,
    String? website,
    String? profileImage,
  }) =>
      actions.updateProfile(
        username: username,
        displayName: displayName,
        bio: bio,
        website: website,
        profileImage: profileImage,
      );

  void toggleFollow(String userId) => actions.toggleFollow(userId);

  void toggleBlockedUser(String userId) => actions.toggleBlockedUser(userId);
}