import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/profile_stats.dart';
import 'package:thittam1hub/models/profile_post.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/services/saved_events_service.dart';
import 'package:thittam1hub/services/connections_service.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/animated_stat_counter.dart';
import 'package:thittam1hub/widgets/cover_banner.dart';
import 'package:thittam1hub/widgets/cover_image_picker.dart';
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
  final _savedEventsService = SavedEventsService();
  final _connectionsService = ConnectionsService();
  
  UserProfile? _profile;
  ProfileStats _stats = const ProfileStats();
  List<ProfilePost> _posts = [];
  List<EventHistory> _eventHistory = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<BadgeItem> _earnedBadges = [];
  List<String> _myBadgeIds = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  
  // Quick action counts
  int _savedEventsCount = 0;
  int _connectionsCount = 0;
  int _ticketsCount = 0;
  
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
        _savedEventsService.getSavedEventsCount(),
        _connectionsService.getAcceptedConnections(),
        _profileService.getTicketsCount(userId),
      ]);

      if (mounted) {
        final allBadges = results[5] as List<BadgeItem>;
        final myBadgeIds = results[6] as List<String>;
        final earnedBadges = allBadges.where((b) => myBadgeIds.contains(b.id)).toList();
        final connections = results[8] as List;
        
        setState(() {
          _profile = results[0] as UserProfile?;
          _stats = results[1] as ProfileStats;
          _posts = results[2] as List<ProfilePost>;
          _eventHistory = results[3] as List<EventHistory>;
          _upcomingEvents = results[4] as List<Map<String, dynamic>>;
          _earnedBadges = earnedBadges;
          _myBadgeIds = myBadgeIds;
          _savedEventsCount = results[7] as int;
          _connectionsCount = connections.length;
          _ticketsCount = results[9] as int;
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
        onSavedEvents: () {
          Navigator.pop(context);
          context.push('/profile/saved');
        },
        onConnections: () {
          Navigator.pop(context);
          context.push('/profile/connections');
        },
        onTickets: () {
          Navigator.pop(context);
          context.push('/profile/tickets');
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

  void _showCoverPicker() {
    HapticFeedback.lightImpact();
    showCoverImagePicker(
      context: context,
      currentImageUrl: _profile?.coverImageUrl,
      currentGradientId: _profile?.coverGradientId,
      onSelectGradient: _handleGradientSelect,
      onSelectImage: _handleCoverUpload,
      onRemove: _handleCoverRemove,
    );
  }

  Future<void> _handleGradientSelect(String gradientId) async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _profileService.setCoverGradient(userId, gradientId);
      setState(() {
        _profile = _profile?.copyWith(
          coverGradientId: gradientId,
          coverImageUrl: null,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update cover: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCoverUpload(Uint8List bytes, String fileName) async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading cover...')),
    );

    try {
      final coverUrl = await _profileService.uploadCoverImage(userId, bytes, fileName);
      if (coverUrl != null) {
        // Update profile with new cover URL
        final updatedProfile = _profile!.copyWith(
          coverImageUrl: coverUrl,
          coverGradientId: null,
        );
        await _profileService.updateUserProfile(updatedProfile);
        setState(() => _profile = updatedProfile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cover uploaded'), backgroundColor: AppColors.success),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload cover: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCoverRemove() async {
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Delete from storage if custom image
      if (_profile?.coverImageUrl != null) {
        await _profileService.deleteCoverImage(userId, _profile!.coverImageUrl!);
      }
      // Clear both cover fields
      await _profileService.setCoverGradient(userId, null);
      setState(() {
        _profile = _profile?.copyWith(
          coverImageUrl: null,
          coverGradientId: null,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover removed')),
        );
      }
    } catch (e) {
      debugPrint('Failed to remove cover: $e');
    }
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
                    // Quick Actions Row
                    _QuickActionsRow(
                      ticketsCount: _ticketsCount,
                      savedCount: _savedEventsCount,
                      connectionsCount: _connectionsCount,
                      onTickets: () => context.push('/profile/tickets'),
                      onSaved: () => context.push('/profile/saved'),
                      onConnections: () => context.push('/profile/connections'),
                      onQrCode: () => context.push('/profile/qr-code'),
                    ),
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
    
    // Get gradient colors if gradient is set
    List<Color>? gradientColors;
    if (_profile?.coverGradientId != null) {
      final theme = CoverGradientTheme.presets.where((t) => t.id == _profile!.coverGradientId).firstOrNull;
      gradientColors = theme?.colors;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CoverBanner(
          imageUrl: _profile?.coverImageUrl,
          gradientColors: gradientColors,
          height: 120,
          showEditButton: true,
          onEditTap: _showCoverPicker,
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
// QUICK ACTIONS ROW
// =============================================================================

class _QuickActionsRow extends StatelessWidget {
  final int ticketsCount;
  final int savedCount;
  final int connectionsCount;
  final VoidCallback onTickets;
  final VoidCallback onSaved;
  final VoidCallback onConnections;
  final VoidCallback onQrCode;

  const _QuickActionsRow({
    required this.ticketsCount,
    required this.savedCount,
    required this.connectionsCount,
    required this.onTickets,
    required this.onSaved,
    required this.onConnections,
    required this.onQrCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _QuickActionChip(
              icon: Icons.confirmation_number_outlined,
              label: 'Tickets',
              count: ticketsCount,
              onTap: onTickets,
            ),
            const SizedBox(width: 8),
            _QuickActionChip(
              icon: Icons.bookmark_outline,
              label: 'Saved',
              count: savedCount,
              onTap: onSaved,
            ),
            const SizedBox(width: 8),
            _QuickActionChip(
              icon: Icons.people_outline,
              label: 'Connections',
              count: connectionsCount,
              onTap: onConnections,
            ),
            const SizedBox(width: 8),
            _QuickActionChip(
              icon: Icons.qr_code,
              label: 'QR Code',
              onTap: onQrCode,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textStyles.labelMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
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

class _BioSection extends StatelessWidget {
  final UserProfile profile;

  const _BioSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.bio!,
            style: context.textStyles.bodyMedium?.copyWith(
              color: cs.onSurface,
            ),
          ),
          if (_hasSocialLinks()) ...[
            const SizedBox(height: 12),
            _SocialLinksRow(profile: profile),
          ],
        ],
      ),
    );
  }

  bool _hasSocialLinks() =>
      (profile.website != null && profile.website!.isNotEmpty) ||
      (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty) ||
      (profile.twitterUrl != null && profile.twitterUrl!.isNotEmpty) ||
      (profile.githubUrl != null && profile.githubUrl!.isNotEmpty);
}

class _SocialLinksRow extends StatelessWidget {
  final UserProfile profile;

  const _SocialLinksRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final links = <Widget>[];

    if (profile.website != null && profile.website!.isNotEmpty) {
      links.add(_SocialLink(
        icon: Icons.language,
        label: 'Website',
        url: profile.website!,
      ));
    }
    if (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty) {
      links.add(_SocialLink(
        icon: Icons.work_outline,
        label: 'LinkedIn',
        url: profile.linkedinUrl!,
      ));
    }
    if (profile.twitterUrl != null && profile.twitterUrl!.isNotEmpty) {
      links.add(_SocialLink(
        icon: Icons.alternate_email,
        label: 'Twitter',
        url: profile.twitterUrl!,
      ));
    }
    if (profile.githubUrl != null && profile.githubUrl!.isNotEmpty) {
      links.add(_SocialLink(
        icon: Icons.code,
        label: 'GitHub',
        url: profile.githubUrl!,
      ));
    }

    return Wrap(spacing: 8, runSpacing: 8, children: links);
  }
}

class _SocialLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: cs.primary,
              ),
            ),
          ],
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

  const _TabBarDelegate({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ProfileTabBar(
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex;
}

// =============================================================================
// TAB CONTENT WIDGETS
// =============================================================================

class _PostsTabContent extends StatelessWidget {
  final List<ProfilePost> posts;

  const _PostsTabContent({required this.posts});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (posts.isEmpty) {
      return _EmptyTabContent(
        icon: Icons.grid_view_outlined,
        title: 'No posts yet',
        subtitle: 'Share your first spark to get started',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                post.content.substring(0, post.content.length.clamp(0, 50)),
                textAlign: TextAlign.center,
                style: context.textStyles.labelSmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventsTabContent extends StatelessWidget {
  final List<Map<String, dynamic>> upcoming;
  final List<EventHistory> history;

  const _EventsTabContent({
    required this.upcoming,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (upcoming.isEmpty && history.isEmpty) {
      return _EmptyTabContent(
        icon: Icons.event_outlined,
        title: 'No events yet',
        subtitle: 'Register for events to see them here',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (upcoming.isNotEmpty) ...[
            Text(
              'UPCOMING',
              style: context.textStyles.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...upcoming.map((e) => _EventTile(
              name: e['events']?['name'] ?? 'Event',
              date: DateTime.tryParse(e['events']?['start_date'] ?? '') ?? DateTime.now(),
              bannerUrl: e['events']?['branding']?['banner_url'],
              isUpcoming: true,
            )),
            const SizedBox(height: 16),
          ],
          if (history.isNotEmpty) ...[
            Text(
              'PAST EVENTS',
              style: context.textStyles.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ...history.take(5).map((e) => _EventTile(
              name: e.eventName,
              date: e.startDate,
              bannerUrl: e.bannerUrl,
              isUpcoming: false,
            )),
          ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final String name;
  final DateTime date;
  final String? bannerUrl;
  final bool isUpcoming;

  const _EventTile({
    required this.name,
    required this.date,
    this.bannerUrl,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUpcoming ? cs.primary.withValues(alpha: 0.1) : cs.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  months[date.month - 1].toUpperCase(),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: isUpcoming ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date.day.toString(),
                  style: context.textStyles.titleMedium?.copyWith(
                    color: isUpcoming ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${months[date.month - 1]} ${date.day}, ${date.year}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _BadgesTabContent extends StatelessWidget {
  final List<BadgeItem> badges;
  final List<String> allBadgeIds;

  const _BadgesTabContent({
    required this.badges,
    required this.allBadgeIds,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return _EmptyTabContent(
        icon: Icons.emoji_events_outlined,
        title: 'No badges yet',
        subtitle: 'Participate in events to earn badges',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return _BadgeTile(badge: badge);
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeItem badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              badge.icon,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          style: context.textStyles.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutSection(
            title: 'Quick Links',
            child: Column(
              children: [
                _QuickLinkTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                _QuickLinkTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => context.push('/profile/settings'),
                ),
                _QuickLinkTile(
                  icon: Icons.qr_code,
                  label: 'My QR Code',
                  onTap: () => context.push('/profile/qr-code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AboutSection(
            title: 'Statistics',
            child: Column(
              children: [
                _StatDetailRow(label: 'Events Attended', value: stats.eventsAttended.toString()),
                _StatDetailRow(label: 'Upcoming Events', value: stats.upcomingEvents.toString()),
                _StatDetailRow(label: 'Connections', value: stats.connectionsCount.toString()),
                _StatDetailRow(label: 'Posts', value: stats.postsCount.toString()),
                _StatDetailRow(label: 'Current Streak', value: '${stats.currentStreak} days'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: Icon(Icons.logout, color: AppColors.error),
              label: Text('Log Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EmptyTabContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTabContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: context.textStyles.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.textStyles.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
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
  final VoidCallback onSavedEvents;
  final VoidCallback onConnections;
  final VoidCallback onTickets;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  const _MoreOptionsSheet({
    required this.onEditProfile,
    required this.onSavedEvents,
    required this.onConnections,
    required this.onTickets,
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
              icon: Icons.bookmark_outline,
              label: 'Saved Events',
              onTap: onSavedEvents,
            ),
            _OptionTile(
              icon: Icons.people_outline,
              label: 'Connections',
              onTap: onConnections,
            ),
            _OptionTile(
              icon: Icons.confirmation_number_outlined,
              label: 'My Tickets',
              onTap: onTickets,
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
