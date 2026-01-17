import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/profile_stats.dart';
import 'package:thittam1hub/models/profile_post.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/animated_stat_counter.dart';
import 'package:thittam1hub/widgets/cover_banner.dart';
import 'package:thittam1hub/widgets/profile_tab_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile Tab - Reddit/Instagram inspired design with tabs
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final _profileService = ProfileService();
  final _gamificationService = GamificationService();
  
  UserProfile? _profile;
  ProfileStats _stats = const ProfileStats();
  List<ProfilePost> _posts = [];
  List<EventHistory> _eventHistory = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<BadgeItem> _earnedBadges = [];
  List<String> _myBadgeIds = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _profileService.getUserProfile(userId),
        _profileService.getProfileStats(userId),
        _profileService.getUserPosts(userId),
        _profileService.getEventHistory(userId),
        _profileService.getUpcomingEvents(userId),
        _gamificationService.getAllBadges(),
        _gamificationService.getMyBadgeIds(),
      ]);

      if (mounted) {
        final allBadges = results[5] as List<BadgeItem>;
        final myBadgeIds = results[6] as List<String>;
        final earnedBadges = allBadges.where((b) => myBadgeIds.contains(b.id)).toList();
        
        setState(() {
          _profile = results[0] as UserProfile?;
          _stats = results[1] as ProfileStats;
          _posts = results[2] as List<ProfilePost>;
          _eventHistory = results[3] as List<EventHistory>;
          _upcomingEvents = results[4] as List<Map<String, dynamic>>;
          _earnedBadges = earnedBadges;
          _myBadgeIds = myBadgeIds;
          _isLoading = false;
        });
        _headerController.forward();
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

  void _shareProfile() {
    HapticFeedback.lightImpact();
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null || _profile == null) return;
    
    final profileUrl = 'https://thittam1hub.app/profile/$userId';
    final shareText = '${_profile!.fullName ?? 'Check out my profile'} on Thittam1Hub\n\n$profileUrl';
    
    Share.share(shareText, subject: 'My Thittam1Hub Profile');
  }

  void _showMoreOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(
        onEditProfile: () {
          Navigator.pop(context);
          context.push('/profile/edit').then((_) => _loadProfile());
        },
        onSettings: () {
          Navigator.pop(context);
          context.push('/profile/settings');
        },
        onLogout: () {
          Navigator.pop(context);
          _handleLogout();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            // Cover Banner + Profile Header
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerAnimation,
                child: Column(
                  children: [
                    // Cover Banner with avatar overlap
                    _buildCoverWithAvatar(),
                    // Profile Info
                    _ProfileInfoSection(
                      profile: _profile,
                      onShare: _shareProfile,
                      onEdit: () => context.push('/profile/edit').then((_) => _loadProfile()),
                      onMore: _showMoreOptions,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Stats Row
                    _StatsRow(stats: _stats),
                    const SizedBox(height: AppSpacing.md),
                    // Bio Section
                    if (_profile?.bio != null && _profile!.bio!.isNotEmpty)
                      _BioSection(profile: _profile!),
                  ],
                ),
              ),
            ),
            // Tab Bar (Sticky)
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabs: const [
                  ProfileTabItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Posts'),
                  ProfileTabItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Events'),
                  ProfileTabItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Badges'),
                  ProfileTabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'About'),
                ],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) => setState(() => _selectedTabIndex = index),
              ),
            ),
            // Tab Content
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverWithAvatar() {
    final cs = Theme.of(context).colorScheme;
    final avatarUrl = _profile?.avatarUrl;
    final fullName = _profile?.fullName ?? 'User';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CoverBanner(
          height: 120,
          showEditButton: true,
          onEditTap: () => context.push('/profile/edit'),
        ),
        // Avatar positioned to overlap banner
        Positioned(
          left: 16,
          bottom: -40,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cs.primary,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      fullName[0].toUpperCase(),
                      style: context.textStyles.headlineMedium?.copyWith(color: cs.onPrimary),
                    )
                  : null,
            ),
          ),
        ),
        // Spacing for overlap
        const SizedBox(height: 160),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _PostsTabContent(posts: _posts);
      case 1:
        return _EventsTabContent(
          upcoming: _upcomingEvents,
          history: _eventHistory,
        );
      case 2:
        return _BadgesTabContent(badges: _earnedBadges, allBadgeIds: _myBadgeIds);
      case 3:
        return _AboutTabContent(
          profile: _profile,
          stats: _stats,
          onLogout: _handleLogout,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// =============================================================================
// PROFILE INFO SECTION
// =============================================================================

class _ProfileInfoSection extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const _ProfileInfoSection({
    required this.profile,
    required this.onShare,
    required this.onEdit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fullName = profile?.fullName ?? 'User';
    final email = SupabaseConfig.auth.currentUser?.email ?? '';
    final handle = '@${email.split('@').first}';
    final organization = profile?.organization;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Actions Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: context.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  _ActionChip(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                    isPrimary: true,
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.share_outlined,
                    onTap: onShare,
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.more_horiz,
                    onTap: onMore,
                  ),
                ],
              ),
            ],
          ),
          // Organization/Headline
          if (organization != null && organization.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    organization,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// STATS ROW - Instagram style
// =============================================================================

class _StatsRow extends StatelessWidget {
  final ProfileStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(value: stats.impactScore, label: 'Impact', icon: '⚡'),
            _Divider(),
            _StatItem(value: stats.eventsAttended, label: 'Events', icon: '📅'),
            _Divider(),
            _StatItem(value: stats.badgesEarned, label: 'Badges', icon: '🏆'),
            _Divider(),
            _StatItem(value: stats.currentStreak, label: 'Streak', icon: '🔥'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final String icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            AnimatedStatCounter(
              value: value,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
    );
  }
}

// =============================================================================
// BIO SECTION
// =============================================================================

class _BioSection extends StatefulWidget {
  final UserProfile profile;

  const _BioSection({required this.profile});

  @override
  State<_BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends State<_BioSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bio = widget.profile.bio ?? '';
    final isLong = bio.length > 150;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            firstChild: Text(
              bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium,
            ),
            secondChild: Text(
              bio,
              style: context.textStyles.bodyMedium,
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _expanded ? 'Show less' : 'Read more',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Social Links
          const SizedBox(height: 12),
          _SocialLinksRow(profile: widget.profile),
        ],
      ),
    );
  }
}

