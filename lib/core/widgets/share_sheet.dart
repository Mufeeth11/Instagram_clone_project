import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/feedback.dart';
import '../../data/dummy_data/dummy_data.dart';
import '../../models/story_model.dart';
import '../../state/app_state.dart';
import 'app_image.dart';

Future<void> showShareSheet(
  BuildContext context, {
  required String itemId,
  String label = 'post',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShareSheet(itemId: itemId, label: label),
  );
}

class ShareSheet extends ConsumerWidget {
  final String itemId;
  final String label;

  const ShareSheet({super.key, required this.itemId, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final me = state.currentUser;
    final people = state.users
        .where((u) => u.id != me?.id && !state.blockedUsers.contains(u.id))
        .take(8)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Share $label',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: people.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final user = people[index];
                  return GestureDetector(
                    onTap: () {
                      final post = state.posts
                          .where((p) => p.id == itemId)
                          .firstOrNull;
                      final reel = state.reels
                          .where((r) => r.id == itemId)
                          .firstOrNull;
                      final title = post?.caption ?? reel?.caption ?? label;
                      ref.read(appProvider.notifier).sendMessage(
                            user.id,
                            'Shared a $label with you: $title',
                          );
                      Navigator.pop(context);
                      FeedbackUtils.snack(
                          context, 'Shared with @${user.username}');
                    },
                    child: Column(
                      children: [
                        ClipOval(
                          child: AppImage(
                              url: user.profileImage, width: 58, height: 58),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 64,
                          child: Text(
                            user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 24),
            _shareAction(
              context,
              icon: Icons.link,
              label: 'Copy link',
              onTap: () async {
                await FeedbackUtils.copy(
                    'https://local.instagram.demo/p/$itemId');
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  FeedbackUtils.snack(context, 'Link copied to clipboard');
                }
              },
            ),
            _shareAction(
              context,
              icon: Icons.bookmark_border,
              label: state.savedPosts.contains(itemId)
                  ? 'Remove from saved'
                  : 'Save locally',
              onTap: () {
                ref.read(appProvider.notifier).toggleSavePost(itemId);
                Navigator.pop(context);
                FeedbackUtils.snack(context, 'Saved to your collection');
              },
            ),
            _shareAction(
              context,
              icon: Icons.auto_awesome,
              label: 'Add to your story',
              onTap: () {
                final me = state.currentUser;
                if (me == null) return;
                final post = state.posts
                    .where((p) => p.id == itemId)
                    .firstOrNull;
                final reel = state.reels
                    .where((r) => r.id == itemId)
                    .firstOrNull;
                final media = post?.imageUrls.first ??
                    reel?.thumbnailUrl ??
                    AppDummyData.sampleImages.first;
                ref.read(appProvider.notifier).addStory(StoryModel(
                  id: 's_local_${DateTime.now().microsecondsSinceEpoch}',
                  userId: me.id,
                  mediaUrl: media,
                  caption: 'Shared a $label ✨',
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(context);
                FeedbackUtils.snack(context, 'Added to your story');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(icon, size: 20),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
