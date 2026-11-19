import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_avatar.dart';
import '../../controllers/messages_controller.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final String? initialUserId;

  const MessagesScreen({super.key, this.initialUserId});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String? _thread;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _thread = widget.initialUserId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    final thread = _thread;
    if (text.isEmpty || thread == null) return;
    if (ref.read(messagesControllerProvider).state.isBlocked(thread)) return;
    ref.read(messagesControllerProvider).sendMessage(thread, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesControllerProvider).state;
    final me = state.currentUser;
    final threads = <String>{
      ...state.chatMessages.map((m) => m.threadUserId),
      ...state.chatMessages.where((m) => m.senderId == me?.id).map((m) => m.threadUserId),
      for (var i = 1; i <= 6; i++) 'u$i',
    }.where((id) => !state.isBlocked(id)).toList();
    final thread = _thread != null && !state.isBlocked(_thread!)
        ? _thread
        : null;

    if (thread != null) {
      final other = state.userById(thread);
      final messages = state.chatMessages
          .where((m) =>
              (m.threadUserId == thread && m.senderId == me?.id) ||
              (m.threadUserId == me?.id && m.senderId == thread))
          .toList();
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _thread = null)),
          title: Row(
            children: [
              UserAvatar(imageUrl: other?.profileImage ?? '', size: 34, viewed: true),
              const SizedBox(width: 10),
              Text(other?.username ?? 'Conversation'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Start the conversation',
                      message: 'Say hi to @${other?.username ?? ''} 👋')
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = message.senderId == me?.id;
                        return Row(
                          mainAxisAlignment: mine
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * .72),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppColors.instagramBlue
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                    color: mine
                                        ? Colors.white
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
                left: 12,
                right: 12,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.instagramBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView.separated(
        itemCount: threads.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = state.userById(threads[index]);
          final last = state.chatMessages
              .where((m) =>
                  (m.threadUserId == threads[index] && m.senderId == me?.id) ||
                  (m.threadUserId == me?.id && m.senderId == threads[index]))
              .toList();
          return ListTile(
            leading: UserAvatar(
                imageUrl: user?.profileImage ?? '', size: 46, viewed: true),
            title: Text(user?.username ?? 'Unknown',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: Text(
              last.isEmpty ? 'Tap to start chatting' : last.last.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            trailing: last.isEmpty
                ? null
                : Text(Formatters.timeAgo(last.last.createdAt),
                    style: const TextStyle(fontSize: 10)),
            onTap: () => setState(() => _thread = threads[index]),
          );
        },
      ),
    );
  }
}
