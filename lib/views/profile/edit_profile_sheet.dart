import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/media_picker_service.dart';
import '../../core/utils/feedback.dart';
import '../widgets/app_image.dart';
import '../../data/dummy_data/dummy_data.dart';
import '../../models/user_model.dart';
import '../../controllers/profile_controller.dart';

void showEditProfileSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const EditProfileSheet(),
  );
}

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  late final TextEditingController _website;
  late String _image;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileControllerProvider).state.currentUser!;
    _username = TextEditingController(text: user.username);
    _displayName = TextEditingController(text: user.displayName);
    _bio = TextEditingController(text: user.bio);
    _website = TextEditingController(text: user.website);
    _image = user.profileImage;
  }

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _bio.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final path = await MediaPickerService.pickImage();
    if (path == null) {
      if (mounted) {
        FeedbackUtils.snack(context, 'Gallery unavailable — pick a sample below',
            isError: true);
      }
      return;
    }
    setState(() => _image = path);
  }

  Future<void> _save() async {
    if (_username.text.trim().length < 3) {
      FeedbackUtils.snack(context, 'Username must be at least 3 characters',
          isError: true);
      return;
    }
    final state = ref.read(profileControllerProvider).state;
    final existing = state.users.where(
        (u) => u.username.toLowerCase() == _username.text.trim().toLowerCase());
    final me = state.currentUser!;
    if (existing.any((u) => u.id != me.id)) {
      FeedbackUtils.snack(context, 'That username is already taken',
          isError: true);
      return;
    }
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    ref.read(profileControllerProvider).updateProfile(
          username: _username.text.trim(),
          displayName: _displayName.text.trim(),
          bio: _bio.text.trim(),
          website: _website.text.trim(),
          profileImage: _image,
        );
    Navigator.pop(context);
    FeedbackUtils.snack(context, 'Profile updated');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Edit profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Center(
                child: Stack(
                  children: [
                    ClipOval(
                      child: AppImage(url: _image, width: 86, height: 86),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: AppColors.instagramBlue,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = index == 0
                        ? ''
                        : AppDummyData.img('avatar${index - 1}', size: 200);
                    return GestureDetector(
                      onTap: index == 0 ? _pickFromGallery : null,
                      child: ClipOval(
                        child: index == 0
                            ? Container(
                                width: 52,
                                height: 52,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Icon(Icons.photo_camera),
                              )
                            : AppImage(url: url, width: 52, height: 52),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap the camera to use your gallery, or pick a sample.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              TextField(
                controller: _username,
                decoration: const InputDecoration(
                    labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(
                    labelText: 'Display name', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Bio', prefixIcon: Icon(Icons.edit_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _website,
                decoration: const InputDecoration(
                    labelText: 'Website', prefixIcon: Icon(Icons.link)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kept for type-safe references from other features.
typedef ProfileUser = UserModel;
