import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  const ImpactHubPage({Key? key}) : super(key: key);

  @override
  _ImpactHubPageState createState() => _ImpactHubPageState();
}

class _ImpactHubPageState extends State<ImpactHubPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
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

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
    _loadNotifications();
    _subscribeToNotifications();
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
      _notificationChannel = _notificationService.subscribeToNotifications((notification) {
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
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No notifications', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: n.isRead ? cs.surfaceContainerHighest : cs.primary.withValues(alpha: 0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: n.avatarUrl != null ? NetworkImage(n.avatarUrl!) : null,
                      child: n.avatarUrl == null ? Icon(_getNotificationIcon(n.type)) : null,
                      backgroundColor: _getNotificationColor(n.type).withValues(alpha: 0.2),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.message),
                        SizedBox(height: 4),
                        Text(_formatTimestamp(n.createdAt), style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No pending requests', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
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
                      backgroundImage: r.requesterAvatar != null ? NetworkImage(r.requesterAvatar!) : null,
                      child: r.requesterAvatar == null ? Text(r.requesterName.isNotEmpty ? r.requesterName[0] : '?') : null,
                    ),
                    title: Text(r.requesterName),
                    subtitle: Text('${r.connectionType} • ${r.matchScore}% match'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Decline',
                          icon: Icon(Icons.close, color: cs.error),
                          onPressed: () async {
                            await _impactService.respondToConnectionRequest(requestId: r.id, accept: false);
                            await _loadPendingRequests();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Declined ${r.requesterName}')));
                          },
                        ),
                        IconButton(
                          tooltip: 'Accept',
                          icon: Icon(Icons.check_circle, color: cs.primary),
                          onPressed: () async {
                            await _impactService.respondToConnectionRequest(requestId: r.id, accept: true);
                            await _loadPendingRequests();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected with ${r.requesterName}')));
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
  }

  void _onModeTapped(int index) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: cs.surface,
                pinned: true,
                floating: true,
                snap: true,
                expandedHeight: 120.0,
                collapsedHeight: 60,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final expandRatio = ((constraints.maxHeight - 60) / 60).clamp(0.0, 1.0);
                    final isExpanded = expandRatio > 0.5;
                    
                    return FlexibleSpaceBar(
                      titlePadding: EdgeInsets.only(
                        left: isExpanded ? 16 : 56,
                        bottom: 12,
                        right: isExpanded ? 120 : 140,
                      ),
                      centerTitle: false,
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: 1,
                        child: Text(
                          'Impact Hub',
                          style: textTheme.titleMedium?.copyWith(
                            color: isExpanded ? cs.onPrimary : cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isExpanded ? 20 : 18,
                          ),
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cs.primary,
                              cs.tertiary,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Decorative circles
                            Positioned(
                              top: -20,
                              right: -30,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.onPrimary.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: -20,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.onPrimary.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _profileLoading
                      ? const _AppBarAvatarSkeleton()
                      : CircleAvatar(
                          backgroundImage: _myProfile?.avatarUrl != null
                              ? NetworkImage(_myProfile!.avatarUrl!)
                              : null,
                          backgroundColor: cs.primaryContainer,
                          child: _myProfile?.avatarUrl == null
                              ? Text(
                                  _myProfile?.fullName.isNotEmpty == true 
                                      ? _myProfile!.fullName[0] 
                                      : 'U',
                                  style: TextStyle(color: cs.onPrimaryContainer),
                                )
                              : null,
                        ),
                ),
                actions: [
                  _notificationsLoading
                      ? const _NotificationBadgeSkeleton()
                      : PulsingWidget(
                          isPulsing: _unreadCount > 0,
                          glowColor: Theme.of(context).colorScheme.error,
                          child: Stack(
                            children: [
                              IconButton(
                                icon: Icon(Icons.notifications_outlined, color: cs.onSurface),
                                onPressed: _showNotificationsSheet,
                              ),
                              if (_unreadCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: cs.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      _unreadCount > 9 ? '9+' : '$_unreadCount',
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
                          ),
                        ),
                  IconButton(
                    icon: Icon(Icons.people_outline, color: cs.onSurface),
                    onPressed: _showRequestsSheet,
                  ),
                  SizedBox(width: 4),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: 12,
                  ),
                  child: _profileLoading
                      ? const _ScoreCardSkeleton()
                      : _profileError
                          ? _ScoreCardError(onRetry: _loadMyProfile)
                          : _ScoreCard(profile: _myProfile),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  child: _ModeSelector(
                    selectedIndex: _selectedIndex,
                    onTap: _onModeTapped,
                  ),
                  height: 64,
                ),
                pinned: true,
              ),
            ];
          },
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
          ),
        ),
      ),
    );
  }
}

// ============ Modern Glassmorphism ScoreCard ============

class _ScoreCard extends StatelessWidget {
  final ImpactProfile? profile;

