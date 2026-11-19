import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/feedback.dart';
import '../../controllers/feed_controller.dart';
import '../../models/comment_model.dart';
import 'app_image.dart';
import 'comment_tile.dart';

Future<void> showCommentSheet(
  BuildContext context, {
  required String targetId,
  required String targetType,
  CommentModel? replyTo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentSheet(
      targetId: targetId,
      targetType: targetType,
      replyTo: replyTo,
    ),
  );
}

class CommentSheet extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;
  final CommentModel? replyTo;

  const CommentSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    this.replyTo,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  CommentModel? _replyTo;

  @override
  void initState() {
    super.initState();
    _replyTo = widget.replyTo;
    if (_replyTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final state = ref.read(feedControllerProvider).state;
    final replyTo = _replyTo != null && state.commentById(_replyTo!.id) != null
        ? _replyTo
        : null;
    ref
        .read(feedControllerProvider)
        .addComment(
          targetId: widget.targetId,
          targetType: widget.targetType,
          text: text,
          parentId: replyTo?.id,
        );
    _controller.clear();
    if (mounted) setState(() => _replyTo = null);
    FeedbackUtils.tap();
    _focusNode.unfocus();
  }

  void _startReply(CommentModel comment) {
    setState(() => _replyTo = comment);
    _focusNode.requestFocus();
    FeedbackUtils.tap();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedControllerProvider).state;
    final entries = buildCommentThread(state, widget.targetId);
    final commentCount = state.commentCountFor(widget.targetId);
    final scheme = Theme.of(context).colorScheme;
    final me = state.currentUser;
    final replyUser = _replyTo == null
        ? null
        : state.userById(_replyTo!.userId);

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
                '$commentCount comments',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('No comments yet. Start the conversation!'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return CommentTile(
                          comment: entry.comment,
                          isReply: entry.isReply,
                          replyToUsername: entry.replyToUsername,
                          onReply: () => _startReply(entry.comment),
                          onDeleted: () {
                            if (_replyTo?.id == entry.comment.id) {
                              setState(() => _replyTo = null);
                            }
                          },
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            if (_replyTo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Replying to @${replyUser?.username ?? 'unknown'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _replyTo = null),
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (me != null)
                    ClipOval(
                      child: AppImage(
                        url: me.profileImage,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: _replyTo == null
                            ? 'Add a comment...'
                            : 'Reply to @${replyUser?.username ?? 'unknown'}...',
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  TextButton(onPressed: _submit, child: const Text('Post')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