class _SocialLinksRow extends StatelessWidget {
  final UserProfile profile;

  const _SocialLinksRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final links = <(IconData, String?, String, Color)>[
      (Icons.language, profile.website, 'Website', AppColors.primary),
      (Icons.business, profile.linkedinUrl, 'LinkedIn', const Color(0xFF0A66C2)),
      (Icons.alternate_email, profile.twitterUrl, 'X', Colors.black87),
      (Icons.code, profile.githubUrl, 'GitHub', const Color(0xFF6e5494)),
    ].where((link) => link.$2 != null && link.$2!.isNotEmpty).toList();

    if (links.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: links.map((link) => _SocialChip(
        icon: link.$1,
        url: link.$2!,
        label: link.$3,
        color: link.$4,
      )).toList(),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String url;
  final String label;
  final Color color;

  const _SocialChip({
    required this.icon,
    required this.url,
    required this.label,
    required this.color,
  });

  Future<void> _launchUrl() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayColor = isDark ? color.withValues(alpha: 0.8) : color;

    return Material(
      color: displayColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _launchUrl,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: displayColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: displayColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB BAR DELEGATE
// =============================================================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final List<ProfileTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  _TabBarDelegate({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: ProfileTabBar(
        tabs: tabs,
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex;
  }
}

// =============================================================================
// POSTS TAB CONTENT
// =============================================================================

class _PostsTabContent extends StatelessWidget {
  final List<ProfilePost> posts;

