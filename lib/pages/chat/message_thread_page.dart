import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/chat_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/typing_indicator.dart';
import 'package:thittam1hub/widgets/message_reactions_bar.dart';
import 'package:thittam1hub/widgets/emoji_picker_sheet.dart';
import 'package:thittam1hub/widgets/message_status_indicator.dart';
import 'package:thittam1hub/widgets/unread_badge.dart';
import 'package:thittam1hub/services/giphy_service.dart';
import 'package:thittam1hub/widgets/gif_picker_sheet.dart';

class MessageThreadPage extends StatefulWidget {
  final String channelId;
  final WorkspaceChannel? channel;
  final String? dmUserId;
  final String? dmUserName;
  final String? dmUserAvatar;
  const MessageThreadPage({
    super.key,
    required this.channelId,
    this.channel,
    this.dmUserId,
    this.dmUserName,
    this.dmUserAvatar,
  });
  @override
  State<MessageThreadPage> createState() => _MessageThreadPageState();
}

class _MessageThreadPageState extends State<MessageThreadPage> with TickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final Map<String, DateTime> _typingUsers = {};
  Timer? _typingCleanup;
  Timer? _typingDebounce;
  bool _sending = false;
  bool _showAttachments = false;
  
  // Reactions state
  Map<String, List<Map<String, dynamic>>> _reactions = {};
  Map<String, List<String>> _readReceipts = {};
  
  // Animation controllers
  late final AnimationController _composerController;
  late final Animation<double> _composerAnimation;

  @override
  void initState() {
    super.initState();
    _composerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _composerAnimation = CurvedAnimation(
      parent: _composerController,
      curve: Curves.easeOut,
    );
    _composerController.forward();
    
    _subscribeTyping();
    _loadReactionsAndReceipts();
    
    // Mark channel as read
    ChatService.updateLastRead(widget.channelId);
  }

  @override
  void dispose() {
    _typingCleanup?.cancel();
    _typingDebounce?.cancel();
    _composerController.dispose();
    _input.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _subscribeTyping() {
    final channel = ChatService.typingChannel(widget.channelId);
    channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final data = payload['payload'] as Map<String, dynamic>?;
        if (data == null) return;
        
        final userId = data['userId'] as String?;
        final name = data['name'] as String?;
        final me = SupabaseConfig.auth.currentUser?.id;
        
        if (userId != null && userId != me && name != null) {
          setState(() {
            _typingUsers[name] = DateTime.now();
          });
          _scheduleTypingCleanup();
        }
      },
    ).subscribe();
  }

  void _scheduleTypingCleanup() {
    _typingCleanup?.cancel();
    _typingCleanup = Timer.periodic(const Duration(seconds: 2), (_) {
      final now = DateTime.now();
      _typingUsers.removeWhere((_, ts) => now.difference(ts).inSeconds > 3);
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadReactionsAndReceipts() async {
    // This would be called after messages load
  }

  Future<void> _onSend() async {
    if (_input.text.trim().isEmpty) return;
    
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    
    try {
      await ChatService.sendMessage(
        channelId: widget.channelId,
        content: _input.text.trim(),
      );
      _input.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Send message error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onTyping() {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final user = SupabaseConfig.auth.currentUser;
        final name = user?.email?.split('@').first ?? 'User';
        if (user != null) {
          await ChatService.sendTyping(widget.channelId, name: name, userId: user.id);
        }
      } catch (e) {
        debugPrint('Typing broadcast error: $e');
      }
    });
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

  Future<void> _onReaction(String messageId, String emoji) async {
    HapticFeedback.mediumImpact();
    await ChatService.addReaction(messageId, emoji);
  }

  void _showReactionPicker(BuildContext context, String messageId, Offset position) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx - 100,
            top: position.dy - 60,
            child: Material(
              color: Colors.transparent,
              child: ReactionPicker(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  _onReaction(messageId, emoji);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final isDM = widget.dmUserId != null;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ThreadAppBar(
              channel: channel,
              dmUserName: widget.dmUserName,
              dmUserAvatar: widget.dmUserAvatar,
            ),
            
            // Messages
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: ChatService.streamMessages(widget.channelId),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  
                  if (messages.isEmpty) {
                    return const _EmptyThread();
                  }
                  
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: _itemCount(messages),
                    itemBuilder: (context, index) => _buildItem(context, index, messages),
                  );
                },
              ),
            ),
            
            // Typing indicator
            if (_typingUsers.isNotEmpty)
              TypingIndicator(
                userName: _typingUsers.keys.first,
                showName: true,
              ),
            
            // Glassmorphism Composer
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_composerAnimation),
              child: _GlassComposer(
                controller: _input,
                focusNode: _focusNode,
                hintLabel: isDM ? '@${widget.dmUserName ?? 'Direct'}' : '#${channel?.name ?? 'channel'}',
                onSend: _onSend,
                onChanged: (_) => _onTyping(),
                sending: _sending,
                showAttachments: _showAttachments,
                onToggleAttachments: () => setState(() => _showAttachments = !_showAttachments),
                onEmojiTap: () => showEmojiPicker(
                  context,
                  onEmojiSelected: (emoji) {
                    final text = _input.text;
                    final selection = _input.selection;
                    final newText = text.replaceRange(
                      selection.start,
                      selection.end,
                      emoji,
                    );
                    _input.text = newText;
                    _input.selection = TextSelection.collapsed(
                      offset: selection.start + emoji.length,
                    );
                  },
                ),
                onGifTap: () => _showGifPicker(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGifPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GifPickerSheet(
        onGifSelected: (gif) async {
          Navigator.pop(context);
          setState(() => _sending = true);
          try {
            await ChatService.sendMessage(
              channelId: widget.channelId,
              content: gif.fullUrl,
            );
            _scrollToBottom();
          } finally {
            if (mounted) setState(() => _sending = false);
          }
        },
      ),
    );
  }

  int _itemCount(List<Message> msgs) {
    int count = 0;
    for (int i = 0; i < msgs.length; i++) {
      count++;
      if (i == 0) continue;
      final gap = msgs[i].sentAt.difference(msgs[i - 1].sentAt).inMinutes;
      if (gap > 5) count++;
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
      if (index == msgIndex) {
        return _MessageBubble(
          message: msgs[i],
          reactions: _reactions[msgs[i].id] ?? [],
          readBy: _readReceipts[msgs[i].id] ?? [],
          onReactionTap: (emoji) => _onReaction(msgs[i].id, emoji),
          onLongPress: (position) => _showReactionPicker(context, msgs[i].id, position),
        );
      }
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
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          
          if (isDM) ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (dmUserAvatar != null && dmUserAvatar!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: dmUserAvatar!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildInitial(dmUserName!, context),
                          errorWidget: (_, __, ___) => _buildInitial(dmUserName!, context),
                        )
                      : _buildInitial(dmUserName!, context),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: OnlineIndicator(isOnline: true, size: 12),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: isDM
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dmUserName ?? 'Direct Message',
                        style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '#${channel?.name ?? 'channel'}',
                              style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel?.isPrivate == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock, size: 12, color: theme.colorScheme.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Private',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if ((channel?.description ?? '').isNotEmpty)
                        Text(
                          channel!.description!,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
          ),
          
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            onPressed: () {
              // Show channel/DM options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name, BuildContext context) {
    final hash = name.codeUnits.fold(0, (p, c) => p + c);
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
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: colors[hash % colors.length],
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start the conversation',
              style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to send a message!',
              style: context.textStyles.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    theme.colorScheme.outline.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: context.textStyles.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.outline.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      return ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1];
    }
    return '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
  }
}

