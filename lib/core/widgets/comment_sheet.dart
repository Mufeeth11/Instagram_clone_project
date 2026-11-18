import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/feedback.dart';
import '../../core/utils/formatters.dart';
import '../../state/app_state.dart';
import 'app_image.dart';

Future<void> showCommentSheet(
  BuildContext context, {
  required String targetId,
  required String targetType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentSheet(targetId: targetId, targetType: targetType),
  );
}

class CommentSheet extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;

  const CommentSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(appProvider.notifier).addComment(
          targetId: widget.targetId,
          targetType: widget.targetType,
          text: text,
        );
    _controller.clear();
    FeedbackUtils.tap();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final comments = state.commentsFor(widget.targetId);
    final scheme = Theme.of(context).colorScheme;
    final me = state.currentUser;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * .72,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '${comments.length} comments',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: comments.isEmpty
                  ? const Center(
                      child: Text('No comments yet. Start the conversation!'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final user = state.userById(comment.userId);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipOval(
                                child: AppImage(
                                  url: user?.profileImage ?? '',
                                  width: 34,
                                  height: 34,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user?.username ?? 'unknown',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          Formatters.timeAgo(comment.createdAt),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: scheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(comment.text,
                                        style: const TextStyle(fontSize: 13)),
                                    if (comment.likeCount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${comment.likeCount} likes',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (me?.id == comment.userId)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  onPressed: () {
                                    ref
                                        .read(appProvider.notifier)
                                        .deleteComment(comment.id);
                                    FeedbackUtils.snack(
                                        context, 'Comment deleted');
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (me != null)
                    ClipOval(
                      child: AppImage(
                          url: me.profileImage, width: 32, height: 32),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  TextButton(
                    onPressed: _submit,
                    child: const Text('Post'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