  const _PostsTabContent({required this.posts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.edit_note, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No posts yet',
              style: context.textStyles.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share your first spark!',
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PostCard(post: post);
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final ProfilePost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge and date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.type,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(post.createdAt),
                style: context.textStyles.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            post.title,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Content preview
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              post.content,
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Stats
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bolt, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${post.likesCount}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chat_bubble_outline, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${post.commentsCount}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// =============================================================================
// EVENTS TAB CONTENT
// =============================================================================

class _EventsTabContent extends StatelessWidget {
  final List<Map<String, dynamic>> upcoming;
  final List<EventHistory> history;

  const _EventsTabContent({
    required this.upcoming,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasContent = upcoming.isNotEmpty || history.isNotEmpty;

    if (!hasContent) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No events yet',
              style: context.textStyles.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Discover and register for events!',
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/events'),
              icon: const Icon(Icons.explore, size: 18),
              label: const Text('Explore Events'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming Events
          if (upcoming.isNotEmpty) ...[
            Text(
              'Upcoming',
              style: context.textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...upcoming.take(3).map((event) => _EventCard(
              event: event['events'] as Map<String, dynamic>,
              isUpcoming: true,
            )),
            const SizedBox(height: 16),
          ],
          // Past Events
          if (history.isNotEmpty) ...[
            Text(
              'Attended',
              style: context.textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: history.length > 6 ? 6 : history.length,
              itemBuilder: (context, index) {
                final event = history[index];
                return _EventGridCard(event: event);
              },
            ),
            if (history.length > 6) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/profile/tickets'),
                  child: Text('View All (${history.length})'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isUpcoming;

  const _EventCard({required this.event, this.isUpcoming = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = event['name'] ?? 'Event';
    final startDate = DateTime.tryParse(event['start_date'] ?? '') ?? DateTime.now();
    final branding = event['branding'] as Map<String, dynamic>?;
    final bannerUrl = branding?['banner_url'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Event thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: cs.primary.withValues(alpha: 0.1),
              child: bannerUrl != null
                  ? Image.network(bannerUrl, fit: BoxFit.cover)
                  : Icon(Icons.event, color: cs.primary),
            ),
          ),
          const SizedBox(width: 12),
          // Event info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatEventDate(startDate),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          if (isUpcoming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Registered',
                style: context.textStyles.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _EventGridCard extends StatelessWidget {
  final EventHistory event;

  const _EventGridCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event banner
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                color: cs.primary.withValues(alpha: 0.1),
                child: event.bannerUrl != null
                    ? Image.network(event.bannerUrl!, fit: BoxFit.cover)
                    : Center(child: Icon(Icons.event, size: 32, color: cs.primary)),
              ),
            ),
          ),
          // Event info
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventName,
                  style: context.textStyles.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(event.startDate),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// =============================================================================
// BADGES TAB CONTENT
// =============================================================================

class _BadgesTabContent extends StatelessWidget {
  final List<BadgeItem> badges;
  final List<String> allBadgeIds;

  const _BadgesTabContent({required this.badges, required this.allBadgeIds});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (badges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.emoji_events, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No badges yet',
              style: context.textStyles.titleMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start earning badges by participating!',
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Group by rarity
    final grouped = <String, List<BadgeItem>>{};
    for (final badge in badges) {
      grouped.putIfAbsent(badge.rarity, () => []).add(badge);
    }

    final rarityOrder = ['LEGENDARY', 'EPIC', 'RARE', 'COMMON'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rarity in rarityOrder)
            if (grouped.containsKey(rarity)) ...[
              _BadgeRaritySection(
                rarity: rarity,
                badges: grouped[rarity]!,
              ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class _BadgeRaritySection extends StatelessWidget {
  final String rarity;
  final List<BadgeItem> badges;

  const _BadgeRaritySection({required this.rarity, required this.badges});

  Color get _rarityColor {
    switch (rarity.toUpperCase()) {
      case 'LEGENDARY':
        return const Color(0xFFFFD700);
      case 'EPIC':
        return const Color(0xFF9B59B6);
      case 'RARE':
        return const Color(0xFF3498DB);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _rarityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              rarity.toUpperCase(),
              style: context.textStyles.labelMedium?.copyWith(
                color: _rarityColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${badges.length})',
              style: context.textStyles.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeCard(badge: badge, rarityColor: _rarityColor);
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeItem badge;
  final Color rarityColor;

  const _BadgeCard({required this.badge, required this.rarityColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rarityColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.icon,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: context.textStyles.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ABOUT TAB CONTENT
// =============================================================================

class _AboutTabContent extends StatelessWidget {
  final UserProfile? profile;
  final ProfileStats stats;
  final VoidCallback onLogout;

  const _AboutTabContent({
    required this.profile,
    required this.stats,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Links Section
          _AboutSection(
            title: 'Quick Links',
            child: Column(
              children: [
                _QuickLinkTile(
                  icon: Icons.confirmation_number_outlined,
                  label: 'My Tickets',
                  subtitle: '${stats.upcomingEvents} upcoming',
                  onTap: () => context.push('/profile/tickets'),
                ),
                _QuickLinkTile(
                  icon: Icons.qr_code,
                  label: 'My QR Code',
                  subtitle: 'For event check-in',
                  onTap: () => context.push('/profile/qr'),
                ),
                _QuickLinkTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.push('/profile/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats Details
          _AboutSection(
            title: 'Activity Stats',
            child: Column(
              children: [
                _StatDetailRow(label: 'Total Events', value: '${stats.eventsAttended}'),
                _StatDetailRow(label: 'Connections', value: '${stats.connectionsCount}'),
                _StatDetailRow(label: 'Posts', value: '${stats.postsCount}'),
                _StatDetailRow(label: 'Longest Streak', value: '${stats.longestStreak} days'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // App Info
          Center(
            child: Text(
              'Thittam1Hub v1.0.0',
              style: context.textStyles.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _AboutSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textStyles.bodyMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StatDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textStyles.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: isPrimary ? cs.primary : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: context.textStyles.labelMedium?.copyWith(
                  color: isPrimary ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _MoreOptionsSheet({
    required this.onEditProfile,
    required this.onSettings,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: onEditProfile,
            ),
            _OptionTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: onSettings,
            ),
            Divider(color: cs.outline.withValues(alpha: 0.2)),
            _OptionTile(
              icon: Icons.logout,
              label: 'Log Out',
              isDestructive: true,
              onTap: onLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isDestructive ? AppColors.error : cs.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: context.textStyles.bodyLarge?.copyWith(color: color),
      ),
      onTap: onTap,
    );
  }
}
