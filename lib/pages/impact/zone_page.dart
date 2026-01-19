import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/models/zone_models.dart';
import 'package:thittam1hub/supabase/zone_service.dart';
import 'package:thittam1hub/widgets/branded_refresh_indicator.dart';
import 'package:thittam1hub/widgets/shimmer_loading.dart';
import 'package:go_router/go_router.dart';

class ZonePage extends StatefulWidget {
  final String? searchQuery;
  final String? eventId;

  const ZonePage({Key? key, this.searchQuery, this.eventId}) : super(key: key);

  @override
  State<ZonePage> createState() => _ZonePageState();
}

class _ZonePageState extends State<ZonePage> {
  final ZoneService _zoneService = ZoneService();
  
  bool _isLoading = true;
  ZoneEvent? _currentEvent;
  List<ZoneEvent> _todayEvents = [];
  List<EventSession> _liveSessions = [];
  List<EventSession> _upcomingSessions = [];
  List<AttendeeRadar> _nearbyAttendees = [];
  List<EventPoll> _activePolls = [];
  List<EventAnnouncement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load today's events first
      _todayEvents = await _zoneService.getTodayEvents();
      
      // Get current checked-in event or use provided eventId
      if (widget.eventId != null) {
        _currentEvent = _todayEvents.firstWhere(
          (e) => e.id == widget.eventId,
          orElse: () => _todayEvents.isNotEmpty ? _todayEvents.first : null as ZoneEvent,
        );
      } else {
        _currentEvent = await _zoneService.getCurrentEvent();
        if (_currentEvent == null && _todayEvents.isNotEmpty) {
          _currentEvent = _todayEvents.first;
        }
      }

