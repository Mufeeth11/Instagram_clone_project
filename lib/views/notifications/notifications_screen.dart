import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../../controllers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider).state;
    final notifications = state.visibleNotifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(notificationsControllerProvider)
                  .markAllNotificationsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')));
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none, title: 'No notifications yet')
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final user = state.userById(notification.userId);
                final icon = notification.type == 'like'
                    ? Icons.favorite
                    : (notification.type == 'comment'
                        ? Icons.mode_comment
                        : (notification.type == 'follow'
                            ? Icons.person_add
                            : Icons.attractions));
                return ListTile(
                  leading: Stack(
                    children: [
                      UserAvatar(
                          imageUrl: user?.profileImage ?? '', size: 44, viewed: true),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 13),
                      children: [
                        TextSpan(
                            text: user?.username ?? 'unknown',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' ${notification.text}'),
                      ],
                    ),
                  ),
                  subtitle: Text(Formatters.timeAgo(notification.createdAt),
                      style: const TextStyle(fontSize: 11)),
                  trailing: notification.type == 'follow' &&
                          user != null &&
                          user.id != state.currentUserId
                      ? TextButton(
                          onPressed: () => ref
                              .read(notificationsControllerProvider)
                              .toggleFollow(user.id),
                          child: Text(state.isFollowing(user.id)
                              ? 'Following'
                              : 'Follow back'),
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(notificationsControllerProvider)
                        .markNotificationRead(notification.id);
                    context.push('/profile/${notification.userId}');
                  },
                );
              },
            ),
    );
  }
}
