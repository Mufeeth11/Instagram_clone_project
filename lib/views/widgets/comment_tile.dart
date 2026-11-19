import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../../controllers/feed_controller.dart';
import '../../models/comment_model.dart';
import '../../state/app_state.dart';
import 'app_image.dart';

/// A comment plus the reply context needed to render it in a thread.
class CommentThreadItem {
  final CommentModel comment;
  final bool isReply;
  final String? replyToUsername;

  const CommentThreadItem({
    required this.comment,
    required this.isReply,
    this.replyToUsername,
  });
}

/// Flattens top-level comments and all of their replies into display order.
List<CommentThreadItem> buildCommentThread(AppState state, String targetId) {
  final items = <CommentThreadItem>[];
  for (final root in state.rootCommentsFor(targetId)) {
    items.add(CommentThreadItem(comment: root, isReply: false));
    for (final reply in state.repliesForRoot(targetId, root.id)) {
      final parentId = reply.parentId;
      final parent = parentId == null ? null : state.commentById(parentId);
      items.add(
        CommentThreadItem(
          comment: reply,
          isReply: true,
          replyToUsername: parent == null
              ? null
              : state.userById(parent.userId)?.username,
        ),
      );
    }
  }
  return items;
}

class CommentTile extends ConsumerWidget {
  final CommentModel comment;
  final bool isReply;
  final String? replyToUsername;
  final VoidCallback? onReply;
  final VoidCallback? onDeleted;

  const CommentTile({
    super.key,
    required this.comment,
    this.isReply = false,
    this.replyToUsername,
    this.onReply,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedControllerProvider).state;
    final user = state.userById(comment.userId);
    final me = state.currentUser;
    final liked = state.likedComments.contains(comment.id);
    final likeCount = state.effectiveCommentLikeCount(comment);
    final scheme = Theme.of(context).colorScheme;
    final avatarSize = isReply ? 28.0 : 34.0;

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 44 : 0, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: AppImage(
              url: user?.profileImage ?? '',
              width: avatarSize,
              height: avatarSize,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.username ?? 'unknown',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isReply ? 12 : 13,
                        ),
                      ),
                    ),
                    if (user?.isVerified == true) ...[
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.verified,
                        size: 13,
                        color: AppColors.instagramBlue,
                      ),
                    ],
                  ],
                ),
                if (replyToUsername != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Replying to @$replyToUsername',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(comment.text, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Formatters.timeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (onReply != null) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (me?.id == comment.userId) ...[
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(feedControllerProvider)
                              .deleteComment(comment.id);
                          FeedbackUtils.snack(context, 'Comment deleted');
                          onDeleted?.call();
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            children: [
              IconButton(
                onPressed: () {
                  ref
                      .read(feedControllerProvider)
                      .toggleLikeComment(comment.id);
                  FeedbackUtils.tap();
                },
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: liked ? AppColors.likeRed : scheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (likeCount > 0)
                Text(
                  Formatters.count(likeCount),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
