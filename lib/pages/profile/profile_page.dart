import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/supabase/gamification_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/utils/hero_animations.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile Tab - Main screen showing user profile, stats, and menu options
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _profileService = ProfileService();
  final _gamificationService = GamificationService();
  UserProfile? _profile;
  int _eventsAttended = 0;
  int _upcomingEvents = 0;
  int _savedEvents = 0;
  List<EventHistory> _eventHistory = [];
  List<BadgeItem> _earnedBadges = [];
  List<String> _myBadgeIds = [];
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

    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _profileService.getUserProfile(userId),
        _profileService.getEventsAttendedCount(userId),
        _profileService.getUpcomingEventsCount(userId),
        _profileService.getSavedEventsCount(userId),
        _profileService.getEventHistory(userId),
        _gamificationService.getAllBadges(),
        _gamificationService.getMyBadgeIds(),
      ]);

      if (mounted) {
        final allBadges = results[5] as List<BadgeItem>;
        final myBadgeIds = results[6] as List<String>;
        final earnedBadges = allBadges.where((b) => myBadgeIds.contains(b.id)).toList();
        
        setState(() {
          _profile = results[0] as UserProfile?;
          _eventsAttended = results[1] as int;
          _upcomingEvents = results[2] as int;
          _savedEvents = results[3] as int;
          _eventHistory = results[4] as List<EventHistory>;
          _earnedBadges = earnedBadges;
          _myBadgeIds = myBadgeIds;
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

  void _showQuickActionsSheet() {
    showGlassBottomSheet(
      context: context,
      title: 'Quick Actions',
      child: GlassActionList(
        actions: [
          GlassActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () async {
              Navigator.pop(context);
              await context.push('/profile/edit');
              _loadProfile();
            },
          ),
          GlassActionButton(
            icon: Icons.qr_code,
            label: 'Show QR Code',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile/qr');
            },
          ),
          GlassActionButton(
            icon: Icons.share,
            label: 'Share Profile',
            onTap: () {
              Navigator.pop(context);
              _shareProfile();
            },
          ),
          GlassActionButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile/settings');
            },
          ),
        ],
      ),
    );
  }

  void _shareProfile() {
    HapticFeedback.lightImpact();
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null || _profile == null) return;
    
    // Generate deep link URL
    final profileUrl = 'https://thittam1hub.app/profile/$userId';
    final shareText = '${_profile!.fullName ?? 'Check out my profile'} on Thittam1Hub\n\n$profileUrl';
    
    Share.share(
      shareText,
      subject: 'My Thittam1Hub Profile',
    );
  }
  
  void _copyProfileLink() {
    HapticFeedback.mediumImpact();
    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) return;
    
    final profileUrl = 'https://thittam1hub.app/profile/$userId';
    Clipboard.setData(ClipboardData(text: profileUrl));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            final uri = Uri.parse(profileUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const ProfileHeaderSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              const QuickStatsRowSkeleton(),
              const SizedBox(height: AppSpacing.lg),
              ...List.generate(5, (index) => FadeSlideTransition(
                delay: staggerDelay(index),
                child: const MenuCardSkeleton(),
              )),
            ],
          ),
        ),
      );
    }

    final email = SupabaseConfig.auth.currentUser?.email ?? '';
    final completeness = _profile?.completeness ?? 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsSheet,
        child: const Icon(Icons.bolt),
      ),
      body: SafeArea(
        child: BrandedRefreshIndicator(
          onRefresh: _loadProfile,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Profile Header with Hero animation
              _ProfileHeader(
                profile: _profile,
                email: email,
                completeness: completeness,
              ),
              const SizedBox(height: AppSpacing.md),

              // Social Links Row
              if (_profile != null)
                _SocialLinksRow(profile: _profile!),
              const SizedBox(height: AppSpacing.lg),

              // Quick Stats with responsive layout
              _QuickStatsRow(
                eventsAttended: _eventsAttended,
                upcomingEvents: _upcomingEvents,
                savedEvents: _savedEvents,
                completeness: completeness,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Badge Showcase Section
              if (_earnedBadges.isNotEmpty) ...[
                _BadgeShowcaseSection(
                  earnedBadges: _earnedBadges,
                  onViewAll: () => context.push('/impact'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Event History Section
              if (_eventHistory.isNotEmpty) ...[
                _EventHistorySection(eventHistory: _eventHistory),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Menu Items with staggered animation
              ..._buildMenuItems(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final menuItems = [
      (Icons.edit_outlined, 'Edit Profile', null, () async {
        await context.push('/profile/edit');
        _loadProfile();
      }),
      (Icons.qr_code, 'My QR Code', 'For event check-in', () => context.push('/profile/qr')),
      (Icons.confirmation_number_outlined, 'My Registrations', '$_upcomingEvents upcoming', () => context.push('/profile/registrations')),
      (Icons.favorite_border, 'Saved Events', '$_savedEvents saved', () => context.push('/profile/saved')),
      (Icons.settings_outlined, 'Settings', null, () => context.push('/profile/settings')),
    ];

    return [
      ...menuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return FadeSlideTransition(
          delay: staggerDelay(index),
          child: Column(
            children: [
              _MenuCard(
                icon: item.$1,
                title: item.$2,
                subtitle: item.$3,
                onTap: item.$4,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      }),
      FadeSlideTransition(
        delay: staggerDelay(menuItems.length),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            _MenuCard(
              icon: Icons.logout,
              title: 'Log Out',
              textColor: AppColors.error,
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    ];
  }
}

/// Social links row with icon buttons
class _SocialLinksRow extends StatelessWidget {
  final UserProfile profile;

  const _SocialLinksRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final links = <(IconData, String?, String)>[
      (Icons.language, profile.website, 'Website'),
      (Icons.business, profile.linkedinUrl, 'LinkedIn'),
      (Icons.alternate_email, profile.twitterUrl, 'X'),
      (Icons.code, profile.githubUrl, 'GitHub'),
    ].where((link) => link.$2 != null && link.$2!.isNotEmpty).toList();

    if (links.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: links.map((link) => _SocialIconButton(
        icon: link.$1,
        url: link.$2!,
        tooltip: link.$3,
      )).toList(),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final String url;
  final String tooltip;

  const _SocialIconButton({
    required this.icon,
    required this.url,
    required this.tooltip,
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: cs.primary),
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
    final cs = Theme.of(context).colorScheme;

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
                  backgroundColor: cs.outline.withValues(alpha: 0.3),
                  color: cs.primary,
                ),
              ),
            ),
            // Avatar with Hero animation
            AnimatedHero(
              tag: HeroConfig.profileAvatarTag(widget.profile?.id ?? 'avatar'),
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
            style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],

        // Email
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        // Completeness with percentage badge
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: showPrompt 
                ? AppColors.warning.withValues(alpha: 0.1) 
                : cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showPrompt ? Icons.info_outline : Icons.check_circle_outline,
                size: 16,
                color: showPrompt ? AppColors.warning : cs.primary,
              ),
              const SizedBox(width: 6),
              Text(
                showPrompt ? 'Complete your profile (${widget.completeness}%)' : 'Profile ${widget.completeness}% complete',
                style: context.textStyles.labelSmall?.semiBold.withColor(
                  showPrompt ? AppColors.warning : cs.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Badge Showcase Section with glassmorphism styling
class _BadgeShowcaseSection extends StatelessWidget {
  final List<BadgeItem> earnedBadges;
  final VoidCallback onViewAll;

  const _BadgeShowcaseSection({
    required this.earnedBadges,
    required this.onViewAll,
  });

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'LEGENDARY':
        return const Color(0xFFFFD700); // Gold
      case 'EPIC':
        return const Color(0xFF9C27B0); // Purple
      case 'RARE':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF4CAF50); // Green for COMMON
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayBadges = earnedBadges.take(4).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'ACHIEVEMENTS',
                    style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${earnedBadges.length}',
                      style: context.textStyles.labelSmall?.semiBold.withColor(cs.primary),
                    ),
                  ),
                ],
              ),
              if (earnedBadges.length > 4)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        // Glassmorphism badge container
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.surfaceContainerHighest.withValues(alpha: 0.8),
                    cs.surfaceContainerHigh.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Badge grid
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    alignment: WrapAlignment.center,
                    children: displayBadges.map((badge) => _BadgeCard(
                      badge: badge,
                      rarityColor: _getRarityColor(badge.rarity),
                    )).toList(),
                  ),
                  // Empty state placeholder
                  if (earnedBadges.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Icon(Icons.military_tech_outlined, size: 48, color: cs.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No badges earned yet',
                            style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Connect with others in Impact Hub to earn badges!',
                            style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual badge card with glassmorphism effect
class _BadgeCard extends StatelessWidget {
  final BadgeItem badge;
  final Color rarityColor;

  const _BadgeCard({
    required this.badge,
    required this.rarityColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(context),
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rarityColor.withValues(alpha: 0.15),
              rarityColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: rarityColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge icon with glow
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    rarityColor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  badge.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Badge name
            Text(
              badge.name,
              style: context.textStyles.labelSmall?.semiBold.withColor(cs.onSurface),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    showGlassBottomSheet(
      context: context,
      title: badge.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large badge icon with animated glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  rarityColor.withValues(alpha: 0.4),
                  rarityColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Rarity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: rarityColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              badge.rarity,
              style: context.textStyles.labelSmall?.semiBold.withColor(rarityColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Description
          Text(
            badge.description,
            style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Category
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                badge.category,
                style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Event History Section
class _EventHistorySection extends StatelessWidget {
  final List<EventHistory> eventHistory;

  const _EventHistorySection({required this.eventHistory});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(
            'EVENT HISTORY',
            style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
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
                      Icon(Icons.event_busy, size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No events attended yet',
                        style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
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
    final cs = Theme.of(context).colorScheme;
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
                color: cs.surfaceContainerHighest,
                child: event.bannerUrl != null
                    ? Image.network(
                        event.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.event,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Icon(Icons.event, color: cs.onSurfaceVariant),
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
                    style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
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
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Quick stats row with responsive layout
class _QuickStatsRow extends StatelessWidget {
  final int eventsAttended;
  final int upcomingEvents;
  final int savedEvents;
  final int completeness;

  const _QuickStatsRow({
    required this.eventsAttended,
    required this.upcomingEvents,
    required this.savedEvents,
    required this.completeness,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        if (isWide) {
          // Tablet: 4-column layout with profile completeness
          return Row(
            children: [
              Expanded(child: _StatCard(label: 'Events\nAttended', value: eventsAttended.toString())),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Upcoming\nEvents', value: upcomingEvents.toString())),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Saved\nEvents', value: savedEvents.toString())),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Profile\nComplete', value: '$completeness%')),
            ],
          );
        }
        
        // Mobile: 3-column layout
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
      },
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              value,
              style: context.textStyles.headlineMedium?.bold.withColor(cs.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textStyles.labelSmall?.withColor(cs.onSurfaceVariant),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: textColor ?? cs.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleMedium?.withColor(textColor ?? cs.onSurface),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
