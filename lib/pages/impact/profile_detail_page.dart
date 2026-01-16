import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/models/work_experience.dart';
import 'package:thittam1hub/models/portfolio_project.dart';
import 'package:thittam1hub/models/skill_endorsement.dart';
import 'package:thittam1hub/supabase/impact_service.dart';
import 'package:thittam1hub/supabase/professional_service.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/hero_animations.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
import 'package:thittam1hub/widgets/work_experience_timeline.dart';
import 'package:thittam1hub/widgets/portfolio_showcase.dart';
import 'package:thittam1hub/widgets/skill_endorsements.dart';

class ProfileDetailPage extends StatefulWidget {
  final String profileId;
  final ImpactProfile? profile; // Pass for immediate hero display
  
  const ProfileDetailPage({
    super.key,
    required this.profileId,
    this.profile,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  final ImpactService _impactService = ImpactService();
  final ProfessionalService _professionalService = ProfessionalService();
  ImpactProfile? _profile;
  bool _isLoading = true;
  List<ImpactProfile> _mutualConnections = [];
  bool _isConnected = false;
  bool _isPending = false;
  
  // Professional data
  List<WorkExperience> _workExperiences = [];
  List<PortfolioProject> _portfolioProjects = [];
  Map<String, SkillEndorsementSummary> _endorsements = {};

  @override
  void initState() {
    super.initState();
    // Use passed profile for immediate display (enables smooth hero)
    if (widget.profile != null) {
      _profile = widget.profile;
      _isLoading = false;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_profile == null) {
      setState(() => _isLoading = true);
    }
    try {
      final results = await Future.wait([
        _impactService.getProfileById(widget.profileId),
        _impactService.getMutualConnections(widget.profileId),
        _impactService.getConnectionStatus(widget.profileId),
        _professionalService.getWorkExperiences(widget.profileId),
        _professionalService.getPortfolioProjects(widget.profileId),
        _professionalService.getEndorsements(widget.profileId),
      ]);
      
      if (mounted) {
        setState(() {
          _profile = (results[0] as ImpactProfile?) ?? _profile;
          _mutualConnections = results[1] as List<ImpactProfile>;
          final connectionStatus = results[2] as String?;
          _isConnected = connectionStatus == 'CONNECTED';
          _isPending = connectionStatus == 'PENDING';
          _workExperiences = results[3] as List<WorkExperience>;
          _portfolioProjects = results[4] as List<PortfolioProject>;
          _endorsements = results[5] as Map<String, SkillEndorsementSummary>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect() async {
    if (_profile == null) return;
    
    HapticFeedback.mediumImpact();
    try {
      await _impactService.sendConnectionRequest(
        _profile!.userId,
        _profile!.lookingFor.isNotEmpty ? _profile!.lookingFor.first : 'NETWORKING',
      );
      
      setState(() => _isPending = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${_profile!.fullName}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send connection request')),
        );
      }
    }
  }

  void _showMoreActions() {
    showGlassBottomSheet(
      context: context,
      child: GlassActionList(
        actions: [
          GlassActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Send Message',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to chat
            },
          ),
          GlassActionButton(
            icon: Icons.bookmark_outline,
            label: 'Save Profile',
            onTap: () async {
              Navigator.pop(context);
              await _impactService.saveProfile(widget.profileId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved ${_profile?.fullName} to favorites')),
                );
              }
            },
          ),
          GlassActionButton(
            icon: Icons.share_outlined,
            label: 'Share Profile',
            onTap: () {
              Navigator.pop(context);
              // TODO: Share profile
            },
          ),
          GlassActionButton(
            icon: Icons.block_outlined,
            label: 'Block User',
            onTap: () {
              Navigator.pop(context);
              // TODO: Block user
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading && _profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = _profile;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Profile not found')),
      );
    }

    final avatarHeroTag = HeroConfig.profileAvatarTag(widget.profileId);
    final nameHeroTag = HeroConfig.profileNameTag(widget.profileId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: _showMoreActions,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.7),
                          cs.secondary,
                        ],
                      ),
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar with Hero
                        AnimatedHero(
                          tag: avatarHeroTag,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundImage: p.avatarUrl != null
                                      ? NetworkImage(p.avatarUrl!)
                                      : null,
                                  backgroundColor: cs.primary.withValues(alpha: 0.2),
                                  child: p.avatarUrl == null
                                      ? Text(
                                          p.fullName.isNotEmpty
                                              ? p.fullName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (p.isOnline)
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name with Hero
                        TextHero(
                          tag: nameHeroTag,
                          child: Text(
                            p.fullName,
                            style: text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (p.headline.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.headline,
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(p.vibeEmoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                'Level ${p.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.bolt, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${p.impactScore}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isConnected || _isPending ? null : _handleConnect,
                          icon: Icon(
                            _isConnected
                                ? Icons.check
                                : _isPending
                                    ? Icons.hourglass_empty
                                    : Icons.person_add,
                          ),
                          label: Text(
                            _isConnected
                                ? 'Connected'
                                : _isPending
                                    ? 'Pending'
                                    : 'Connect',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Open chat
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About section
                  if (p.bio != null && p.bio!.isNotEmpty) ...[
                    Text('About', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(p.bio!, style: text.bodyMedium),
                    const SizedBox(height: 24),
                  ],

                  // Organization
                  if (p.organization != null) ...[
                    _InfoTile(
                      icon: Icons.business,
                      title: 'Organization',
                      value: p.organization!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Education
                  _InfoTile(
                    icon: Icons.school,
                    title: 'Education',
                    value: p.educationStatus,
                  ),
                  const SizedBox(height: 24),

                  // Looking for
                  if (p.lookingFor.isNotEmpty) ...[
                    Text('Looking for', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.lookingFor.map((item) => Chip(
                        label: Text(item),
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: cs.primary),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Work Experience Timeline
                  if (_workExperiences.isNotEmpty) ...[
                    WorkExperienceTimeline(
                      experiences: _workExperiences,
                      isEditable: false,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Portfolio Showcase
                  if (_portfolioProjects.isNotEmpty) ...[
                    PortfolioShowcase(
                      projects: _portfolioProjects,
                      isEditable: false,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Skills with Endorsements
                  if (p.skills.isNotEmpty) ...[
                    SkillEndorsements(
                      skills: p.skills,
                      endorsements: _endorsements,
                      isEditable: false,
                      profileUserId: widget.profileId,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Interests
                  if (p.interests.isNotEmpty) ...[
                    Text('Interests', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.interests.map((interest) => Chip(
                        label: Text(interest),
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: AppColors.accent),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Badges
                  if (p.badges.isNotEmpty) ...[
                    Text('Badges', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: p.badges.map((badge) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.amber500,
                              AppColors.amber500.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Mutual connections
                  if (_mutualConnections.isNotEmpty) ...[
                    Text(
                      'Mutual Connections (${_mutualConnections.length})',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mutualConnections.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final mutual = _mutualConnections[index];
                          return GestureDetector(
                            onTap: () => context.push(
                              '/impact/profile/${mutual.userId}',
                              extra: mutual,
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: mutual.avatarUrl != null
                                      ? NetworkImage(mutual.avatarUrl!)
                                      : null,
                                  child: mutual.avatarUrl == null
                                      ? Text(mutual.fullName[0])
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    mutual.fullName.split(' ').first,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.labelSmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.labelSmall?.copyWith(color: AppColors.textMuted)),
              Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
