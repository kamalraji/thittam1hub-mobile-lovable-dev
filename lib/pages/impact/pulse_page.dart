import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/models/match_insight.dart';
import 'package:thittam1hub/supabase/impact_service.dart';
import 'package:thittam1hub/widgets/match_insights_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thittam1hub/utils/hero_animations.dart';
import 'package:thittam1hub/utils/animations.dart';
import 'package:thittam1hub/utils/intent_config.dart';

class PulsePage extends StatefulWidget {
  const PulsePage({Key? key}) : super(key: key);

  @override
  State<PulsePage> createState() => _PulsePageState();
}

class _PulsePageState extends State<PulsePage> with TickerProviderStateMixin {
  final ImpactService _impactService = ImpactService();
  List<ImpactProfile> _allProfiles = [];
  List<ImpactProfile> _filteredProfiles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  ImpactProfile? _myProfile;
  final Map<String, MatchResult> _matchResults = {};
  final Map<String, int> _matchScores = {};
  final Map<String, bool> _onlineStatus = {};
  RealtimeChannel? _onlineStatusChannel;

  // Filters
  List<String> _selectedSkills = [];
  List<String> _selectedInterests = [];
  List<String> _selectedLookingFor = [];

  // Intent selector
  String? _selectedIntent;
  late AnimationController _intentAnimController;

