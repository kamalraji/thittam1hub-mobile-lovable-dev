import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/supabase/impact_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thittam1hub/utils/hero_animations.dart';
import 'package:thittam1hub/utils/animations.dart';

class PulsePage extends StatefulWidget {
  const PulsePage({Key? key}) : super(key: key);

  @override
  State<PulsePage> createState() => _PulsePageState();
}

class _PulsePageState extends State<PulsePage> {
  final ImpactService _impactService = ImpactService();
  List<ImpactProfile> _allProfiles = [];
  List<ImpactProfile> _filteredProfiles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  ImpactProfile? _myProfile;
  final Map<String, int> _matchScores = {};
  final Map<String, bool> _onlineStatus = {};
  RealtimeChannel? _onlineStatusChannel;
  
  // Filters
  List<String> _selectedSkills = [];
  List<String> _selectedInterests = [];
  List<String> _selectedLookingFor = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _subscribeToOnlineStatus();
    _impactService.updateOnlineStatus(true);
  }

  void _subscribeToOnlineStatus() {
    _onlineStatusChannel = _impactService.subscribeToOnlineStatus((userId, isOnline) {
      if (mounted) {
        setState(() => _onlineStatus[userId] = isOnline);
      }
    });
  }

  @override
  void dispose() {
    _onlineStatusChannel?.unsubscribe();
    _impactService.updateOnlineStatus(false);
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    _myProfile = await _impactService.getMyImpactProfile();
    final profiles = await _impactService.getImpactProfiles(
      skills: _selectedSkills.isEmpty ? null : _selectedSkills,
      interests: _selectedInterests.isEmpty ? null : _selectedInterests,
      lookingFor: _selectedLookingFor.isEmpty ? null : _selectedLookingFor,
    );
    if (mounted) {
      setState(() {
        _allProfiles = profiles;
        _filteredProfiles = List.of(profiles);
        _matchScores.clear();
        _onlineStatus.clear();
        if (_myProfile != null) {
          for (final p in _filteredProfiles) {
            _matchScores[p.userId] = _impactService.calculateMatchScore(_myProfile!, p);
            _onlineStatus[p.userId] = p.isOnline;
          }
          _filteredProfiles.sort((a, b) => (_matchScores[b.userId] ?? 0).compareTo((_matchScores[a.userId] ?? 0)));
        }
        _currentIndex = 0;
        _isLoading = false;
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    
    try {
      await _impactService.sendConnectionRequest(
        profile.userId,
        profile.lookingFor.isNotEmpty ? profile.lookingFor.first : 'NETWORKING',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to ${profile.fullName}'),
            backgroundColor: Color(0xFF8B5CF6),
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
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, skill, etc...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.grey[600]),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          if (_selectedSkills.isNotEmpty || _selectedInterests.isNotEmpty || _selectedLookingFor.isNotEmpty)
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
                  ..._selectedLookingFor.map((l) => _buildFilterChip(l, () {
                    setState(() => _selectedLookingFor.remove(l));
                    _loadProfiles();
                  })),
                ],
              ),
            ),
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
                : _filteredProfiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text('No profiles found.', style: TextStyle(color: Colors.grey[600])),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedSkills.clear();
                                  _selectedInterests.clear();
                                  _selectedLookingFor.clear();
                                });
                                _loadProfiles();
                              },
                              child: Text('Clear Filters'),
                            ),
                          ],
                        ),
                      )
                    : ProfileCard(
                        profile: _filteredProfiles[_currentIndex],
                        matchScore: _matchScores[_filteredProfiles[_currentIndex].userId] ?? 0,
                        isOnline: _onlineStatus[_filteredProfiles[_currentIndex].userId] ?? false,
                        onSkip: _onSkip,
                        onConnect: _onConnect,
                        onSave: _onSave,
                        onTap: () => context.push(
                          '/impact/profile/${_filteredProfiles[_currentIndex].userId}',
                          extra: _filteredProfiles[_currentIndex],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(label),
          deleteIcon: Icon(Icons.close, size: 16),
          onDeleted: onRemove,
          backgroundColor: Color(0xFF8B5CF6).withValues(alpha: 0.1),
          labelStyle: TextStyle(color: Color(0xFF8B5CF6)),
        ),
      );
}

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
    final allSkills = widget.allProfiles
        .expand((p) => p.skills)
        .toSet()
        .toList()
      ..sort();
    final allInterests = widget.allProfiles
        .expand((p) => p.interests)
        .toSet()
        .toList()
      ..sort();
    final allLookingFor = widget.allProfiles
        .expand((p) => p.lookingFor)
        .toSet()
        .toList()
      ..sort();

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
                Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _buildSection('Skills', allSkills, _skills),
                  SizedBox(height: 16),
                  _buildSection('Interests', allInterests, _interests),
                  SizedBox(height: 16),
                  _buildSection('Looking For', allLookingFor, _lookingFor),
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
                  backgroundColor: Color(0xFF8B5CF6),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> options, List<String> selected) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                selectedColor: Color(0xFF8B5CF6).withValues(alpha: 0.2),
                checkmarkColor: Color(0xFF8B5CF6),
              );
            }).toList(),
          ),
        ],
      );
}

