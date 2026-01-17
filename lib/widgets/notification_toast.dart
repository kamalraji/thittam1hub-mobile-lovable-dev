import 'package:flutter/material.dart';
import 'package:thittam1hub/models/notification_item.dart';

class NotificationToast extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationToast({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    
    _controller.forward();
    
    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  IconData _getIcon() {
    switch (widget.notification.type) {
      case NotificationType.SPARK_REACTION:
        return Icons.bolt;
      case NotificationType.CONNECTION_REQUEST:
        return Icons.person_add;
      case NotificationType.CONNECTION_ACCEPTED:
        return Icons.people;
      case NotificationType.CIRCLE_INVITE:
        return Icons.group_add;
      case NotificationType.NEW_BADGE:
        return Icons.military_tech;
      case NotificationType.LEVEL_UP:
        return Icons.arrow_upward;
      case NotificationType.MUTUAL_CONNECTION:
        return Icons.handshake;
      case NotificationType.HIGH_MATCH_ONLINE:
        return Icons.circle;
    }
  }

  Color _getIconColor() {
    switch (widget.notification.type) {
      case NotificationType.SPARK_REACTION:
        return Colors.amber;
      case NotificationType.HIGH_MATCH_ONLINE:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: Key(widget.notification.id),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: GestureDetector(
            onTap: () {
              _dismiss();
              widget.onTap();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar or icon
                  if (widget.notification.avatarUrl != null)
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(widget.notification.avatarUrl!),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getIconColor().withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: _getIconColor(),
                        size: 22,
                      ),
                    ),
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.notification.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.notification.message,
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Dismiss button
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay to show notification toasts
class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  static NotificationOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<NotificationOverlayState>();
  }

  @override
  State<NotificationOverlay> createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay> {
  final List<NotificationItem> _notifications = [];

  void showNotification(NotificationItem notification) {
    setState(() {
      _notifications.add(notification);
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        SafeArea(
          child: Column(
            children: _notifications.take(3).map((notification) {
              return NotificationToast(
                key: ValueKey(notification.id),
                notification: notification,
                onTap: () {
                  // TODO: Navigate to action URL
                  _removeNotification(notification.id);
                },
                onDismiss: () => _removeNotification(notification.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
