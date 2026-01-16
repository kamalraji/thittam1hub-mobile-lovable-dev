import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/supabase/impact_service.dart';
import 'package:thittam1hub/models/connection_request_item.dart';
import 'package:thittam1hub/models/notification_item.dart';
import 'package:thittam1hub/services/notification_service.dart';
import 'pulse_page.dart';
import 'circles_page.dart';
import 'spark_page.dart';
import 'vibe_page.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
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

  final List<Widget> _pages = [
    PulsePage(),
    CirclesPage(),
    SparkPage(),
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
    final profile = await _impactService.getMyImpactProfile();
    if (mounted) {
      setState(() => _myProfile = profile);
    }
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationService.getNotifications();
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _unreadCount = count;
      });
    }
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
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: cs.surface,
              pinned: true,
              expandedHeight: 200.0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                centerTitle: true,
                title: Text(
                  'Impact Hub',
                  style: textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        cs.tertiary,
                      ],
                    ),
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: _myProfile?.avatarUrl != null
                      ? NetworkImage(_myProfile!.avatarUrl!)
                      : null,
                  child: _myProfile?.avatarUrl == null
                      ? Text(_myProfile?.fullName.substring(0, 1) ?? 'U')
                      : null,
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_none, color: cs.onSurface),
                      onPressed: _showNotificationsSheet,
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
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
                            '$_unreadCount',
                            style: TextStyle(color: cs.onError, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.people_outline, color: cs.onSurface),
                  onPressed: _showRequestsSheet,
                ),
                Chip(
                  label: Text('Score: ${_myProfile?.impactScore ?? 0}'),
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                SizedBox(width: 16),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _myProfile == null
                    ? const FadeSlideTransition(child: ScoreCardSkeleton())
                    : ScoreCard(profile: _myProfile),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                child: ModeSelector(
                  selectedIndex: _selectedIndex,
                  onTap: _onModeTapped,
                ),
                height: 100,
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
    );
  }
}

class ScoreCard extends StatelessWidget {
  final ImpactProfile? profile;

  const ScoreCard({Key? key, this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = profile?.impactScore ?? 0;
    final level = profile?.level ?? 1;
    final pointsToNextLevel = (level * 1000) - score;
    final progress = level > 0 ? (score % 1000) / 1000 : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.tertiary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Your Impact Score',
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: cs.onPrimary.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
          ),
          SizedBox(height: 8),
          Text(
            '$score pts • $pointsToNextLevel to Level ${level + 1}',
            style: TextStyle(
              color: cs.onPrimary,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  showGlassBottomSheet(
                    context: context,
                    title: 'Your Badges',
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    child: const BadgesContent(),
                  );
                },
                child: Text('View Badges'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.surface,
                  foregroundColor: cs.primary,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  showGlassBottomSheet(
                    context: context,
                    title: 'Leaderboard',
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    child: const LeaderboardContent(),
                  );
                },
                child: Text('Leaderboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.surface,
                  foregroundColor: cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Content widget for Badges glassmorphism sheet
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

/// Content widget for Leaderboard glassmorphism sheet
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

// Legacy sheet widgets kept for backward compatibility
class BadgesSheet extends StatelessWidget {
  const BadgesSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: const BadgesContent(),
        ),
      ),
    );
  }
}

class LeaderboardSheet extends StatelessWidget {
  const LeaderboardSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          child: const LeaderboardContent(),
        ),
      ),
    );
  }
}

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
    final screenHeight = MediaQuery.of(context).size.height;
    final selectorHeight = (screenHeight * 0.12).clamp(80.0, 120.0);
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: selectorHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 10),
        children: [
          ModePill(
            icon: Icons.search,
            label: 'Pulse',
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          ModePill(
            icon: Icons.public,
            label: 'Circles',
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          ModePill(
            icon: Icons.lightbulb_outline,
            label: 'Spark',
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          ModePill(
            icon: Icons.gamepad_outlined,
            label: 'Vibe',
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
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
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? cs.onPrimary : cs.onSurface,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child, this.height = 100});

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

class ScoreCardSkeleton extends StatelessWidget {
  const ScoreCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 18, width: 150, color: cs.surfaceContainerHigh),
          SizedBox(height: 12),
          Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(4))),
          SizedBox(height: 12),
          Container(height: 14, width: 200, color: cs.surfaceContainerHigh),
          SizedBox(height: 16),
          Row(
            children: [
              Container(height: 36, width: 100, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(18))),
              SizedBox(width: 12),
              Container(height: 36, width: 100, decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(18))),
            ],
          ),
        ],
      ),
    );
  }
}