class ProfileCard extends StatefulWidget {
  final ImpactProfile profile;
  final int matchScore;
  final bool isOnline;
  final VoidCallback onSkip;
  final VoidCallback onConnect;
  final VoidCallback onSave;
  final VoidCallback? onTap;
  final bool enableHero;

  const ProfileCard({
    Key? key,
    required this.profile,
    required this.matchScore,
    required this.isOnline,
    required this.onSkip,
    required this.onConnect,
    required this.onSave,
    this.onTap,
    this.enableHero = true,
  }) : super(key: key);

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with SingleTickerProviderStateMixin {
  final ImpactService _impactService = ImpactService();
  List<ImpactProfile> _mutualConnections = [];
  bool _loadingMutuals = false;
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
    final mutuals = await _impactService.getMutualConnections(widget.profile.userId);
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
    final swipeProgress = (_dragPosition.abs() / 80).clamp(0.0, 1.0);
    final isSwipingRight = _dragPosition > 0;
    final avatarHeroTag = HeroConfig.profileAvatarTag(widget.profile.userId);
    final nameHeroTag = HeroConfig.profileNameTag(widget.profile.userId);
    
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: Transform.translate(
        offset: Offset(_dragPosition, 0),
        child: Transform.rotate(
          angle: _dragPosition * 0.005,
          child: Opacity(
            opacity: 1 - (swipeProgress * 0.3),
            child: Stack(
              children: [
                Card(
                  margin: const EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        backgroundImage: widget.profile.avatarUrl != null ? NetworkImage(widget.profile.avatarUrl!) : null,
                        child: widget.profile.avatarUrl == null ? Text(widget.profile.fullName.substring(0, 1), style: TextStyle(fontSize: 24)) : null,
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
                            border: Border.all(color: Colors.white, width: 2),
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
                        child: Text(widget.profile.fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 4),
                      Text(widget.profile.headline, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Color(0xFF8B5CF6), size: 16),
                      SizedBox(width: 6),
                      Text('${widget.matchScore}%', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text('🎯 Looking for: ${widget.profile.lookingFor.join(', ')}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 12),
            if (_mutualConnections.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 4),
                  Text('${_mutualConnections.length} mutual connection${_mutualConnections.length > 1 ? 's' : ''}', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
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
                        backgroundImage: _mutualConnections[i].avatarUrl != null ? NetworkImage(_mutualConnections[i].avatarUrl!) : null,
                        child: _mutualConnections[i].avatarUrl == null ? Text(_mutualConnections[i].fullName[0]) : null,
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
              children: widget.profile.interests.take(3).map((interest) => Chip(label: Text(interest))).toList(),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vibe: ${widget.profile.vibeEmoji}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('🔥 Level ${widget.profile.level}', style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            Spacer(),
            Text(
              'Swipe left to skip, right to save, or use buttons below',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: widget.onSkip,
                  child: Icon(Icons.close, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    backgroundColor: Colors.red[400],
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onConnect,
                  child: Text('Connect', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    backgroundColor: Color(0xFF8B5CF6),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onSave,
                  child: Icon(Icons.star_border, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    backgroundColor: Colors.amber[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    ),
                if (_dragPosition.abs() > 20)
                  Positioned.fill(
                    child: Align(
                      alignment: isSwipingRight ? Alignment.centerLeft : Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSwipingRight ? Colors.amber[600]!.withValues(alpha: swipeProgress) : Colors.red[400]!.withValues(alpha: swipeProgress),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSwipingRight ? Icons.star : Icons.close,
                            color: Colors.white.withValues(alpha: swipeProgress),
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
}