  @override
  void initState() {
    super.initState();
    _intentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadProfiles();
    _subscribeToOnlineStatus();
    _impactService.updateOnlineStatus(true);

    // Stagger intent card animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _intentAnimController.forward();
    });
  }

  void _subscribeToOnlineStatus() {
    _onlineStatusChannel =
        _impactService.subscribeToOnlineStatus((userId, isOnline) {
      if (mounted) {
        setState(() => _onlineStatus[userId] = isOnline);
      }
    });
  }

  @override
  void dispose() {
    _onlineStatusChannel?.unsubscribe();
    _impactService.updateOnlineStatus(false);
    _intentAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    _myProfile = await _impactService.getMyImpactProfile();

    // Build lookingFor filter with complementary matching
    List<String>? lookingForFilter;
    if (_selectedIntent != null) {
      lookingForFilter = [_selectedIntent!];
      // Add complementary key for reciprocal matching
      final config = IntentConfig.getByKey(_selectedIntent!);
      if (config?.complementaryKey != null) {
        lookingForFilter.add(config!.complementaryKey!);
      }
    } else if (_selectedLookingFor.isNotEmpty) {
      lookingForFilter = _selectedLookingFor;
    }

    final profiles = await _impactService.getImpactProfiles(
      skills: _selectedSkills.isEmpty ? null : _selectedSkills,
      interests: _selectedInterests.isEmpty ? null : _selectedInterests,
      lookingFor: lookingForFilter,
    );
    if (mounted) {
      setState(() {
        _allProfiles = profiles;
        _filteredProfiles = List.of(profiles);
        _matchScores.clear();
        _matchResults.clear();
        _onlineStatus.clear();
        if (_myProfile != null) {
          for (final p in _filteredProfiles) {
            final result =
                _impactService.calculateMatchInsights(_myProfile!, p);
            _matchResults[p.userId] = result;
            _matchScores[p.userId] = result.totalScore;
            _onlineStatus[p.userId] = p.isOnline;
          }
          _filteredProfiles.sort((a, b) => (_matchScores[b.userId] ?? 0)
              .compareTo((_matchScores[a.userId] ?? 0)));
        }
        _currentIndex = 0;
        _isLoading = false;
      });
    }
  }

  void _onIntentSelected(String? intentKey) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIntent == intentKey) {
        // Deselect if tapping the same intent
        _selectedIntent = null;
        _selectedLookingFor.clear();
      } else {
        _selectedIntent = intentKey;
        // Sync with filter
        _selectedLookingFor = intentKey != null ? [intentKey] : [];
      }
    });
    _loadProfiles();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterSheet(
        allProfiles: _allProfiles,
        selectedSkills: _selectedSkills,
        selectedInterests: _selectedInterests,
        selectedLookingFor: _selectedLookingFor,
        onApply: (skills, interests, lookingFor) {
          setState(() {
            _selectedSkills = skills;
            _selectedInterests = interests;
            _selectedLookingFor = lookingFor;
            // Sync intent with filter if single lookingFor selected
            if (lookingFor.length == 1) {
              _selectedIntent = lookingFor.first;
            } else {
              _selectedIntent = null;
            }
          });
          _loadProfiles();
        },
      ),
    );
  }

  void _onSkip() {
    if (_currentIndex >= _filteredProfiles.length) return;
    final profile = _filteredProfiles[_currentIndex];
    _impactService.skipProfile(profile.userId);

    setState(() {
      if (_currentIndex < _filteredProfiles.length - 1) {
        _currentIndex++;
      } else {
        _filteredProfiles.removeAt(_currentIndex);
        if (_filteredProfiles.isEmpty) {
          _loadProfiles();
        }
      }
    });
  }

  void _onConnect() async {
    if (_currentIndex >= _filteredProfiles.length) return;
    final profile = _filteredProfiles[_currentIndex];
    final cs = Theme.of(context).colorScheme;

    try {
      await _impactService.sendConnectionRequest(
        profile.userId,
        _selectedIntent ??
            (profile.lookingFor.isNotEmpty
                ? profile.lookingFor.first
                : 'NETWORKING'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${profile.fullName}'),
            backgroundColor: cs.primary,
          ),
        );
      }

      setState(() {
        if (_currentIndex < _filteredProfiles.length - 1) {
          _currentIndex++;
        } else {
          _filteredProfiles.removeAt(_currentIndex);
          if (_filteredProfiles.isEmpty) {
            _loadProfiles();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send connection request')),
        );
      }
    }
  }

  void _onSave() async {
    if (_currentIndex >= _filteredProfiles.length) return;
    final profile = _filteredProfiles[_currentIndex];

    try {
      await _impactService.saveProfile(profile.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved ${profile.fullName} to favorites'),
            backgroundColor: Colors.amber[600],
          ),
        );
      }

      setState(() {
        if (_currentIndex < _filteredProfiles.length - 1) {
          _currentIndex++;
        } else {
          _filteredProfiles.removeAt(_currentIndex);
          if (_filteredProfiles.isEmpty) {
            _loadProfiles();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Intent Selector Section
            _IntentSelectorSection(
              selectedIntent: _selectedIntent,
              onIntentSelected: _onIntentSelected,
              animationController: _intentAnimController,
            ),

            // Discovery Mode Toggle (People/Groups/All)
            _DiscoveryModeToggle(
              currentMode: _discoveryMode,
              onModeChanged: (mode) {
                HapticFeedback.lightImpact();
                setState(() => _discoveryMode = mode);
                if (mode == DiscoveryMode.groups || mode == DiscoveryMode.all) {
                  _loadCircles();
                }
              },
            ),

            // Search and Filter Row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: _discoveryMode == DiscoveryMode.groups 
                            ? 'Search groups...' 
                            : 'Search by name, skill, etc...',
                        prefixIcon:
                            Icon(Icons.search, color: cs.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        Icon(Icons.filter_list, color: cs.onSurfaceVariant),
                        if (_selectedSkills.isNotEmpty ||
                            _selectedInterests.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
            ),

            // Active Intent Badge
            if (_selectedIntent != null)
              _ActiveIntentBadge(
                intentKey: _selectedIntent!,
                profileCount: _filteredProfiles.length,
                onClear: () => _onIntentSelected(null),
              ),

            // Filter chips (skills, interests - not lookingFor since we have intent selector)
            if (_selectedSkills.isNotEmpty || _selectedInterests.isNotEmpty)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._selectedSkills.map((s) => _buildFilterChip(s, () {
                          setState(() => _selectedSkills.remove(s));
                          _loadProfiles();
                        })),
                    ..._selectedInterests.map((i) => _buildFilterChip(i, () {
                          setState(() => _selectedInterests.remove(i));
                          _loadProfiles();
                        })),
                  ],
                ),
              ),

            // Content Area - switches based on discovery mode
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FadeSlideTransition(
                          child: const ProfileCardSkeleton(),
                        ),
                      ),
                    )
                  : _discoveryMode == DiscoveryMode.groups
                      ? _buildGroupsContent(cs, textTheme)
                      : _discoveryMode == DiscoveryMode.all
                          ? _buildMixedContent(cs, textTheme)
                          : _buildPeopleContent(cs, textTheme),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleContent(ColorScheme cs, TextTheme textTheme) {
    if (_filteredProfiles.isEmpty) {
      return _buildEmptyState(cs, textTheme, 'profiles');
    }
    return ProfileCard(
      profile: _filteredProfiles[_currentIndex],
      matchScore: _matchScores[_filteredProfiles[_currentIndex].userId] ?? 0,
      matchResult: _matchResults[_filteredProfiles[_currentIndex].userId],
      isOnline: _onlineStatus[_filteredProfiles[_currentIndex].userId] ?? false,
      selectedIntent: _selectedIntent,
      onSkip: _onSkip,
      onConnect: _onConnect,
      onSave: _onSave,
      onTap: () => context.push(
        '/impact/profile/${_filteredProfiles[_currentIndex].userId}',
        extra: _filteredProfiles[_currentIndex],
      ),
    );
  }

  Widget _buildGroupsContent(ColorScheme cs, TextTheme textTheme) {
    if (_matchedCircles.isEmpty) {
      return _buildEmptyState(cs, textTheme, 'groups');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchedCircles.length,
      itemBuilder: (context, index) {
        final result = _matchedCircles[index];
        return CircleDiscoveryCard(
          circle: result.circle,
          matchScore: result.matchScore,
          insights: result.insights,
          onJoin: () async {
            await _circleService.joinCircle(result.circle.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined ${result.circle.name}')),
              );
              _loadCircles();
            }
          },
          onTap: () => context.push('/impact/circles/${result.circle.id}'),
        );
      },
    );
  }

  Widget _buildMixedContent(ColorScheme cs, TextTheme textTheme) {
    // Combine profiles and circles, interleaved by score
    final combinedItems = <_MixedDiscoveryItem>[];
    
    for (final profile in _filteredProfiles) {
      combinedItems.add(_MixedDiscoveryItem(
        type: 'profile',
        profile: profile,
        score: _matchScores[profile.userId] ?? 0,
      ));
    }
    
    for (final circleResult in _matchedCircles) {
      combinedItems.add(_MixedDiscoveryItem(
        type: 'circle',
        circleResult: circleResult,
        score: circleResult.matchScore,
      ));
    }
    
    combinedItems.sort((a, b) => b.score.compareTo(a.score));
    
    if (combinedItems.isEmpty) {
      return _buildEmptyState(cs, textTheme, 'matches');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: combinedItems.length,
      itemBuilder: (context, index) {
        final item = combinedItems[index];
        if (item.type == 'circle') {
          return CircleDiscoveryCard(
            circle: item.circleResult!.circle,
            matchScore: item.circleResult!.matchScore,
            insights: item.circleResult!.insights,
            onJoin: () async {
              await _circleService.joinCircle(item.circleResult!.circle.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined ${item.circleResult!.circle.name}')),
                );
                _loadCircles();
              }
            },
            onTap: () => context.push('/impact/circles/${item.circleResult!.circle.id}'),
          );
        } else {
          // Mini profile card for list view
          return _MiniProfileCard(
            profile: item.profile!,
            matchScore: item.score,
            isOnline: _onlineStatus[item.profile!.userId] ?? false,
            onTap: () => context.push(
              '/impact/profile/${item.profile!.userId}',
              extra: item.profile,
            ),
          );
        }
      },
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme textTheme, String type) {
    final config = _selectedIntent != null
        ? IntentConfig.getByKey(_selectedIntent!)
        : null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'groups' ? Icons.groups_outlined : (config?.icon ?? Icons.people_outline),
            size: 64,
            color: config?.color ?? cs.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            _selectedIntent != null
                ? 'No ${config?.label ?? type} matches found.'
                : 'No $type found.',
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 8),
          if (_selectedIntent != null)
            TextButton.icon(
              onPressed: () => _onIntentSelected(null),
              icon: Icon(Icons.close),
              label: Text('Clear ${config?.label ?? 'intent'} filter'),
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSkills.clear();
                  _selectedInterests.clear();
                  _selectedLookingFor.clear();
                  _selectedIntent = null;
                });
                _loadProfiles();
              },
              child: Text('Clear All Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: cs.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(color: cs.primary),
      ),
    );
  }
}

