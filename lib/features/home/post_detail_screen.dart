import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/post_card.dart';
import '../../core/widgets/user_avatar.dart';
import '../../state/app_state.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final post = state.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: Text('This post is no longer available.')),
      );
    }
    final comments = state.commentsFor(postId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          PostCard(post: post),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Comments (${comments.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Be the first to comment.')),
            ),
          ...comments.map((comment) {
            final user = state.userById(comment.userId);
            return ListTile(
              leading: UserAvatar(
                  imageUrl: user?.profileImage ?? '', size: 38, viewed: true),
              title: Row(
                children: [
                  Text(user?.username ?? 'unknown',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(Formatters.timeAgo(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              subtitle: Text(comment.text),
            );
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
