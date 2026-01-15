import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/chat_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';

class MessageThreadPage extends StatefulWidget {
  final String channelId;
  final WorkspaceChannel? channel;
  final String? dmUserId;
  final String? dmUserName;
  final String? dmUserAvatar;
  const MessageThreadPage({super.key, required this.channelId, this.channel, this.dmUserId, this.dmUserName, this.dmUserAvatar});
  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final Map<String, DateTime> _typingUsers = {};
  Timer? _typingCleanup;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Typing indicator can be wired with Supabase Realtime in the future
  }

  @override
  void dispose() {
    _typingCleanup?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _subscribeTyping() {}

  void _scheduleTypingCleanup() {
    _typingCleanup?.cancel();
    _typingCleanup = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now();
      _typingUsers.removeWhere((_, ts) => now.difference(ts).inSeconds > 3);
      if (mounted) setState(() {});
    });
  }

  Future<void> _onSend() async {
    if (_input.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(channelId: widget.channelId, content: _input.text.trim());
      _input.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Send message error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onTyping() async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      final name = user?.email?.split('@').first ?? 'User';
      if (user != null) {
        await ChatService.sendTyping(widget.channelId, name: name, userId: user.id);
      }
    } catch (e) {
      debugPrint('Typing broadcast error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final isDM = widget.dmUserId != null;
    return SafeArea(
      child: Column(children: [
        _ThreadAppBar(channel: channel, dmUserName: widget.dmUserName, dmUserAvatar: widget.dmUserAvatar),
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: ChatService.streamMessages(widget.channelId),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? [];
              // auto-scroll when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              if (messages.isEmpty) {
                return const _EmptyThread();
              }
              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  itemCount: _itemCount(messages),
                  itemBuilder: (context, index) => _buildItem(context, index, messages),
                ),
              );
            },
          ),
        ),
        if (_typingUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_typingUsers.keys.first} is typing...',
                style: context.textStyles.labelSmall!.withColor(AppColors.textMuted),
              ),
            ),
          ),
        _Composer(
          controller: _input,
          hintLabel: isDM ? '@${widget.dmUserName ?? 'Direct'}' : '#${channel?.name ?? 'channel'}',
          onSend: _onSend,
          onChanged: (_) => _onTyping(),
          sending: _sending,
        ),
      ]),
    );
  }

  int _itemCount(List<Message> msgs) {
    // include date separators
    int count = 0;
    for (int i = 0; i < msgs.length; i++) {
      count++; // for the message
      if (i == 0) continue;
      final gap = msgs[i].sentAt.difference(msgs[i - 1].sentAt).inMinutes;
      if (gap > 5) count++; // separator
    }
    return count;
  }

  Widget _buildItem(BuildContext context, int index, List<Message> msgs) {
    int msgIndex = 0;
    for (int i = 0; i < msgs.length; i++) {
      if (i > 0) {
        final gap = msgs[i].sentAt.difference(msgs[i - 1].sentAt).inMinutes;
        if (gap > 5) {
          if (index == msgIndex) return _DateSeparator(date: msgs[i].sentAt);
          msgIndex++;
        }
      }
      if (index == msgIndex) return _MessageBubble(message: msgs[i]);
      msgIndex++;
    }
    return const SizedBox.shrink();
  }
}

class _ThreadAppBar extends StatelessWidget {
  final WorkspaceChannel? channel;
  final String? dmUserName;
  final String? dmUserAvatar;
  const _ThreadAppBar({this.channel, this.dmUserName, this.dmUserAvatar});
  @override
  Widget build(BuildContext context) {
    final isDM = dmUserName != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6))),
      ),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        const SizedBox(width: 8),
        if (isDM)
          CircleAvatar(radius: 18, backgroundImage: (dmUserAvatar != null && dmUserAvatar!.isNotEmpty) ? NetworkImage(dmUserAvatar!) : null, child: (dmUserAvatar == null || dmUserAvatar!.isEmpty) ? const Icon(Icons.person, color: AppColors.textPrimary) : null),
        if (isDM) const SizedBox(width: 10),
        Expanded(
          child: isDM
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dmUserName ?? 'Direct Message', style: context.textStyles.titleMedium?.semiBold, overflow: TextOverflow.ellipsis),
                  Text('Direct message', style: context.textStyles.bodySmall!.withColor(AppColors.textMuted)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('#${channel?.name ?? 'channel'}', style: context.textStyles.titleMedium?.semiBold, overflow: TextOverflow.ellipsis)),
                    if (channel?.isPrivate == true) const _PrivateBadge(),
                  ]),
                  if ((channel?.description ?? '').isNotEmpty)
                    Text(channel!.description!, style: context.textStyles.bodySmall!.withColor(AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
        ),
      ]),
    );
  }
}

