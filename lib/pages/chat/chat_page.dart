import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/chat_group.dart';
import 'package:thittam1hub/services/chat_service.dart';
import 'package:thittam1hub/services/group_chat_service.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/enhanced_empty_state.dart';
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';
import 'package:thittam1hub/widgets/chat_shimmer.dart';
import 'package:thittam1hub/widgets/unread_badge.dart';
import 'create_group_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  List<WorkspaceChannel> _channels = [];
  Map<String, Message?> _last = {};
  List<DMThread> _dmThreads = [];
  List<ChatGroup> _groups = [];
  Map<String, int> _unreadCounts = {};

  final _groupService = GroupChatService();
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _load();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final channels = await ChatService.getMyChannels();
      final last = await ChatService.getLastMessages(channels.map((e) => e.id).toList());
      final dms = await ChatService.getMyDMThreads();
      final groups = await _groupService.getMyGroups();
      
      // Fetch unread counts
      final allChannelIds = [
        ...channels.map((e) => e.id),
        ...dms.map((e) => e.channelId),
      ];
      final unread = await ChatService.getUnreadCounts(allChannelIds);

      if (mounted) setState(() {
        _channels = channels;
        _last = last;
        _dmThreads = dms;
        _groups = groups;
        _unreadCounts = unread;
        _fabController.forward();
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

  List<DMThread> get _filteredDMs {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _dmThreads;
    return _dmThreads.where((t) => t.partnerName.toLowerCase().contains(q)).toList();
  }

  List<ChatGroup> get _filteredGroups {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _groups;
    return _groups.where((g) => g.name.toLowerCase().contains(q) || (g.description ?? '').toLowerCase().contains(q)).toList();
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
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped(_filtered);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: BrandedRefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await _load();
          },
          child: CustomScrollView(
            slivers: [
              // Enhanced App Bar
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                expandedHeight: AppLayout.appBarHeight,
                toolbarHeight: AppLayout.toolbarHeight,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Text('Messages', style: context.textStyles.titleLarge),
                    const SizedBox(width: 8),
                    if (_totalUnread > 0)
                      UnreadBadge(count: _totalUnread, size: 22),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'New Message',
                    onPressed: () => context.push('/chat/new'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
              ),
              
              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _SearchBar(controller: _search, onChanged: (_) => setState(() {})),
                ),
              ),
              
              // Content
              if (_loading)
                const SliverToBoxAdapter(child: ChatListShimmer(itemCount: 8))
              else if (_channels.isEmpty && _dmThreads.isEmpty && _groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onTap: _load),
                )
              else
                SliverList.list(children: [
                  _DMSection(
                    threads: _filteredDMs,
                    unreadCounts: _unreadCounts,
                  ),
                  _GroupsSection(
                    groups: _filteredGroups,
                    onCreateGroup: () async {
                      final result = await Navigator.push<ChatGroup>(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateGroupPage()),
                      );
                      if (result != null) _load();
                    },
                  ),
                  _ChannelGroup(
                    title: '📢 Announcements',
                    items: groups[ChannelType.ANNOUNCEMENT]!,
                    last: _last,
                    unreadCounts: _unreadCounts,
                  ),
                  _ChannelGroup(
                    title: '💬 General',
                    items: groups[ChannelType.GENERAL]!,
                    last: _last,
                    unreadCounts: _unreadCounts,
                  ),
                  _ChannelGroup(
                    title: '👥 Teams',
                    items: groups[ChannelType.ROLE_BASED]!,
                    last: _last,
                    unreadCounts: _unreadCounts,
                  ),
                  _ChannelGroup(
                    title: '📋 Tasks',
                    items: groups[ChannelType.TASK_SPECIFIC]!,
                    last: _last,
                    unreadCounts: _unreadCounts,
                  ),
                  const SizedBox(height: 80), // FAB space
                ]),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/chat/new');
          },
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('New Chat'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  int get _totalUnread => _unreadCounts.values.fold(0, (a, b) => a + b);
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: context.textStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search conversations...',
              hintStyle: context.textStyles.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: () {
              controller.clear();
              onChanged('');
            },
            child: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
  final Map<String, int> unreadCounts;
  
  const _ChannelGroup({
    required this.title,
    required this.items,
    required this.last,
    required this.unreadCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 20),
          child: Text(
            title,
            style: context.textStyles.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((c) => _ChannelTile(
          channel: c,
          last: last[c.id],
          unreadCount: unreadCounts[c.id] ?? 0,
        )),
      ]),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final WorkspaceChannel channel;
  final Message? last;
  final int unreadCount;
  
  const _ChannelTile({
    required this.channel,
    required this.last,
    required this.unreadCount,
  });

  IconData get _icon => switch (channel.type) {
    ChannelType.ANNOUNCEMENT => Icons.campaign_outlined,
    ChannelType.GENERAL => Icons.forum_outlined,
    ChannelType.ROLE_BASED => Icons.groups_outlined,
    ChannelType.TASK_SPECIFIC => Icons.checklist_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = last?.content ?? channel.description ?? '';
    final ts = last?.sentAt;
    final time = ts != null ? _formatTime(ts) : '';
    final hasUnread = unreadCount > 0;

    return Dismissible(
      key: Key('channel_${channel.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          Icons.mark_chat_read_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.lightImpact();
        await ChatService.updateLastRead(channel.id);
        return false;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/chat/${channel.id}', extra: channel);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasUnread 
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasUnread
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            // Channel icon with indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _icon,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                if (channel.isPrivate)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${channel.name}',
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        UnreadBadge(count: unreadCount, size: 20),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
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
    final diff = now.difference(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    return '${dt.month}/${dt.day}';
  }
}

class _DMSection extends StatelessWidget {
  final List<DMThread> threads;
  final Map<String, int> unreadCounts;
  
  const _DMSection({
    required this.threads,
    required this.unreadCounts,
  });

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            '💬 Direct Messages',
            style: context.textStyles.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...threads.map((t) => _DMTile(
          thread: t,
          unreadCount: unreadCounts[t.channelId] ?? 0,
        )),
      ]),
    );
  }
}

