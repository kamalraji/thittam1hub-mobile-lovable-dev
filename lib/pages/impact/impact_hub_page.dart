import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/supabase/impact_service.dart';
import 'package:thittam1hub/models/connection_request_item.dart';
import 'package:thittam1hub/models/notification_item.dart';
import 'package:thittam1hub/services/notification_service.dart';
import 'pulse_page.dart';
import 'circles_page.dart';
import 'vibe_page.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
import 'package:thittam1hub/widgets/shimmer_loading.dart';
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';
import 'package:thittam1hub/widgets/confetti_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImpactHubPage extends StatefulWidget {
  final String? initialTab;

  const ImpactHubPage({Key? key, this.initialTab}) : super(key: key);

  @override
  _ImpactHubPageState createState() => _ImpactHubPageState();
}

class _ImpactHubPageState extends State<ImpactHubPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  final ImpactService _impactService = ImpactService();
  final NotificationService _notificationService = NotificationService();
  ImpactProfile? _myProfile;
  List<ConnectionRequestItem> _pendingRequests = [];
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  RealtimeChannel? _notificationChannel;
  bool _notificationsLoading = true;
  bool _profileLoading = true;
  bool _profileError = false;
  bool _showConfetti = false;
  String? _celebrationMessage;

  final List<Widget> _pages = [
    PulsePage(),
    CirclesPage(),
    VibePage(),
  ];

  static const _tabNames = ['pulse', 'circles', 'vibe'];
  static const _tabLabels = ['Pulse', 'Circles', 'Vibe'];
  static const _tabIcons = [
    Icons.explore_rounded,
    Icons.group_rounded,
    Icons.gamepad_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _getInitialTabIndex();
    _pageController = PageController(initialPage: _selectedIndex);
    _loadMyProfile();
    _loadNotifications();
    _subscribeToNotifications();
  }

  int _getInitialTabIndex() {
    if (widget.initialTab != null) {
      final index = _tabNames.indexOf(widget.initialTab!.toLowerCase());
      return index >= 0 ? index : 0;
    }
    return 0;
  }

  @override
  void didUpdateWidget(ImpactHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      final index = _tabNames.indexOf(widget.initialTab!.toLowerCase());
      if (index >= 0 && index != _selectedIndex) {
        _onModeTapped(index);
      }
    }
  }

  @override
  void dispose() {
    _notificationChannel?.unsubscribe();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMyProfile() async {
    if (!_profileLoading) {
      setState(() => _profileLoading = true);
    }
    try {
      final profile = await _impactService.getMyImpactProfile();
      if (mounted) {
        setState(() {
          _myProfile = profile;
          _profileLoading = false;
          _profileError = profile == null;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _profileLoading = false;
          _profileError = true;
        });
      }
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _notificationsLoading = true);
    try {
      final notifications = await _notificationService.getNotifications();
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _unreadCount = count;
          _notificationsLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() => _notificationsLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      _loadMyProfile(),
      _loadNotifications(),
    ]);
  }

  void _subscribeToNotifications() {
    try {
      _notificationChannel =
          _notificationService.subscribeToNotifications((notification) {
        if (mounted) {
          setState(() {
            _notifications.insert(0, notification);
            _unreadCount++;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.title),
              duration: Duration(seconds: 2),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => _showNotificationsSheet(),
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error subscribing to notifications: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    final items = await _impactService.getIncomingPendingRequests();
    if (mounted) setState(() => _pendingRequests = items);
  }

  void _showNotificationsSheet() async {
    await _loadNotifications();
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showGlassBottomSheet(
      context: context,
      title: 'Notifications',
      maxHeight: MediaQuery.of(context).size.height * 0.8,
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
              await _loadNotifications();
            },
            child: Text('Mark all read', style: TextStyle(color: cs.primary)),
          ),
        Chip(label: Text('${_unreadCount} new')),
      ],
      child: _notifications.isEmpty
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No notifications',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: n.isRead
                      ? cs.surfaceContainerHighest
                      : cs.primary.withValues(alpha: 0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: n.avatarUrl != null
                          ? NetworkImage(n.avatarUrl!)
                          : null,
                      child: n.avatarUrl == null
                          ? Icon(_getNotificationIcon(n.type))
                          : null,
                      backgroundColor:
                          _getNotificationColor(n.type).withValues(alpha: 0.2),
                    ),
                    title: Text(n.title,
                        style: TextStyle(
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.message),
                        SizedBox(height: 4),
                        Text(_formatTimestamp(n.createdAt),
                            style: textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    onTap: () async {
                      if (!n.isRead) {
                        await _notificationService.markAsRead(n.id);
                        await _loadNotifications();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }

  void _showRequestsSheet() async {
    await _loadPendingRequests();
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showGlassBottomSheet(
      context: context,
      title: 'Connection Requests',
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      actions: [Chip(label: Text('${_pendingRequests.length}'))],
      child: _pendingRequests.isEmpty
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No pending requests',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingRequests.length,
              itemBuilder: (context, index) {
                final r = _pendingRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: r.requesterAvatar != null
                          ? NetworkImage(r.requesterAvatar!)
                          : null,
                      child: r.requesterAvatar == null
                          ? Text(r.requesterName.isNotEmpty
                              ? r.requesterName[0]
                              : '?')
                          : null,
                    ),
                    title: Text(r.requesterName),
                    subtitle:
                        Text('${r.connectionType} • ${r.matchScore}% match'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decline',
                          icon: Icon(Icons.close, color: cs.error),
                          onPressed: () async {
                            await _impactService.respondToConnectionRequest(
                                requestId: r.id, accept: false);
                            await _loadPendingRequests();
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Declined ${r.requesterName}')));
                          },
                        ),
                        IconButton(
                          tooltip: 'Accept',
                          icon: Icon(Icons.check_circle, color: cs.primary),
                          onPressed: () async {
                            await _impactService.respondToConnectionRequest(
                                requestId: r.id, accept: true);
                            await _loadPendingRequests();
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Connected with ${r.requesterName}')));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showScoreDetailSheet() {
    if (_myProfile == null) return;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final score = _myProfile?.impactScore ?? 0;
    final level = _myProfile?.level ?? 1;
    final streak = _myProfile?.streakCount ?? 0;
    final pointsToNextLevel = (level * 1000) - score;
    final progress = level > 0 ? (score % 1000) / 1000 : 0.0;

    showGlassBottomSheet(
      context: context,
      title: 'Impact Score',
      maxHeight: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          // Large score display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.9),
                  cs.tertiary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, size: 32, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      '$score',
                      style: textTheme.displaySmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Level $level',
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                    minHeight: 10,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '$pointsToNextLevel pts to Level ${level + 1}',
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orange,
                  label: 'Streak',
                  value: '$streak days',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber,
                  label: 'Badges',
                  value: '${_myProfile?.badges.length ?? 0}',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showGlassBottomSheet(
                      context: context,
                      title: 'Your Badges',
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                      child: const BadgesContent(),
                    );
                  },
                  icon: Icon(Icons.emoji_events_outlined),
                  label: Text('Badges'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showGlassBottomSheet(
                      context: context,
                      title: 'Leaderboard',
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                      child: const LeaderboardContent(),
                    );
                  },
                  icon: Icon(Icons.leaderboard_outlined),
                  label: Text('Rank'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.CONNECTION_REQUEST:
        return Icons.person_add;
      case NotificationType.CONNECTION_ACCEPTED:
        return Icons.check_circle;
      case NotificationType.CIRCLE_INVITE:
        return Icons.group_add;
      case NotificationType.SPARK_REACTION:
        return Icons.lightbulb;
      case NotificationType.NEW_BADGE:
        return Icons.emoji_events;
      case NotificationType.LEVEL_UP:
        return Icons.trending_up;
      case NotificationType.MUTUAL_CONNECTION:
        return Icons.people;
      case NotificationType.HIGH_MATCH_ONLINE:
        return Icons.favorite;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case NotificationType.CONNECTION_REQUEST:
      case NotificationType.CONNECTION_ACCEPTED:
        return cs.primary;
      case NotificationType.CIRCLE_INVITE:
        return cs.tertiary;
      case NotificationType.SPARK_REACTION:
        return Colors.amber;
      case NotificationType.NEW_BADGE:
      case NotificationType.LEVEL_UP:
        return Colors.orange;
      case NotificationType.MUTUAL_CONNECTION:
        return Colors.blue;
      case NotificationType.HIGH_MATCH_ONLINE:
        return Colors.pink;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _updateUrl(index);
  }

  void _onModeTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateUrl(int index) {
    final tabName = _tabNames[index];
    context.replace('/impact?tab=$tabName');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                floating: true,
                snap: true,
                expandedHeight: 56,
                collapsedHeight: 56,
                toolbarHeight: 56,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    // Left: Impact Hub Logo
                    _ImpactHubLogoInline(),
                    const Spacer(),
                    // Center: Tab Dropdown
                    _TabDropdown(
                      selectedIndex: _selectedIndex,
                      labels: _tabLabels,
                      icons: _tabIcons,
                      onChanged: _onModeTapped,
                    ),
                    const Spacer(),
                    // Right: Score Badge + Notifications
                    _ImpactScoreBadge(
                      profile: _myProfile,
                      isLoading: _profileLoading,
                      onTap: _showScoreDetailSheet,
                    ),
                    SizedBox(width: 4),
                    _notificationsLoading
                        ? const _NotificationBadgeSkeleton()
                        : PulsingWidget(
                            isPulsing: _unreadCount > 0,
                            glowColor: cs.error,
                            child: _HeaderIconButton(
                              icon: Icons.notifications_outlined,
                              badgeCount: _unreadCount,
                              onPressed: _showNotificationsSheet,
                            ),
                          ),
                  ],
                ),
              ),
            ];
          },
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: _pages,
          ),
        ),
      ),
    );
  }
}

// ============ Impact Hub Logo Inline ============

class _ImpactHubLogoInline extends StatelessWidget {
  const _ImpactHubLogoInline();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Brand colors
    const gradientStart = Color(0xFF8B5CF6);
    const gradientEnd = Color(0xFF06B6D4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Impact Hub',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ============ Tab Dropdown Selector ============

class _TabDropdown extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final Function(int) onChanged;

  const _TabDropdown({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopupMenuButton<int>(
      onSelected: onChanged,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[selectedIndex], size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              labels[selectedIndex],
              style: textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: cs.primary),
          ],
        ),
      ),
      itemBuilder: (context) => List.generate(
        labels.length,
        (index) => PopupMenuItem<int>(
          value: index,
          child: Row(
            children: [
              Icon(
                icons[index],
                size: 20,
                color:
                    index == selectedIndex ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                labels[index],
                style: textTheme.bodyMedium?.copyWith(
                  color: index == selectedIndex ? cs.primary : cs.onSurface,
                  fontWeight: index == selectedIndex
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              if (index == selectedIndex) ...[
                const Spacer(),
                Icon(Icons.check_rounded, size: 18, color: cs.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============ Compact Impact Score Badge ============

class _ImpactScoreBadge extends StatelessWidget {
  final ImpactProfile? profile;
  final bool isLoading;
  final VoidCallback onTap;

  const _ImpactScoreBadge({
    required this.profile,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading) {
      return ShimmerLoading(
        child: Container(
          width: 70,
          height: 32,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    final score = profile?.impactScore ?? 0;
    final level = profile?.level ?? 1;
    final streak = profile?.streakCount ?? 0;

    // Format score compactly
    String scoreText;
    if (score >= 1000) {
      scoreText = '${(score / 1000).toStringAsFixed(1)}K';
    } else {
      scoreText = '$score';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.15),
                cs.tertiary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                scoreText,
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              Text(
                'Lv$level',
                style: textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(width: 4),
                Icon(Icons.local_fire_department_rounded,
                    size: 12, color: Colors.orange),
                Text(
                  '$streak',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============ Header Icon Button ============

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    this.badgeCount = 0,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: cs.onSurface),
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: TextStyle(
                  color: cs.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ============ Stat Tile for Score Detail Sheet ============

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Skeleton Widgets ============

class _NotificationBadgeSkeleton extends StatelessWidget {
  const _NotificationBadgeSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ShimmerLoading(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AppBarAvatarSkeleton extends StatelessWidget {
  const _AppBarAvatarSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ShimmerLoading(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ============ Badges & Leaderboard Content ============

class BadgesContent extends StatefulWidget {
  const BadgesContent({Key? key}) : super(key: key);

  @override
  State<BadgesContent> createState() => _BadgesContentState();
}

class _BadgesContentState extends State<BadgesContent> {
  final GamificationService _gamificationService = GamificationService();
  List<Map<String, dynamic>> _earnedBadges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final badgeIds = await _gamificationService.getMyBadgeIds();
      final allBadges = await _gamificationService.getAllBadges();
      final earnedBadges = allBadges
          .where((b) => badgeIds.contains(b.id))
          .map((b) => {
                'id': b.id,
                'name': b.name,
                'description': b.description,
                'icon': b.icon,
                'category': b.category,
                'points_required': b.pointsRequired,
                'rarity': b.rarity,
              })
          .toList();
      if (mounted) {
        setState(() {
          _earnedBadges = earnedBadges;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading badges: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getBadgeIcon(String category) {
    switch (category.toUpperCase()) {
      case 'NETWORKING':
        return Icons.hub_rounded;
      case 'ENGAGEMENT':
        return Icons.thumb_up_rounded;
      case 'CONTENT':
        return Icons.create_rounded;
      case 'COMMUNITY':
        return Icons.groups_rounded;
      case 'ACHIEVEMENT':
        return Icons.emoji_events_rounded;
      case 'SPECIAL':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.verified_rounded;
    }
  }

  Color _getBadgeColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'LEGENDARY':
        return Colors.amber;
      case 'EPIC':
        return Colors.purple;
      case 'RARE':
        return Colors.blue;
      case 'COMMON':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_earnedBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 48, color: cs.onSurfaceVariant),
            SizedBox(height: 16),
            Text('No badges earned yet',
                style:
                    textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            SizedBox(height: 8),
            Text('Keep engaging to earn badges!',
                style:
                    textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _earnedBadges.length,
      itemBuilder: (context, index) {
        final b = _earnedBadges[index];
        final badge = b['badge'] as Map<String, dynamic>? ?? b;
        final category = (badge['category'] ?? 'ACHIEVEMENT') as String;
        final rarity = (badge['rarity'] ?? 'COMMON') as String;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getBadgeColor(rarity).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getBadgeIcon(category),
                  color: _getBadgeColor(rarity), size: 24),
            ),
            title: Text(badge['name'] ?? 'Badge',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle:
                Text(badge['description'] ?? '', style: textTheme.bodySmall),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getBadgeColor(rarity).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rarity,
                style: textTheme.labelSmall?.copyWith(
                  color: _getBadgeColor(rarity),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LeaderboardContent extends StatefulWidget {
  const LeaderboardContent({Key? key}) : super(key: key);

  @override
  State<LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<LeaderboardContent> {
  final ImpactService _impactService = ImpactService();
  final GamificationService _gamificationService = GamificationService();
  List<LeaderboardEntry> _topUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      final users = await _gamificationService.getTopLeaderboard(limit: 20);
      if (mounted) {
        setState(() {
          _topUsers = users;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_topUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 48, color: cs.onSurfaceVariant),
            SizedBox(height: 16),
            Text('Leaderboard is empty',
                style:
                    textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topUsers.length,
      itemBuilder: (context, index) {
        final user = _topUsers[index];
        final rank = user.rank;

        Color rankColor;
        IconData? rankIcon;
        if (rank == 1) {
          rankColor = Colors.amber;
          rankIcon = Icons.emoji_events_rounded;
        } else if (rank == 2) {
          rankColor = Colors.grey.shade400;
          rankIcon = Icons.emoji_events_rounded;
        } else if (rank == 3) {
          rankColor = Colors.brown.shade300;
          rankIcon = Icons.emoji_events_rounded;
        } else {
          rankColor = cs.onSurfaceVariant;
          rankIcon = null;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  child: rankIcon != null
                      ? Icon(rankIcon, color: rankColor, size: 24)
                      : Text(
                          '#$rank',
                          style: textTheme.titleSmall?.copyWith(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.name.isNotEmpty ? user.name[0] : '?')
                      : null,
                ),
              ],
            ),
            title: Text(user.name,
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Rank #${user.rank}', style: textTheme.bodySmall),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  '${user.score}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============ Pulsing Animation Widget ============

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final bool isPulsing;
  final Color glowColor;

  const PulsingWidget({
    Key? key,
    required this.child,
    this.isPulsing = false,
    this.glowColor = Colors.red,
  }) : super(key: key);

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
