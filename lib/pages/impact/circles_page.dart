import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/circle.dart';
import 'package:thittam1hub/supabase/circle_service.dart';
import 'package:thittam1hub/utils/animations.dart';

class CirclesPage extends StatefulWidget {
  const CirclesPage({Key? key}) : super(key: key);

  @override
  State<CirclesPage> createState() => _CirclesPageState();
}

class _CirclesPageState extends State<CirclesPage> {
  final CircleService _circleService = CircleService();
  late Future<List<Circle>> _autoMatchedCirclesFuture;
  late Future<List<Circle>> _popularCirclesFuture;
  late Future<List<Circle>> _recommendedCirclesFuture;
  Set<String> _joinedCircles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _autoMatchedCirclesFuture = _circleService.getAutoMatchedCircles();
    _popularCirclesFuture = _circleService.getPopularCircles();
    _recommendedCirclesFuture = _circleService.getRecommendedCircles();
    _joinedCircles = await _circleService.getUserCircles();
    if (mounted) setState(() {});
  }

  Future<void> _toggleCircleMembership(Circle circle) async {
    final isJoined = _joinedCircles.contains(circle.id);
    final cs = Theme.of(context).colorScheme;
    
    try {
      if (isJoined) {
        await _circleService.leaveCircle(circle.id);
        if (mounted) {
          setState(() => _joinedCircles.remove(circle.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Left ${circle.name}'),
              backgroundColor: cs.surfaceContainerHighest,
            ),
          );
        }
      } else {
        await _circleService.joinCircle(circle.id);
        if (mounted) {
          setState(() => _joinedCircles.add(circle.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${circle.name}'),
              backgroundColor: cs.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${isJoined ? "leave" : "join"} circle')),
        );
      }
    }
  }

  void _navigateToChat(Circle circle) {
    context.go('/circles/${circle.id}', extra: circle);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.55).clamp(180.0, 260.0);
    final listHeight = screenWidth < 400 ? 200.0 : 220.0;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Circles',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openCreateCircle,
            icon: Icon(Icons.add_circle_outline),
            label: Text('Create'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search circles...',
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                ),
              ),
            ),
            _buildSectionTitle('📍 Auto-Matched Circles'),
            FutureBuilder<List<Circle>>(
              future: _autoMatchedCirclesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: List.generate(3, (index) => FadeSlideTransition(
                      delay: staggerDelay(index),
                      child: const CircleCardSkeleton(),
                    )),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No auto-matched circles found.', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)));
                } else {
                  final circles = snapshot.data!;
                  return Column(
                    children: circles
                        .map((circle) => AutoMatchedCircleCard(
                              circle: circle,
                              isJoined: _joinedCircles.contains(circle.id),
                              onTap: () => _navigateToChat(circle),
                              onJoinToggle: () => _toggleCircleMembership(circle),
                            ))
                        .toList(),
                  );
                }
              },
            ),
            _buildSectionTitle('🔥 Popular Circles'),
            SizedBox(
              height: listHeight,
              child: FutureBuilder<List<Circle>>(
                future: _popularCirclesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, index) => FadeSlideTransition(
                        delay: staggerDelay(index),
                        child: const PopularCircleCardSkeleton(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No popular circles found.', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)));
                  } else {
                    final circles = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: circles.length,
                      itemBuilder: (context, index) {
                        final circle = circles[index];
                        return PopularCircleCard(
                          circle: circle,
                          isJoined: _joinedCircles.contains(circle.id),
                          onTap: () => _navigateToChat(circle),
                          onJoinToggle: () => _toggleCircleMembership(circle),
                          cardWidth: cardWidth,
                        );
                      },
                    );
                  }
                },
              ),
            ),
            _buildSectionTitle('🎯 Based on Your Interests'),
            SizedBox(
              height: listHeight,
              child: FutureBuilder<List<Circle>>(
                future: _recommendedCirclesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 3,
                      itemBuilder: (_, index) => FadeSlideTransition(
                        delay: staggerDelay(index),
                        child: const PopularCircleCardSkeleton(),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No recommended circles found.', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)));
                  } else {
                    final circles = snapshot.data!;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: circles.length,
                      itemBuilder: (context, index) {
                        final circle = circles[index];
                        return PopularCircleCard(
                          circle: circle,
                          isJoined: _joinedCircles.contains(circle.id),
                          onTap: () => _navigateToChat(circle),
                          onJoinToggle: () => _toggleCircleMembership(circle),
                          cardWidth: cardWidth,
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openCreateCircle() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => CreateCircleSheet(
        onCreate: (name, description, icon, isPublic, tags) async {
          await _circleService.createCircle(
            name: name,
            description: description,
            icon: icon,
            isPublic: isPublic,
            tags: tags,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Circle "$name" created'), backgroundColor: cs.primary));
            _loadData();
          }
        },
      ),
    );
  }
}

class AutoMatchedCircleCard extends StatelessWidget {
  final Circle circle;
  final bool isJoined;
  final VoidCallback onTap;
  final VoidCallback onJoinToggle;

  const AutoMatchedCircleCard({
    Key? key,
    required this.circle,
    required this.isJoined,
    required this.onTap,
    required this.onJoinToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(circle.icon, style: TextStyle(fontSize: 24)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(circle.description ?? '', style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onJoinToggle,
                child: Text(isJoined ? 'Joined ✓' : 'Join'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? cs.surfaceContainerHighest : cs.primary,
                  foregroundColor: isJoined ? cs.onSurfaceVariant : cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PopularCircleCard extends StatelessWidget {
  final Circle circle;
  final bool isJoined;
  final VoidCallback onTap;
  final VoidCallback onJoinToggle;
  final double cardWidth;

  const PopularCircleCard({
    Key? key,
    required this.circle,
    required this.isJoined,
    required this.onTap,
    required this.onJoinToggle,
    this.cardWidth = 220,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(circle.icon, style: TextStyle(fontSize: 24)),
              SizedBox(height: 8),
              Text(circle.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(circle.description ?? '', style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              Spacer(),
              Text('👥 ${circle.tags.join(', ')}', style: textTheme.bodySmall),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: onJoinToggle,
                child: Text(isJoined ? 'Joined ✓' : 'Join Circle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isJoined ? cs.surfaceContainerHighest : cs.primary,
                  foregroundColor: isJoined ? cs.onSurfaceVariant : cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CreateCircleSheet extends StatefulWidget {
  final Future<void> Function(String name, String? description, String icon, bool isPublic, List<String> tags) onCreate;
  const CreateCircleSheet({super.key, required this.onCreate});

  @override
  State<CreateCircleSheet> createState() => _CreateCircleSheetState();
}

class _CreateCircleSheetState extends State<CreateCircleSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController(text: '🌟');
  final _tagController = TextEditingController();
  bool _isPublic = true;
  bool _submitting = false;
  final List<String> _tags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = _tagController.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() => _tags.add(t));
      _tagController.clear();
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onCreate(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        _iconController.text.trim().isEmpty ? '🌟' : _iconController.text.trim(),
        _isPublic,
        _tags,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create circle')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Create Circle', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          SizedBox(height: 12),
          Row(children: [
            SizedBox(width: 70, child: Text('Icon Emoji')),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _iconController,
                decoration: InputDecoration(hintText: 'e.g. 🎯', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
          SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Public Circle'),
            subtitle: Text(_isPublic ? 'Anyone can join' : 'Only invited can join'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          SizedBox(height: 8),
          Text('Tags', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(hintText: 'Add a tag', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            SizedBox(width: 8),
            IconButton(onPressed: _addTag, icon: Icon(Icons.add_circle, color: cs.primary)),
          ]),
          if (_tags.isNotEmpty) ...[
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags.map((t) => Chip(
                label: Text(t),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _tags.remove(t)),
              )).toList(),
            ),
          ],
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Create Circle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