class _GroupsSection extends StatelessWidget {
  final List<ChatGroup> groups;
  final VoidCallback onCreateGroup;
  
  const _GroupsSection({
    required this.groups,
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '👥 Groups',
                style: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: onCreateGroup,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No groups yet. Create one!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...groups.map((g) => _GroupTile(group: g)),
      ]),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final ChatGroup group;
  
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = group.unreadCount > 0;
    final time = group.lastMessageAt != null ? _formatTime(group.lastMessageAt!) : '';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        HapticFeedback.selectionClick();
        // Navigate to group chat (reuse message thread or create group thread page)
        context.push('/chat/groups/${group.id}', extra: group);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: hasUnread
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          // Group avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: group.iconUrl != null
                ? CachedNetworkImage(
                    imageUrl: group.iconUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildGroupInitials(context),
                    errorWidget: (_, __, ___) => _buildGroupInitials(context),
                  )
                : _buildGroupInitials(context),
          ),
          const SizedBox(width: 14),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: hasUnread
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.lastMessage ?? '${group.memberCount} members',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: hasUnread
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasUnread) ...[
                      const SizedBox(width: 8),
                      UnreadBadge(count: group.unreadCount, size: 20),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGroupInitials(BuildContext context) {
    final hash = group.name.codeUnits.fold(0, (p, c) => p + c);
    final colors = [
      AppColors.indigo500,
      AppColors.teal500,
      AppColors.pink500,
      AppColors.violet500,
      AppColors.emerald500,
    ];
    
    return Container(
      color: colors[hash % colors.length].withValues(alpha: 0.15),
      child: Center(
        child: Text(
          group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: colors[hash % colors.length],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
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
    final diff = now.difference(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    return '${dt.month}/${dt.day}';
  }
}

class _DMTile extends StatelessWidget {
  final DMThread thread;
  final int unreadCount;
  
  const _DMTile({
    required this.thread,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = thread.lastMessage;
    final time = last != null ? _formatTime(last.sentAt) : '';
    final hasUnread = unreadCount > 0;

    return Dismissible(
      key: Key('dm_${thread.channelId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          Icons.mark_chat_read_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.lightImpact();
        await ChatService.updateLastRead(thread.channelId);
        return false;
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/chat/${thread.channelId}', extra: {
            'dmUserId': thread.partnerUserId,
            'dmUserName': thread.partnerName,
            'dmUserAvatar': thread.partnerAvatar,
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasUnread
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasUnread
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            // Avatar with online indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (thread.partnerAvatar != null && thread.partnerAvatar!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: thread.partnerAvatar!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildInitialAvatar(context),
                          errorWidget: (_, __, ___) => _buildInitialAvatar(context),
                        )
                      : _buildInitialAvatar(context),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: OnlineIndicator(isOnline: true, size: 14),
                ),
              ],
            ),
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.partnerName,
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: context.textStyles.labelSmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          last?.content ?? 'Start a conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: hasUnread
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        UnreadBadge(count: unreadCount, size: 20),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(BuildContext context) {
    final hash = thread.partnerName.codeUnits.fold(0, (p, c) => p + c);
    final colors = [
      AppColors.indigo500,
      AppColors.teal500,
      AppColors.pink500,
      AppColors.violet500,
      AppColors.emerald500,
    ];
    
    return Container(
      color: colors[hash % colors.length].withValues(alpha: 0.15),
      child: Center(
        child: Text(
          thread.partnerName.isNotEmpty ? thread.partnerName[0].toUpperCase() : '?',
          style: TextStyle(
            color: colors[hash % colors.length],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
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
    final diff = now.difference(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
    return '${dt.month}/${dt.day}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No conversations yet',
      subtitle: 'Start chatting with your team or connections',
      primaryButtonLabel: 'Start a Chat',
      primaryButtonIcon: Icons.add_comment_outlined,
      onPrimaryAction: () {
        HapticFeedback.lightImpact();
        context.push('/chat/new');
      },
      secondaryButtonLabel: 'Refresh',
      onSecondaryAction: onTap,
    );
  }
}
