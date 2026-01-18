import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/chat_service.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/icon_mappings.dart';
import 'package:thittam1hub/widgets/enhanced_empty_state.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  List<WorkspaceChannel> _channels = [];
  Map<String, Message?> _last = {};
  List<DMThread> _dmThreads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final channels = await ChatService.getMyChannels();
      final last = await ChatService.getLastMessages(channels.map((e) => e.id).toList());
      final dms = await ChatService.getMyDMThreads();
      if (mounted) setState(() {
        _channels = channels;
        _last = last;
        _dmThreads = dms;
      });
    } catch (e) {
      debugPrint('ChatPage load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<WorkspaceChannel> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _channels;
    return _channels.where((c) => c.name.toLowerCase().contains(q) || (c.description ?? '').toLowerCase().contains(q)).toList();
  }

  Map<ChannelType, List<WorkspaceChannel>> _grouped(List<WorkspaceChannel> items) {
    final map = {
      ChannelType.ANNOUNCEMENT: <WorkspaceChannel>[],
      ChannelType.GENERAL: <WorkspaceChannel>[],
      ChannelType.ROLE_BASED: <WorkspaceChannel>[],
      ChannelType.TASK_SPECIFIC: <WorkspaceChannel>[],
    };
    for (final c in items) {
      map[c.type]?.add(c);
    }
    // stable sort by name
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped(_filtered);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              expandedHeight: AppLayout.appBarHeight,
              toolbarHeight: AppLayout.toolbarHeight,
              automaticallyImplyLeading: false,
              title: Text('Messages', style: context.textStyles.titleLarge),
              actions: [
                IconButton(
                  tooltip: 'New Message',
                  onPressed: () => context.push('/chat/new'),
                  icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                ),
              ],
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _SearchBar(controller: _search, onChanged: (_) => setState(() {})),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_channels.isEmpty && _dmThreads.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onTap: _load),
              )
            else
              SliverList.list(children: [
                _DMSection(threads: _dmThreads),
                _ChannelGroup(title: '📢 ANNOUNCEMENTS', items: groups[ChannelType.ANNOUNCEMENT]!, last: _last),
                _ChannelGroup(title: '💬 GENERAL', items: groups[ChannelType.GENERAL]!, last: _last),
                _ChannelGroup(title: '👥 ROLE_BASED', items: groups[ChannelType.ROLE_BASED]!, last: _last),
                _ChannelGroup(title: '📋 TASK_SPECIFIC', items: groups[ChannelType.TASK_SPECIFIC]!, last: _last),
              ]),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        const Icon(Icons.search, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search conversations...',
              border: InputBorder.none,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ChannelGroup extends StatelessWidget {
  final String title;
  final List<WorkspaceChannel> items;
  final Map<String, Message?> last;
  const _ChannelGroup({required this.title, required this.items, required this.last});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Text(title, style: context.textStyles.labelLarge!.withColor(AppColors.textMuted)),
        ),
        ...items.map((c) => _ChannelTile(channel: c, last: last[c.id])),
      ]),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final WorkspaceChannel channel;
  final Message? last;
  const _ChannelTile({required this.channel, required this.last});

  IconData get _icon => switch (channel.type) {
        ChannelType.ANNOUNCEMENT => Icons.campaign_outlined,
        ChannelType.GENERAL => Icons.forum_outlined,
        ChannelType.ROLE_BASED => Icons.groups_outlined,
        ChannelType.TASK_SPECIFIC => Icons.checklist_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final subtitle = channel.description ?? (last?.content ?? '');
    final ts = last?.sentAt;
    final time = ts != null ? _formatTime(ts) : '';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.push('/chat/${channel.id}', extra: channel),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), child: Icon(_icon, color: Theme.of(context).colorScheme.primary)),
            if (channel.isPrivate)
              const Positioned(right: -2, bottom: -2, child: Icon(Icons.lock, size: 14, color: AppColors.textMuted)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('#${channel.name}', style: context.textStyles.titleMedium?.semiBold, overflow: TextOverflow.ellipsis)),
                if (time.isNotEmpty) Text(time, style: context.textStyles.labelSmall!.withColor(AppColors.textMuted)),
              ]),
              const SizedBox(height: 4),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall!.withColor(AppColors.textMuted)),
            ]),
          ),
          // Unread badge placeholder (only show if >0)
          // const SizedBox(width: 8),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final am = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $am';
    }
    return '${dt.month}/${dt.day}/${dt.year % 100}';
  }
}

class _DMSection extends StatelessWidget {
  final List<DMThread> threads;
  const _DMSection({required this.threads});

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Text('👤 Direct Messages', style: context.textStyles.labelLarge!.withColor(AppColors.textMuted)),
        ),
        ...threads.map((t) => _DMTile(thread: t)),
      ]),
    );
  }
}

class _DMTile extends StatelessWidget {
  final DMThread thread;
  const _DMTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final last = thread.lastMessage;
    final time = last != null ? _formatTime(last.sentAt) : '';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.push('/chat/${thread.channelId}', extra: {
        'dmUserId': thread.partnerUserId,
        'dmUserName': thread.partnerName,
        'dmUserAvatar': thread.partnerAvatar,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: (thread.partnerAvatar != null && thread.partnerAvatar!.isNotEmpty) ? NetworkImage(thread.partnerAvatar!) : null,
            child: (thread.partnerAvatar == null || thread.partnerAvatar!.isEmpty) ? const Icon(Icons.person, color: AppColors.textPrimary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(thread.partnerName, style: context.textStyles.titleMedium?.semiBold, overflow: TextOverflow.ellipsis)),
                if (time.isNotEmpty) Text(time, style: context.textStyles.labelSmall!.withColor(AppColors.textMuted)),
              ]),
              const SizedBox(height: 4),
              Text(last?.content ?? 'Start a conversation', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall!.withColor(AppColors.textMuted)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final am = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $am';
    }
    return '${dt.month}/${dt.day}/${dt.year % 100}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyState(
      icon: EmptyStateConfig.messages.icon,
      title: EmptyStateConfig.messages.title,
      subtitle: 'Start by joining a workspace channel',
      primaryButtonLabel: 'New Message',
      primaryButtonIcon: Icons.chat_rounded,
      onPrimaryAction: () {
        HapticFeedback.lightImpact();
        context.push('/chat/new');
      },
      secondaryButtonLabel: 'Refresh',
      onSecondaryAction: onTap,
    );
  }
}
