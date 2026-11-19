import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/comment_sheet.dart';
import '../widgets/comment_tile.dart';
import '../widgets/post_card.dart';
import '../../controllers/feed_controller.dart';

class PostDetailScreen extends ConsumerWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedControllerProvider).state;
    final post = state.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null || state.isBlocked(post.userId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: Text('This post is no longer available.')),
      );
    }
    final comments = buildCommentThread(state, postId);
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
          ...comments.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CommentTile(
                comment: entry.comment,
                isReply: entry.isReply,
                replyToUsername: entry.replyToUsername,
                onReply: () => showCommentSheet(
                  context,
                  targetId: postId,
                  targetType: 'post',
                  replyTo: entry.comment,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
