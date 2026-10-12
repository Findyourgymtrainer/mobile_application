import 'package:flutter/material.dart';

import '../app_state.dart';
import 'common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read after the first frame so the unread badge updates safely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).markNoticesRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notices = AppScope.of(context).myNotices;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notices.isEmpty
          ? const EmptyState(Icons.notifications_none, 'No notifications yet.\nBooking updates and messages show up here.')
          : ListView.separated(
              itemCount: notices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.notifications_outlined)),
                title: Text(notices[i].text),
                subtitle: Text('${fmtDate(notices[i].at)}, ${fmtTime(notices[i].at)}'),
              ),
            ),
    );
  }
}

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final partners = app.conversationPartners();
    final me = app.currentUserId!;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: partners.isEmpty
          ? const EmptyState(Icons.chat_bubble_outline, 'No conversations yet.\nOpen a trainer profile and tap Message.')
          : ListView.separated(
              itemCount: partners.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final other = partners[i];
                final last = app.thread(me, other).last;
                return ListTile(
                  leading: Avatar(app.nameOf(other)),
                  title: Text(app.nameOf(other)),
                  subtitle: Text(last.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherId: other))),
                );
              },
            ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String otherId;

  const ChatScreen({super.key, required this.otherId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (_text.text.trim().isEmpty) return;
    AppScope.of(context).sendMessage(widget.otherId, _text.text);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.currentUserId!;
    final msgs = app.thread(me, widget.otherId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Row(children: [Avatar(app.nameOf(widget.otherId), radius: 16), const SizedBox(width: 10), Text(app.nameOf(widget.otherId))])),
      body: Column(children: [
        Expanded(
          child: msgs.isEmpty
              ? const EmptyState(Icons.waving_hand_outlined, 'Say hello and ask about availability or programs.')
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.fromId == me;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(m.text, style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface)),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Type a message', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