// ==================== Intent Selector Section ====================

class _IntentSelectorSection extends StatelessWidget {
  final String? selectedIntent;
  final Function(String?) onIntentSelected;
  final AnimationController animationController;

  const _IntentSelectorSection({
    required this.selectedIntent,
    required this.onIntentSelected,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                'What are you looking for today?',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (selectedIntent != null)
                TextButton(
                  onPressed: () => onIntentSelected(null),
                  child: Text('View All'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: IntentConfig.all.length,
            itemBuilder: (context, index) {
              final config = IntentConfig.all[index];
              final isSelected = selectedIntent == config.key;

              return AnimatedBuilder(
                animation: animationController,
                builder: (context, child) {
                  // Staggered animation
                  final delay = index * 0.1;
                  final animValue =
                      ((animationController.value - delay) / (1 - delay))
                          .clamp(0.0, 1.0);

                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - animValue)),
                    child: Opacity(
                      opacity: animValue,
                      child: child,
                    ),
                  );
                },
                child: _IntentCard(
                  config: config,
                  isSelected: isSelected,
                  onTap: () => onIntentSelected(config.key),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IntentCard extends StatefulWidget {
  final IntentConfig config;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntentCard({
    required this.config,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_IntentCard> createState() => _IntentCardState();
}

class _IntentCardState extends State<_IntentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 85,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.config.color
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.config.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [
                            widget.config.color.withValues(alpha: 0.25),
                            widget.config.color.withValues(alpha: 0.1),
                          ]
                        : [
                            (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.05),
                            (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.02),
                          ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.config.emoji,
                      style: TextStyle(fontSize: 28),
                    ),
                    SizedBox(height: 6),
                    Text(
                      widget.config.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: widget.isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: widget.isSelected
                            ? widget.config.color
                            : cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Active Intent Badge ====================

class _ActiveIntentBadge extends StatelessWidget {
  final String intentKey;
  final int profileCount;
  final VoidCallback onClear;

  const _ActiveIntentBadge({
    required this.intentKey,
    required this.profileCount,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final config = IntentConfig.getByKey(intentKey);
    if (config == null) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: config.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(config.emoji, style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'Looking for ${config.label}',
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$profileCount',
                    style: TextStyle(
                      color: config.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 16, color: config.color),
                ),
              ],
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}

// ==================== Filter Sheet ====================

class FilterSheet extends StatefulWidget {
  final List<ImpactProfile> allProfiles;
  final List<String> selectedSkills;
  final List<String> selectedInterests;
  final List<String> selectedLookingFor;
  final Function(List<String>, List<String>, List<String>) onApply;

  const FilterSheet({
    Key? key,
    required this.allProfiles,
    required this.selectedSkills,
    required this.selectedInterests,
    required this.selectedLookingFor,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late List<String> _skills;
  late List<String> _interests;
  late List<String> _lookingFor;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.selectedSkills);
    _interests = List.from(widget.selectedInterests);
    _lookingFor = List.from(widget.selectedLookingFor);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final allSkills =
        widget.allProfiles.expand((p) => p.skills).toSet().toList()..sort();
    final allInterests =
        widget.allProfiles.expand((p) => p.interests).toSet().toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Advanced Filters',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _skills.clear();
                      _interests.clear();
                      _lookingFor.clear();
                    });
                  },
                  child: Text('Clear All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Use the intent cards above for quick filtering, or use these advanced options.',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _buildSection('Skills', allSkills, _skills),
                  SizedBox(height: 16),
                  _buildSection('Interests', allInterests, _interests),
                  SizedBox(height: 16),
                  _buildIntentSection(),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_skills, _interests, _lookingFor);
                  Navigator.pop(context);
                },
                child: Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, List<String> options, List<String> selected) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                });
              },
              selectedColor: cs.primary.withValues(alpha: 0.2),
              checkmarkColor: cs.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIntentSection() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Looking For',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: IntentConfig.all.map((config) {
            final isSelected = _lookingFor.contains(config.key);
            return FilterChip(
              avatar: Text(config.emoji, style: TextStyle(fontSize: 14)),
              label: Text(config.label),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _lookingFor.add(config.key);
                  } else {
                    _lookingFor.remove(config.key);
                  }
                });
              },
              selectedColor: config.color.withValues(alpha: 0.2),
              checkmarkColor: config.color,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ==================== Profile Card ====================