  const _ScoreCard({Key? key, this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    
    final score = profile?.impactScore ?? 0;
    final level = profile?.level ?? 1;
    final streak = profile?.streakCount ?? 0;
    final pointsToNextLevel = (level * 1000) - score;
    final progress = level > 0 ? (score % 1000) / 1000 : 0.0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.9),
                cs.tertiary.withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(
              color: cs.onPrimary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.gps_fixed_rounded, size: 14, color: cs.onPrimary.withValues(alpha: 0.8)),
                          SizedBox(width: 4),
                          Text(
                            'Impact Score',
                            style: textTheme.labelMedium?.copyWith(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$score',
                        style: textTheme.headlineMedium?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Level badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.onPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 16, color: cs.onPrimary),
                        SizedBox(width: 4),
                        Text(
                          'Level $level',
                          style: textTheme.labelMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '$pointsToNextLevel pts to Level ${level + 1}',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Stats row and action buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final useCompact = constraints.maxWidth < 300;
                  
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      // Streak chip
                      if (streak > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                '$streak day${streak > 1 ? 's' : ''}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CompactActionButton(
                            icon: Icons.emoji_events_outlined,
                            label: useCompact ? null : 'Badges',
                            onTap: () {
                              showGlassBottomSheet(
                                context: context,
                                title: 'Your Badges',
                                maxHeight: MediaQuery.of(context).size.height * 0.8,
                                child: const BadgesContent(),
                              );
                            },
                          ),
                          SizedBox(width: 8),
                          _CompactActionButton(
                            icon: Icons.leaderboard_outlined,
                            label: useCompact ? null : 'Rank',
                            onTap: () {
                              showGlassBottomSheet(
                                context: context,
                                title: 'Leaderboard',
                                maxHeight: MediaQuery.of(context).size.height * 0.8,
                                child: const LeaderboardContent(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _CompactActionButton({
    required this.icon,
    this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Material(
      color: cs.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 12 : 10,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.primary),
              if (label != null) ...[
                SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ============ Score Card Loading & Error States ============

class _ScoreCardSkeleton extends StatelessWidget {
  const _ScoreCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 90, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(4))),
                    SizedBox(height: 8),
                    Container(height: 28, width: 70, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
                Container(height: 32, width: 80, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(16))),
              ],
            ),
            SizedBox(height: 16),
            Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(4))),
            SizedBox(height: 8),
            Container(height: 12, width: 140, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(4))),
            SizedBox(height: 16),
            Row(
              children: [
                Container(height: 32, width: 80, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12))),
                SizedBox(width: 8),
                Container(height: 32, width: 80, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ScoreCardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cs.errorContainer.withValues(alpha: 0.3),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 32),
          SizedBox(height: 8),
          Text(
            'Unable to load profile',
            style: textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer),
          ),
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: cs.error),
          ),
        ],
      ),
    );
  }
}

// ============ Mode Selector (Fixed - Only 3 tabs) ============

class _ModeSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _ModeSelector({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Mode items - matches _pages list (3 items)
    final modes = [
      _ModeItem(Icons.explore_outlined, Icons.explore, 'Pulse'),
      _ModeItem(Icons.group_outlined, Icons.group, 'Circles'),
      _ModeItem(Icons.gamepad_outlined, Icons.gamepad, 'Vibe'),
    ];
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3), width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(modes.length, (index) {
          final mode = modes[index];
          final isSelected = selectedIndex == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? mode.selectedIcon : mode.icon,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      size: 22,
                    ),
                    SizedBox(height: 2),
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ModeItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _ModeItem(this.icon, this.selectedIcon, this.label);
}

// ============ AppBar Skeletons ============

class _AppBarAvatarSkeleton extends StatelessWidget {
  const _AppBarAvatarSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _NotificationBadgeSkeleton extends StatelessWidget {
  const _NotificationBadgeSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ============ Sliver Delegate ============

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child, this.height = 64});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

// ============ Badges Content ============

class BadgesContent extends StatefulWidget {
  const BadgesContent({Key? key}) : super(key: key);

  @override
  State<BadgesContent> createState() => _BadgesContentState();
}

class _BadgesContentState extends State<BadgesContent> {
  final _svc = GamificationService();
  List<BadgeItem> _all = [];
  List<String> _mine = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _svc.getAllBadges(),
        _svc.getMyBadgeIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<BadgeItem>;
        _mine = results[1] as List<String>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('BadgesContent load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Chip(label: Text('${_mine.length}/${_all.length}')),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: _all.length,
          itemBuilder: (context, index) {
            final b = _all[index];
            final earned = _mine.contains(b.id);
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: earned ? 1 : 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(b.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(b.rarity, style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============ Leaderboard Content ============

class LeaderboardContent extends StatefulWidget {
  const LeaderboardContent({Key? key}) : super(key: key);

  @override
  State<LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<LeaderboardContent> {
  final _svc = GamificationService();
  List<LeaderboardEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _svc.getTopLeaderboard();
      if (!mounted) return;
      setState(() {
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Leaderboard load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ));
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final e = _entries[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: e.avatarUrl != null ? NetworkImage(e.avatarUrl!) : null,
            child: e.avatarUrl == null ? Text(e.name.isNotEmpty ? e.name[0] : '?') : null,
          ),
          title: Text('#${e.rank}  ${e.name}'),
          subtitle: Text('${e.score} pts'),
          trailing: index == 0
              ? const Text('🥇')
              : index == 1
                  ? const Text('🥈')
                  : index == 2
                      ? const Text('🥉')
                      : null,
        );
      },
    );
  }
}

// Legacy skeleton classes kept for backward compatibility
class AppBarAvatarSkeleton extends StatelessWidget {
  const AppBarAvatarSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const _AppBarAvatarSkeleton();
}

class NotificationBadgeSkeleton extends StatelessWidget {
  const NotificationBadgeSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const _NotificationBadgeSkeleton();
}

class ScoreChipSkeleton extends StatelessWidget {
  const ScoreChipSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Chip(
        label: Container(width: 50, height: 14),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class ScoreCardSkeleton extends StatelessWidget {
  const ScoreCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const _ScoreCardSkeleton();
}

// Legacy ModeSelector and ModePill kept for backward compatibility
class ModeSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const ModeSelector({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ModeSelector(selectedIndex: selectedIndex, onTap: onTap);
  }
}

class ModePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ModePill({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? cs.onPrimary : cs.onSurface, size: 20),
            SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? cs.onPrimary : cs.onSurface, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
