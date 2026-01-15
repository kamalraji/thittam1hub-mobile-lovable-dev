import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';

/// Profile Tab - Main screen showing user profile, stats, and menu options
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _profileService = ProfileService();
  UserProfile? _profile;
  int _eventsAttended = 0;
  int _upcomingEvents = 0;
  int _savedEvents = 0;
  List<EventHistory> _eventHistory = [];
  bool _isLoading = true;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = await _profileService.getUserProfile(userId);
      final attended = await _profileService.getEventsAttendedCount(userId);
      final upcoming = await _profileService.getUpcomingEventsCount(userId);
      final saved = await _profileService.getSavedEventsCount(userId);
      final history = await _profileService.getEventHistory(userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _eventsAttended = attended;
          _upcomingEvents = upcoming;
          _savedEvents = saved;
          _eventHistory = history;
          _isLoading = false;
        });
        // Animate progress ring
        _progressController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseConfig.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final email = SupabaseConfig.auth.currentUser?.email ?? '';
    final completeness = _profile?.completeness ?? 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Profile Header
              _ProfileHeader(
                profile: _profile,
                email: email,
                completeness: completeness,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quick Stats
              _QuickStatsRow(
                eventsAttended: _eventsAttended,
                upcomingEvents: _upcomingEvents,
                savedEvents: _savedEvents,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Event History Section
              if (_eventHistory.isNotEmpty) ...[
                _EventHistorySection(eventHistory: _eventHistory),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Menu Items
              _MenuCard(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () async {
                  await context.push('/profile/edit');
                  _loadProfile(); // Refresh after edit
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                icon: Icons.qr_code,
                title: 'My QR Code',
                subtitle: 'For event check-in',
                onTap: () => context.push('/profile/qr'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                icon: Icons.confirmation_number_outlined,
                title: 'My Registrations',
                subtitle: '$_upcomingEvents upcoming',
                onTap: () => context.push('/profile/registrations'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                icon: Icons.favorite_border,
                title: 'Saved Events',
                subtitle: '$_savedEvents saved',
                onTap: () => context.push('/profile/saved'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MenuCard(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => context.push('/profile/settings'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _MenuCard(
                icon: Icons.logout,
                title: 'Log Out',
                textColor: AppColors.error,
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile header with animated ring, avatar, name, email, and completeness
class _ProfileHeader extends StatefulWidget {
  final UserProfile? profile;
  final String email;
  final int completeness;

  const _ProfileHeader({
    required this.profile,
    required this.email,
    required this.completeness,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.completeness / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completeness != widget.completeness) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.completeness / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.profile?.fullName ?? 'User';
    final organization = widget.profile?.organization;
    final avatarUrl = widget.profile?.avatarUrl;
    final showPrompt = widget.completeness < 80;

    return Column(
      children: [
        // Avatar with animated progress ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Animated progress ring
            SizedBox(
              width: 96,
              height: 96,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) => CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: 4,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      fullName[0].toUpperCase(),
                      style: context.textStyles.headlineMedium?.copyWith(color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Name
        Text(
          fullName,
          style: context.textStyles.headlineSmall?.bold,
          textAlign: TextAlign.center,
        ),

        // Organization
        if (organization != null) ...[
          const SizedBox(height: 4),
          Text(
            organization,
            style: context.textStyles.bodyMedium?.withColor(AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],

        // Email
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: context.textStyles.bodySmall?.withColor(AppColors.textMuted),
          textAlign: TextAlign.center,
        ),

        // Completeness with percentage badge
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: showPrompt ? AppColors.warning.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showPrompt ? Icons.info_outline : Icons.check_circle_outline,
                size: 16,
                color: showPrompt ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                showPrompt ? 'Complete your profile (${widget.completeness}%)' : 'Profile ${widget.completeness}% complete',
                style: context.textStyles.labelSmall?.semiBold.withColor(
                  showPrompt ? AppColors.warning : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Event History Section
class _EventHistorySection extends StatelessWidget {
  final List<EventHistory> eventHistory;

  const _EventHistorySection({required this.eventHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            'EVENT HISTORY',
            style: context.textStyles.labelSmall?.withColor(AppColors.textMuted),
          ),
        ),
        Card(
          child: Column(
            children: [
              if (eventHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No events attended yet',
                        style: context.textStyles.bodyMedium?.withColor(AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                ...eventHistory.take(3).map((event) => _EventHistoryCard(event: event)),
              if (eventHistory.length > 3)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to full history page
                    },
                    child: Text('View all ${eventHistory.length} events'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Event History Card
class _EventHistoryCard extends StatelessWidget {
  final EventHistory event;

  const _EventHistoryCard({required this.event});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/event/${event.eventId}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Event thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.border,
                child: event.bannerUrl != null
                    ? Image.network(
                        event.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.event,
                          color: AppColors.textMuted,
                        ),
                      )
                    : Icon(Icons.event, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Event info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventName,
                    style: context.textStyles.titleSmall?.semiBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(event.startDate),
                    style: context.textStyles.bodySmall?.withColor(AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Attended',
                      style: context.textStyles.labelSmall?.withColor(AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Quick stats row with three cards
class _QuickStatsRow extends StatelessWidget {
  final int eventsAttended;
  final int upcomingEvents;
  final int savedEvents;

  const _QuickStatsRow({
    required this.eventsAttended,
    required this.upcomingEvents,
    required this.savedEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Events\nAttended',
            value: eventsAttended.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'Upcoming\nEvents',
            value: upcomingEvents.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            label: 'Saved\nEvents',
            value: savedEvents.toString(),
          ),
        ),
      ],
    );
  }
}

/// Single stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              value,
              style: context.textStyles.headlineMedium?.bold.withColor(AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textStyles.labelSmall?.withColor(AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu card with icon, title, subtitle, and chevron
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleMedium?.withColor(textColor ?? AppColors.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textStyles.bodySmall?.withColor(AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