class ProfileCard extends StatefulWidget {
  final ImpactProfile profile;
  final int matchScore;
  final MatchResult? matchResult;
  final bool isOnline;
  final String? selectedIntent;
  final VoidCallback onSkip;
  final VoidCallback onConnect;
  final VoidCallback onSave;
  final VoidCallback? onTap;
  final bool enableHero;

  const ProfileCard({
    Key? key,
    required this.profile,
    required this.matchScore,
    this.matchResult,
    required this.isOnline,
    this.selectedIntent,
    required this.onSkip,
    required this.onConnect,
    required this.onSave,
    this.onTap,
    this.enableHero = true,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  final ImpactService _impactService = ImpactService();
  List<ImpactProfile> _mutualConnections = [];
  bool _loadingMutuals = false;
  bool _showInsights = false;
  double _dragPosition = 0;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _loadMutualConnections();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(_resetController)
      ..addListener(() {
        setState(() => _dragPosition = _resetAnimation.value);
      });
  }

  Future<void> _loadMutualConnections() async {
    setState(() => _loadingMutuals = true);
    final mutuals =
        await _impactService.getMutualConnections(widget.profile.userId);
    if (mounted) {
      setState(() {
        _mutualConnections = mutuals;
        _loadingMutuals = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(-150.0, 150.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragPosition > 80) {
      widget.onSave();
      _resetPosition();
    } else if (_dragPosition < -80) {
      widget.onSkip();
      _resetPosition();
    } else {
      _resetPosition();
    }
  }

  void _resetPosition() {
    _resetAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOut,
    ));
    _resetController.forward(from: 0);
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final swipeProgress = (_dragPosition.abs() / 80).clamp(0.0, 1.0);
    final isSwipingRight = _dragPosition > 0;
    final avatarHeroTag = HeroConfig.profileAvatarTag(widget.profile.userId);
    final nameHeroTag = HeroConfig.profileNameTag(widget.profile.userId);

    // Get intent config for styling
    final intentConfig = widget.selectedIntent != null
        ? IntentConfig.getByKey(widget.selectedIntent!)
        : null;

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: Transform.translate(
        offset: Offset(_dragPosition, 0),
        child: Transform.rotate(
          angle: _dragPosition * 0.005,
          child: Opacity(
            opacity: (1 - (swipeProgress * 0.3)).toDouble(),
            child: Stack(
              children: [
                Card(
                  margin: const EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                AnimatedHero(
                                  tag: avatarHeroTag,
                                  enabled: widget.enableHero,
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        widget.profile.avatarUrl != null
                                            ? NetworkImage(
                                                widget.profile.avatarUrl!)
                                            : null,
                                    child: widget.profile.avatarUrl == null
                                        ? Text(
                                            widget.profile.fullName
                                                .substring(0, 1),
                                            style: TextStyle(fontSize: 24))
                                        : null,
                                  ),
                                ),
                                if (widget.isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: cs.surface, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextHero(
                                    tag: nameHeroTag,
                                    enabled: widget.enableHero,
                                    child: Text(widget.profile.fullName,
                                        style: textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  SizedBox(height: 4),
                                  Text(widget.profile.headline,
                                      style: textTheme.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            // Match Insights Badge (tappable to expand)
                            if (widget.matchResult != null)
                              GestureDetector(
                                onTap: () => setState(
                                    () => _showInsights = !_showInsights),
                                child: MatchInsightsCard(
                                  matchResult: widget.matchResult!,
                                  compact: true,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (intentConfig?.color ?? cs.primary)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.favorite,
                                        color:
                                            intentConfig?.color ?? cs.primary,
                                        size: 16),
                                    SizedBox(width: 6),
                                    Text('${widget.matchScore}%',
                                        style: TextStyle(
                                            color: intentConfig?.color ??
                                                cs.primary,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        // Expandable Match Insights
                        if (_showInsights && widget.matchResult != null) ...[
                          SizedBox(height: 16),
                          MatchInsightsCard(
                            matchResult: widget.matchResult!,
                            initiallyExpanded: true,
                            onTap: () => setState(() => _showInsights = false),
                          ),
                        ],
                        SizedBox(height: 24),
                        _buildLookingForSection(textTheme),
                        SizedBox(height: 12),
                        if (_mutualConnections.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: cs.primary),
                              SizedBox(width: 4),
                              Text(
                                  '${_mutualConnections.length} mutual connection${_mutualConnections.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _mutualConnections.length.clamp(0, 5),
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Tooltip(
                                  message: _mutualConnections[i].fullName,
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundImage: _mutualConnections[i]
                                                .avatarUrl !=
                                            null
                                        ? NetworkImage(
                                            _mutualConnections[i].avatarUrl!)
                                        : null,
                                    child: _mutualConnections[i].avatarUrl ==
                                            null
                                        ? Text(
                                            _mutualConnections[i].fullName[0])
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.profile.interests
                              .take(3)
                              .map((interest) => Chip(label: Text(interest)))
                              .toList(),
                        ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Vibe: ${widget.profile.vibeEmoji}',
                                style: textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('🔥 Level ${widget.profile.level}',
                                style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                        Spacer(),
                        Text(
                          'Swipe left to skip, right to save, or use buttons below',
                          style: textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 340;
                            if (isNarrow) {
                              return Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildSkipButton(cs),
                                      _buildSaveButton(),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildConnectButton(cs),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildSkipButton(cs),
                                _buildConnectButton(cs),
                                _buildSaveButton(),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (_dragPosition.abs() > 20)
                  Positioned.fill(
                    child: Align(
                      alignment: isSwipingRight
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSwipingRight
                                ? Colors.amber[600]!
                                    .withValues(alpha: swipeProgress)
                                : cs.error.withValues(alpha: swipeProgress),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSwipingRight ? Icons.star : Icons.close,
                            color:
                                Colors.white.withValues(alpha: swipeProgress),
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLookingForSection(TextTheme textTheme) {
    // Show looking for with intent-aware styling
    final lookingForItems = widget.profile.lookingFor;
    if (lookingForItems.isEmpty) return SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Text('🎯 Looking for:',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ...lookingForItems.take(3).map((item) {
          final config = IntentConfig.getByKey(item);
          final isMatched = widget.selectedIntent == item ||
              (IntentConfig.getByKey(widget.selectedIntent ?? '')
                      ?.complementaryKey ==
                  item);

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: config != null
                  ? config.color.withValues(alpha: isMatched ? 0.2 : 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: isMatched && config != null
                  ? Border.all(color: config.color.withValues(alpha: 0.5))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (config != null) ...[
                  Text(config.emoji, style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                ],
                Text(
                  config?.label ?? item,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                    color: config?.color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkipButton(ColorScheme cs) {
    return ElevatedButton(
      onPressed: widget.onSkip,
      child: Icon(Icons.close, color: cs.onError),
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(20),
        backgroundColor: cs.error,
      ),
    );
  }

  Widget _buildConnectButton(ColorScheme cs) {
    final intentConfig = widget.selectedIntent != null
        ? IntentConfig.getByKey(widget.selectedIntent!)
        : null;

    return ElevatedButton(
      onPressed: widget.onConnect,
      child: Text('Connect', style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
        backgroundColor: intentConfig?.color ?? cs.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: widget.onSave,
      child: Icon(Icons.star_border, color: Colors.white),
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(),
        padding: EdgeInsets.all(20),
        backgroundColor: Colors.amber[600],
      ),
    );
  }
}

// ==================== Profile Card Skeleton ====================

class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 200,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: List.generate(
                3,
                (i) => Container(
                  margin: EdgeInsets.only(right: 8),
                  height: 32,
                  width: 70,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (i) => Container(
                  height: 56,
                  width: i == 1 ? 120 : 56,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(i == 1 ? 28 : 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Discovery Mode Toggle ====================

class _DiscoveryModeToggle extends StatelessWidget {
  final DiscoveryMode currentMode;
  final ValueChanged<DiscoveryMode> onModeChanged;

  const _DiscoveryModeToggle({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: DiscoveryMode.values.map((mode) {
            final isSelected = currentMode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => onModeChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mode == DiscoveryMode.people ? '👤' : mode == DiscoveryMode.groups ? '👥' : '🌐',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mode == DiscoveryMode.people ? 'People' : mode == DiscoveryMode.groups ? 'Groups' : 'All',
                        style: TextStyle(
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ==================== Mixed Discovery Item ====================

class _MixedDiscoveryItem {
  final String type; // 'profile' or 'circle'
  final ImpactProfile? profile;
  final GroupMatchResult? circleResult;
  final int score;

  _MixedDiscoveryItem({
    required this.type,
    this.profile,
    this.circleResult,
    required this.score,
  });
}

// ==================== Mini Profile Card for List View ====================

class _MiniProfileCard extends StatelessWidget {
  final ImpactProfile profile;
  final int matchScore;
  final bool isOnline;
  final VoidCallback onTap;

  const _MiniProfileCard({
    required this.profile,
    required this.matchScore,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                    child: profile.avatarUrl == null ? Text(profile.fullName[0]) : null,
                  ),
                  if (isOnline)
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    if (profile.headline.isNotEmpty)
                      Text(profile.headline, style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$matchScore%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