class _PrivateBadge extends StatelessWidget {
  const _PrivateBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.lock, size: 14, color: AppColors.textMuted),
        SizedBox(width: 4),
        Text('Private', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.forum_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('No messages yet. Be the first to start the conversation!', style: context.textStyles.bodyMedium, textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          const Expanded(child: Divider(height: 1)),
          const SizedBox(width: 8),
          Text(_fmt(date), style: context.textStyles.labelSmall!.withColor(AppColors.textMuted)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(height: 1)),
        ]),
      );

  static String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  Color _nameColor(String name) {
    // Simple name hash to choose color from palette
    final hash = name.codeUnits.fold(0, (p, c) => p + c);
    final colors = [
      AppColors.indigo500,
      AppColors.teal500,
      AppColors.pink500,
      AppColors.violet500,
      AppColors.emerald500,
      AppColors.rose500,
      AppColors.fuchsia500,
      AppColors.amber500,
      AppColors.red500,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final me = SupabaseConfig.auth.currentUser?.id;
    final isMe = me == message.senderId;
    final bubbleColor = isMe
        ? Colors.white
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final border = Border.all(color: isMe ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.6));

    return GestureDetector(
      onLongPress: () => _showMessageMenu(context, message),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
          if (!isMe) _Avatar(name: message.senderName),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 4),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(message.senderName, style: context.textStyles.labelSmall!.withColor(_nameColor(message.senderName)).medium),
                    const SizedBox(width: 6),
                    Text(_fmtTime(message.sentAt), style: context.textStyles.labelSmall!.withColor(AppColors.textMuted)),
                  ]),
                ),
              Container(
                decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(20), border: border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText(message.content, style: context.textStyles.bodyMedium),
                  if (message.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(children: message.attachments.map((a) => _AttachmentRow(att: a)).toList()),
                  ],
                  if (message.editedAt != null) ...[
                    const SizedBox(height: 6),
                    Text('Edited', style: context.textStyles.labelSmall!.withColor(AppColors.textMuted)),
                  ],
                ]),
              ),
            ]),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) _Avatar(name: message.senderName, isMe: true),
        ]),
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $am';
  }

  void _showMessageMenu(BuildContext context, Message msg) async {
    final box = context.findRenderObject() as RenderBox?;
    final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx + 50, pos.dy + 50, 0, 0),
      items: const [
        PopupMenuItem(value: 'copy', child: Text('Copy')),
      ],
    );
    if (selected == 'copy') {
      await Clipboard.setData(ClipboardData(text: msg.content));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
      }
    }
  }
}

class _AttachmentRow extends StatelessWidget {
  final MessageAttachment att;
  const _AttachmentRow({required this.att});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.only(top: 6),
      child: Row(children: [
        const Icon(Icons.attach_file, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(att.filename, style: context.textStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Text(_humanSize(att.size), style: context.textStyles.labelSmall!.withColor(AppColors.textMuted)),
      ]),
    );
  }

  static String _humanSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isMe;
  const _Avatar({required this.name, this.isMe = false});

  Color _color(String s) {
    final hash = s.codeUnits.fold(0, (p, c) => p + c);
    final colors = [
      AppColors.indigo500,
      AppColors.teal500,
      AppColors.pink500,
      AppColors.violet500,
      AppColors.emerald500,
      AppColors.rose500,
      AppColors.fuchsia500,
      AppColors.amber500,
      AppColors.red500,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      CircleAvatar(radius: 16, backgroundColor: _color(name).withValues(alpha: 0.15), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.textPrimary))),
      Positioned(right: -1, bottom: -1, child: Icon(Icons.circle, size: 10, color: isMe ? AppColors.success : Colors.grey)),
    ]);
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hintLabel;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged;
  final bool sending;

  const _Composer({
    required this.controller,
    required this.hintLabel,
    required this.onSend,
    this.onChanged,
    this.sending = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6))),
        ),
        child: Row(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file, color: AppColors.textMuted)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(hintText: 'Message $hintLabel...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)))),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          sending
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  onPressed: controller.text.trim().isEmpty ? null : onSend,
                  icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.primary),
                ),
        ]),
      ),
    );
  }
}
