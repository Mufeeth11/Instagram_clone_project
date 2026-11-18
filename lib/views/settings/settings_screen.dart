import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/feedback.dart';
import '../widgets/user_avatar.dart';
import '../../controllers/settings_controller.dart';
import '../profile/edit_profile_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider).state;
    final me = state.currentUser;
    final controller = ref.read(settingsControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    void showInfo(String title, String body) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(body)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
    }

    void showThemeDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Appearance'),
          content: RadioGroup<ThemeMode>(
            groupValue: state.themeMode,
            onChanged: (value) {
              if (value == null) return;
              controller.setTheme(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in ThemeMode.values)
                  RadioListTile<ThemeMode>(
                    title: Text(mode == ThemeMode.system
                        ? 'System default'
                        : (mode == ThemeMode.light
                            ? 'Light mode'
                            : 'Dark mode')),
                    value: mode,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    void showPasswordDialog() {
      final current = TextEditingController();
      final next = TextEditingController();
      final confirm = TextEditingController();
      final formKey = GlobalKey<FormState>();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter current password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) => v != null && v.length >= 6
                      ? null
                      : 'At least 6 characters',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                  validator: (v) =>
                      v == next.text ? null : 'Passwords do not match',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final error = controller.changePassword(
                  current: current.text,
                  next: next.text,
                );
                Navigator.pop(context);
                FeedbackUtils.snack(
                    context,
                    error ?? 'Password updated',
                    isError: error != null);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    }

    void showBlockedSheet() {
      final blocked = state.blockedUsers.toList();
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Blocked users',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (blocked.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No blocked users.')),
                  ),
                ...blocked.map((id) {
                  final user = state.userById(id);
                  return ListTile(
                    leading: UserAvatar(
                        imageUrl: user?.profileImage ?? '', size: 40, viewed: true),
                    title: Text(user?.username ?? id),
                    trailing: TextButton(
                      onPressed: () =>
                          controller.toggleBlockedUser(id),
                      child: const Text('Unblock'),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    }

    void showChoiceDialog({
      required String title,
      required List<String> options,
      required String selected,
      required ValueChanged<String> onSelected,
    }) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (value) {
              if (value == null) return;
              onSelected(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  RadioListTile<String>(
                    title: Text(option),
                    value: option,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        children: [
          if (me != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  UserAvatar(imageUrl: me.profileImage, size: 54, viewed: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.displayName,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('@${me.username}',
                            style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _section(context, 'Account', [
            _tile(context, Icons.person_outline, 'Edit Profile',
                'Update your name, bio and photo', () {
              showEditProfileSheet(context);
            }),
            _tile(context, Icons.badge_outlined, 'Account Information',
                '@${me?.username ?? ''} · ${me?.email ?? ''}', () {
              showInfo(
                'Account information',
                'Username: ${me?.username}\nEmail: ${me?.email}\nType: Local demo account\nData is stored only on this device.',
              );
            }),
            _tile(context, Icons.lock_outline, 'Password', 'Change your password',
                showPasswordDialog),
            _tile(context, Icons.bookmark_border, 'Saved Posts',
                '${state.savedPosts.length} posts saved', () {
              context.push('/profile/${me?.id}', extra: 'saved');
            }),
            _tile(context, Icons.archive_outlined, 'Archive', 'Archived stories and posts',
                () {
              showInfo('Archive', 'Nothing is archived yet. This is a local demo.');
            }),
            _tile(context, Icons.history, 'Activity', 'Your recent notifications', () {
              context.push('/notifications');
            }),
          ]),
          _section(context, 'Preferences', [
            _tile(context, Icons.notifications_outlined, 'Notifications',
                'Push and activity alerts', null,
                trailing: Switch(
                  value: state.setting<bool>('notifications', true),
                  onChanged: (value) => controller.setSetting('notifications', value),
                )),
            _tile(context, Icons.dark_mode_outlined, 'Dark Mode',
                'Switch between light and dark', showThemeDialog),
            _tile(context, Icons.light_mode_outlined, 'Light Mode',
                'Use the light appearance', showThemeDialog),
            _tile(context, Icons.palette_outlined, 'Theme Settings',
                'Current: ${state.themeMode == ThemeMode.system ? 'System' : (state.themeMode == ThemeMode.light ? 'Light' : 'Dark')}',
                showThemeDialog),
            _tile(context, Icons.language, 'Language',
                state.setting<String>('language', 'English'), () {
              showChoiceDialog(
                title: 'Language',
                options: const [
                  'English',
                  'Sinhala',
                  'Tamil',
                  'Spanish',
                  'Japanese'
                ],
                selected: state.setting<String>('language', 'English'),
                onSelected: (value) {
                  controller.setSetting('language', value);
                  FeedbackUtils.snack(context, 'Language set to $value (demo)');
                },
              );
            }),
          ]),
          _section(context, 'Privacy', [
            _tile(context, Icons.lock_outline, 'Private Account',
                'Only approved followers can see your posts', null,
                trailing: Switch(
                  value: state.setting<bool>('privateAccount', false),
                  onChanged: (_) => controller.togglePrivateAccount(),
                )),
            _tile(context, Icons.block, 'Blocked Users',
                '${state.blockedUsers.length} blocked', showBlockedSheet),
            _tile(context, Icons.circle_outlined, 'Activity Status',
                'Show when you were last active', null,
                trailing: Switch(
                  value: state.setting<bool>('activityStatus', true),
                  onChanged: (value) =>
                      controller.setSetting('activityStatus', value),
                )),
            _tile(context, Icons.comment_outlined, 'Comment Controls',
                state.setting<String>('commentControls', 'Everyone'), () {
              showChoiceDialog(
                title: 'Who can comment?',
                options: const ['Everyone', 'Followers', 'Off'],
                selected: state.setting<String>('commentControls', 'Everyone'),
                onSelected: (value) =>
                    controller.setSetting('commentControls', value),
              );
            }),
          ]),
          _section(context, 'About', [
            _tile(context, Icons.info_outline, 'About App', 'Learn about this demo', () {
              showInfo(
                'About App',
                'An Instagram-inspired Flutter application with a fully local simulated backend. Built with Riverpod, GoRouter and SharedPreferences.',
              );
            }),
            _tile(context, Icons.privacy_tip_outlined, 'Privacy Policy',
                'How your local data is handled', () {
              showInfo(
                'Privacy Policy',
                'All data stays on your device. No account information is sent to a server. Images and sample videos are loaded from free public sources.',
              );
            }),
            _tile(context, Icons.description_outlined, 'Terms of Service',
                'Demo usage terms', () {
              showInfo(
                'Terms of Service',
                'This is a non-commercial demo project for learning and portfolio purposes. It is not affiliated with Instagram or Meta.',
              );
            }),
            const ListTile(
              leading: Icon(Icons.android),
              title: Text('App Version'),
              trailing: Text('1.0.0'),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log out?'),
                    content: const Text(
                        'You will be returned to the login screen. Your local data will be kept.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700),
                        onPressed: () {
                          Navigator.pop(context);
                          controller.logout();
                          context.go('/login');
                        },
                        child: const Text('Log out'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log out',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: Colors.red.shade300)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 6),
            child: Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          ...children,
          const Divider(),
        ],
      );

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
