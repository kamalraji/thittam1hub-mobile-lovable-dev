import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/profile_stats.dart';
import 'package:thittam1hub/services/profile_service.dart';
import 'package:thittam1hub/services/connections_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/widgets/cover_banner.dart';
import 'package:thittam1hub/widgets/cover_image_picker.dart';
import 'package:thittam1hub/widgets/styled_button.dart';

/// Public profile page - viewed when accessing via deep link
/// Shows limited profile info with connect/message actions
class PublicProfilePage extends StatefulWidget {
  final String profileId;
  
  const PublicProfilePage({
    super.key,
    required this.profileId,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final _profileService = ProfileService();
  final _connectionsService = ConnectionsService();
  
  UserProfile? _profile;
  ProfileStats? _stats;
  bool _isLoading = true;
  bool _isConnecting = false;
  String? _connectionStatus; // pending, accepted, none
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final currentUserId = SupabaseConfig.auth.currentUser?.id;
      _isOwnProfile = currentUserId == widget.profileId;
      
      final results = await Future.wait([
        _profileService.getUserProfile(widget.profileId),
        _profileService.getProfileStats(widget.profileId),
        if (currentUserId != null && !_isOwnProfile)
          _connectionsService.getConnectionStatus(currentUserId, widget.profileId),
      ]);
      
      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfile?;
          _stats = results[1] as ProfileStats;
          if (results.length > 2) {
            _connectionStatus = results[2] as String?;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load public profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleConnect() async {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      // Redirect to login
      context.go('/signin');
      return;
    }
    
    setState(() => _isConnecting = true);
    
    try {
      await _connectionsService.sendConnectionRequest(widget.profileId);
      setState(() => _connectionStatus = 'pending');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Connection request sent!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _handleMessage() {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    if (currentUserId == null) {
      context.go('/signin');
      return;
    }
    
    // Navigate to chat with this user
    context.push('/chat/new', extra: {
      'dmUserId': widget.profileId,
      'dmUserName': _profile?.fullName ?? 'User',
      'dmUserAvatar': _profile?.avatarUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_off, size: 64, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Profile not found',
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This profile may have been removed or is private',
                style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get gradient colors if gradient is set
    List<Color>? gradientColors;
    if (_profile?.coverGradientId != null) {
      final theme = CoverGradientTheme.presets.where((t) => t.id == _profile!.coverGradientId).firstOrNull;
      gradientColors = theme?.colors;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with cover
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: CoverBanner(
                imageUrl: _profile?.coverImageUrl,
                gradientColors: gradientColors,
                height: 200,
                showEditButton: false,
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Avatar and basic info
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: cs.primary,
                            backgroundImage: _profile?.avatarUrl != null 
                                ? NetworkImage(_profile!.avatarUrl!) 
                                : null,
                            child: _profile?.avatarUrl == null
                                ? Text(
                                    (_profile?.fullName ?? 'U')[0].toUpperCase(),
                                    style: context.textStyles.headlineLarge?.copyWith(color: cs.onPrimary),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Name
                        FadeSlideTransition(
                          child: Text(
                            _profile?.fullName ?? 'User',
                            style: context.textStyles.headlineSmall?.bold,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        // Handle if available
                        if (_profile?.socialLinks?['handle'] != null)
                          FadeSlideTransition(
                            delay: const Duration(milliseconds: 50),
                            child: Text(
                              '@${_profile!.socialLinks!['handle']}',
                              style: context.textStyles.bodyMedium?.withColor(cs.primary),
                            ),
                          ),
                        
                        // Headline/Bio
                        if (_profile?.bio != null && _profile!.bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: FadeSlideTransition(
                              delay: const Duration(milliseconds: 100),
                              child: Text(
                                _profile!.bio!,
                                style: context.textStyles.bodyMedium?.withColor(cs.onSurfaceVariant),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        
                        // Organization
                        if (_profile?.organization != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.business, size: 14, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  _profile!.organization!,
                                  style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Stats row
                        if (_stats != null)
                          FadeSlideTransition(
                            delay: const Duration(milliseconds: 150),
                            child: _PublicStatsRow(stats: _stats!),
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        if (!_isOwnProfile)
                          FadeSlideTransition(
                            delay: const Duration(milliseconds: 200),
                            child: _buildActionButtons(cs),
                          ),
                        
                        if (_isOwnProfile)
                          FadeSlideTransition(
                            delay: const Duration(milliseconds: 200),
                            child: FilledButton.icon(
                              onPressed: () => context.go('/profile'),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit My Profile'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 48),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Skills section
                        if (_profile?.skills != null && _profile!.skills!.isNotEmpty)
                          _buildSkillsSection(cs),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    final isLoggedIn = SupabaseConfig.auth.currentUser != null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Connect button
        if (_connectionStatus == null || _connectionStatus == 'none')
          FilledButton.icon(
            onPressed: _isConnecting ? null : _handleConnect,
            icon: _isConnecting 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                  )
                : const Icon(Icons.person_add),
            label: Text(isLoggedIn ? 'Connect' : 'Sign in to Connect'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(140, 44),
            ),
          ),
        
        if (_connectionStatus == 'pending')
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_empty),
            label: const Text('Pending'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 44),
            ),
          ),
        
        if (_connectionStatus == 'accepted')
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check),
            label: const Text('Connected'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(140, 44),
              backgroundColor: AppColors.success,
            ),
          ),
        
        const SizedBox(width: 12),
        
        // Message button
        OutlinedButton.icon(
          onPressed: _handleMessage,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Message'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, 44),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills',
          style: context.textStyles.titleMedium?.bold,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _profile!.skills!.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                skill,
                style: context.textStyles.bodySmall?.withColor(cs.primary),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PublicStatsRow extends StatelessWidget {
  final ProfileStats stats;

  const _PublicStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatColumn(
            value: stats.impactScore.toString(),
            label: 'Impact',
            icon: Icons.star,
            color: const Color(0xFFFFB800),
          ),
          _divider(cs),
          _StatColumn(
            value: stats.eventsAttended.toString(),
            label: 'Events',
            icon: Icons.event,
            color: cs.primary,
          ),
          _divider(cs),
          _StatColumn(
            value: stats.badgesEarned.toString(),
            label: 'Badges',
            icon: Icons.emoji_events,
            color: const Color(0xFFFF6B35),
          ),
          _divider(cs),
          _StatColumn(
            value: stats.connectionsCount.toString(),
            label: 'Connections',
            icon: Icons.people,
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 32,
      color: cs.outlineVariant.withOpacity(0.3),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textStyles.titleMedium?.bold,
        ),
        Text(
          label,
          style: context.textStyles.labelSmall?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