      // Load event-specific data if we have an event
      if (_currentEvent != null) {
        await Future.wait([
          _loadSessions(),
          _loadAttendees(),
          _loadPolls(),
          _loadAnnouncements(),
        ]);
      }
    } catch (e) {
      debugPrint('Zone page load error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSessions() async {
    if (_currentEvent == null) return;
    _liveSessions = await _zoneService.getLiveSessions(_currentEvent!.id);
    _upcomingSessions = await _zoneService.getUpcomingSessions(_currentEvent!.id);
  }

  Future<void> _loadAttendees() async {
    if (_currentEvent == null) return;
    _nearbyAttendees = await _zoneService.getNearbyAttendees(_currentEvent!.id);
  }

  Future<void> _loadPolls() async {
    if (_currentEvent == null) return;
    _activePolls = await _zoneService.getActivePolls(_currentEvent!.id);
  }

  Future<void> _loadAnnouncements() async {
    if (_currentEvent == null) return;
    _announcements = await _zoneService.getAnnouncements(_currentEvent!.id);
  }

  Future<void> _handleCheckIn() async {
    if (_currentEvent == null) return;
    
    HapticFeedback.mediumImpact();
    final success = await _zoneService.checkIn(_currentEvent!.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Checked in to ${_currentEvent!.name}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _loadData();
    }
  }

  Future<void> _handleCheckOut() async {
    if (_currentEvent == null) return;
    
    HapticFeedback.mediumImpact();
    final success = await _zoneService.checkOut(_currentEvent!.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked out. See you next time!')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, color: cs.primary, size: 24),
            const SizedBox(width: 8),
            Text('Zone',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_currentEvent != null)
            TextButton.icon(
              onPressed: _currentEvent!.isCheckedIn ? _handleCheckOut : _handleCheckIn,
              icon: Icon(
                _currentEvent!.isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
                size: 18,
              ),
              label: Text(_currentEvent!.isCheckedIn ? 'Check Out' : 'Check In'),
              style: TextButton.styleFrom(foregroundColor: cs.primary),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _currentEvent == null
                ? _buildNoEventState()
                : BrandedRefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 80,
                      ),
                      children: [
                        // Event Context Header
                        _EventContextCard(
                          event: _currentEvent!,
                          attendeeCount: _nearbyAttendees.length,
                          onCheckIn: _handleCheckIn,
                          onCheckOut: _handleCheckOut,
                        ),

                        // Live Now Section
                        if (_liveSessions.isNotEmpty) ...[
                          _buildSectionHeader('🔴 Live Now', cs.error),
                          ..._liveSessions.map((s) => _LiveSessionCard(session: s)),
                        ],

                        // Up Next Section
                        if (_upcomingSessions.isNotEmpty) ...[
                          _buildSectionHeader('⏭️ Up Next', cs.primary),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _upcomingSessions.length,
                              itemBuilder: (ctx, i) => _UpcomingSessionCard(
                                session: _upcomingSessions[i],
                              ),
                            ),
                          ),
                        ],

                        // Networking Radar
                        if (_nearbyAttendees.isNotEmpty) ...[
                          _buildSectionHeader(
                            '📡 Networking Radar (${_nearbyAttendees.length} nearby)',
                            cs.tertiary,
                          ),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _nearbyAttendees.length > 8
                                  ? 9
                                  : _nearbyAttendees.length,
                              itemBuilder: (ctx, i) {
                                if (i == 8 && _nearbyAttendees.length > 8) {
                                  return _MoreAttendeesCard(
                                    count: _nearbyAttendees.length - 8,
                                  );
                                }
                                return _AttendeeRadarCard(
                                  attendee: _nearbyAttendees[i],
                                  onTap: () {
                                    context.push('/profile/${_nearbyAttendees[i].userId}');
                                  },
                                );
                              },
                            ),
                          ),
                        ],

                        // Live Polls
                        if (_activePolls.isNotEmpty) ...[
                          _buildSectionHeader('📊 Live Poll', cs.secondary),
                          ..._activePolls.take(1).map((p) => _LivePollCard(
                                poll: p,
                                onVote: (optionId) async {
                                  await _zoneService.submitPollVote(p.id, optionId);
                                  _loadPolls();
                                  if (mounted) setState(() {});
                                },
                              )),
                        ],

                        // Announcements Feed
                        if (_announcements.isNotEmpty) ...[
                          _buildSectionHeader('📢 Announcements', cs.onSurfaceVariant),
                          ..._announcements.map((a) => _AnnouncementCard(announcement: a)),
                        ],

                        // Empty state if nothing happening
                        if (_liveSessions.isEmpty &&
                            _upcomingSessions.isEmpty &&
                            _nearbyAttendees.isEmpty &&
                            _activePolls.isEmpty &&
                            _announcements.isEmpty)
                          _buildQuietState(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(4, (_) => const ShimmerCard()),
    );
  }

  Widget _buildNoEventState() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 80, color: cs.onSurfaceVariant.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text(
              'No Events Today',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any events scheduled for today.\nExplore upcoming events to register!',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Discover Events'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietState() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.coffee_rounded, size: 64, color: cs.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'It\'s quiet here...',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No live sessions or activities right now.\nCheck back during the event!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ============ Event Context Card ============

class _EventContextCard extends StatelessWidget {
  final ZoneEvent event;
  final int attendeeCount;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _EventContextCard({
    required this.event,
    required this.attendeeCount,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withOpacity(0.15),
            cs.tertiary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.name,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.isHappeningNow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (event.venue != null) ...[
            const SizedBox(height: 4),
            Text(
              event.venue!,
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people_rounded, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '$attendeeCount here now',
                style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              if (event.isCheckedIn)
                Chip(
                  avatar: Icon(Icons.check_circle, size: 16, color: cs.primary),
                  label: const Text('Checked In'),
                  backgroundColor: cs.primary.withOpacity(0.1),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                )
              else
                FilledButton.tonal(
                  onPressed: onCheckIn,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Check In'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ Live Session Card ============

class _LiveSessionCard extends StatelessWidget {
  final EventSession session;

  const _LiveSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cs.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE NOW',
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (session.room != null)
                  Chip(
                    label: Text(session.room!),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (session.speakerName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: session.speakerAvatar != null
                        ? NetworkImage(session.speakerAvatar!)
                        : null,
                    child: session.speakerAvatar == null
                        ? Text(session.speakerName![0])
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session.speakerName!,
                    style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${session.minutesRemaining} min remaining',
                  style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    // TODO: Navigate to session or open stream
                  },
                  child: const Text('Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Upcoming Session Card ============

class _UpcomingSessionCard extends StatelessWidget {
  final EventSession session;

  const _UpcomingSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final timeFormat = '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}';

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timeFormat,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              session.title,
              style: textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.room != null)
            Text(
              session.room!,
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ============ Attendee Radar Card ============

class _AttendeeRadarCard extends StatelessWidget {
  final AttendeeRadar attendee;
  final VoidCallback onTap;

  const _AttendeeRadarCard({required this.attendee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: attendee.avatarUrl != null
                      ? NetworkImage(attendee.avatarUrl!)
                      : null,
                  child: attendee.avatarUrl == null
                      ? Text(
                          attendee.fullName.isNotEmpty ? attendee.fullName[0] : '?',
                          style: textTheme.titleMedium,
                        )
                      : null,
                ),
                if (attendee.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              attendee.fullName.split(' ').first,
              style: textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ More Attendees Card ============

class _MoreAttendeesCard extends StatelessWidget {
  final int count;

  const _MoreAttendeesCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.surfaceContainerHighest,
            child: Text(
              '+$count',
              style: textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'more',
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ============ Live Poll Card ============

class _LivePollCard extends StatelessWidget {
  final EventPoll poll;
  final Function(String) onVote;

  const _LivePollCard({required this.poll, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...poll.options.map((option) {
              final isSelected = poll.userVote == option.id;
              final percentage = poll.totalVotes > 0
                  ? (option.voteCount / poll.totalVotes * 100).round()
                  : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: poll.hasVoted ? null : () => onVote(option.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withOpacity(0.15)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: cs.primary)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.text,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                        if (poll.hasVoted) ...[
                          Text(
                            '$percentage%',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              '${poll.totalVotes} votes',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Announcement Card ============

class _AnnouncementCard extends StatelessWidget {
  final EventAnnouncement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(announcement.typeIcon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (announcement.isPinned)
                  Icon(Icons.push_pin, size: 16, color: cs.tertiary),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(announcement.createdAt),
              style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}';
  }
}

// ============ Shimmer Card ============

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ShimmerLoading(
        child: SizedBox(height: 120, width: double.infinity),
      ),
    );
  }
}