class _MessageBubble extends StatefulWidget {
  final Message message;
  final List<Map<String, dynamic>> reactions;
  final List<String> readBy;
  final Function(String emoji) onReactionTap;
  final Function(Offset position) onLongPress;

  const _MessageBubble({
    required this.message,
    required this.reactions,
    required this.readBy,
    required this.onReactionTap,
    required this.onLongPress,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _nameColor(String name) {
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
    ];
    return colors[hash % colors.length];
  }

  List<GroupedReaction> get _groupedReactions {
    final userId = SupabaseConfig.auth.currentUser?.id;
    final Map<String, List<String>> grouped = {};
    
    for (final r in widget.reactions) {
      final emoji = r['emoji'] as String;
      final uid = r['user_id'] as String;
      grouped.putIfAbsent(emoji, () => []).add(uid);
    }
    
    return grouped.entries.map((e) {
      return GroupedReaction(
        emoji: e.key,
        count: e.value.length,
        reactedByMe: e.value.contains(userId),
        userIds: e.value,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = SupabaseConfig.auth.currentUser?.id;
    final isMe = me == widget.message.senderId;
    
    final bubbleColor = isMe
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = isMe
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : theme.colorScheme.outline.withValues(alpha: 0.2);

    // Check if message is a GIF
    final isGif = widget.message.content.contains('giphy.com') ||
                  widget.message.content.endsWith('.gif');

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onLongPressStart: (details) {
            HapticFeedback.mediumImpact();
            widget.onLongPress(details.globalPosition);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe) _Avatar(name: widget.message.senderName),
                if (!isMe) const SizedBox(width: 8),
                
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.message.senderName,
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: _nameColor(widget.message.senderName),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _fmtTime(widget.message.sentAt),
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 6),
                            bottomRight: Radius.circular(isMe ? 6 : 20),
                          ),
                          border: Border.all(color: borderColor),
                        ),
                        padding: isGif 
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isGif)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: widget.message.content,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 200,
                                    height: 150,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 200,
                                    height: 100,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              )
                            else
                              SelectableText(
                                widget.message.content,
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            
                            if (widget.message.attachments.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Column(
                                children: widget.message.attachments
                                    .map((a) => _AttachmentRow(att: a))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Reactions display
                      if (_groupedReactions.isNotEmpty)
                        ReactionsDisplay(
                          reactions: _groupedReactions,
                          onReactionTap: widget.onReactionTap,
                        ),
                      
                      // Read receipts and status for own messages
                      if (isMe)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _fmtTime(widget.message.sentAt),
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(width: 4),
                              MessageStatusIndicator(
                                status: widget.readBy.isNotEmpty
                                    ? MessageStatus.read
                                    : MessageStatus.delivered,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (isMe) const SizedBox(width: 8),
                if (isMe) _Avatar(name: widget.message.senderName, isMe: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $am';
  }
}

class _AttachmentRow extends StatelessWidget {
  final MessageAttachment att;
  const _AttachmentRow({required this.att});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attach_file,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.filename,
                  style: context.textStyles.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _humanSize(att.size),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _color(name).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: _color(name),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _GlassComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintLabel;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged;
  final bool sending;
  final bool showAttachments;
  final VoidCallback onToggleAttachments;
  final VoidCallback onEmojiTap;
  final VoidCallback onGifTap;

  const _GlassComposer({
    required this.controller,
    required this.focusNode,
    required this.hintLabel,
    required this.onSend,
    this.onChanged,
    this.sending = false,
    this.showAttachments = false,
    required this.onToggleAttachments,
    required this.onEmojiTap,
    required this.onGifTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Attachment options
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _AttachmentOption(
                          icon: Icons.image_outlined,
                          label: 'Photo',
                          color: AppColors.indigo500,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _AttachmentOption(
                          icon: Icons.gif_box_outlined,
                          label: 'GIF',
                          color: AppColors.pink500,
                          onTap: onGifTap,
                        ),
                        const SizedBox(width: 12),
                        _AttachmentOption(
                          icon: Icons.attach_file,
                          label: 'File',
                          color: AppColors.teal500,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: showAttachments
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                
                // Main composer row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment toggle
                    GestureDetector(
                      onTap: onToggleAttachments,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: showAttachments
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          showAttachments ? Icons.close : Icons.add,
                          color: showAttachments
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Text field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                focusNode: focusNode,
                                onChanged: onChanged,
                                onSubmitted: (_) => onSend(),
                                textInputAction: TextInputAction.send,
                                maxLines: 4,
                                minLines: 1,
                                style: context.textStyles.bodyMedium,
                                decoration: InputDecoration(
                                  hintText: 'Message $hintLabel',
                                  hintStyle: context.textStyles.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Emoji button
                            GestureDetector(
                              onTap: onEmojiTap,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8, bottom: 8),
                                child: Icon(
                                  Icons.emoji_emotions_outlined,
                                  size: 22,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Send button
                    GestureDetector(
                      onTap: controller.text.trim().isEmpty ? null : onSend,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: controller.text.trim().isNotEmpty
                              ? LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: controller.text.trim().isEmpty
                              ? theme.colorScheme.surfaceContainerHighest
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: controller.text.trim().isNotEmpty
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: sending
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: controller.text.trim().isNotEmpty
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
