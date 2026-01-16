import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thittam1hub/models/space.dart';
import 'package:thittam1hub/pages/impact/live_now_indicator.dart';
import 'package:thittam1hub/supabase/space_service.dart';
import 'package:thittam1hub/utils/animations.dart';

class SpacesPage extends StatefulWidget {
  const SpacesPage({Key? key}) : super(key: key);

  @override
  State<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends State<SpacesPage> {
  final SpaceService _spaceService = SpaceService();
  late Stream<List<Space>> _spacesStream;

  @override
  void initState() {
    super.initState();
    _spacesStream = _spaceService.getLiveSpaces();
  }

  void _navigateToSpace(Space space) {
    context.go('/spaces/${space.id}', extra: space);
  }

  Future<void> _showCreateSpaceDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateSpaceDialog(),
    );

    if (result != null) {
      final space = await _spaceService.createSpace(result['topic'], result['tags']);
      if (space != null) {
        _navigateToSpace(space);
      }
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
        title: StreamBuilder<List<Space>>(
          stream: _spacesStream,
          builder: (context, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return LiveNowIndicator(
              liveCount: count,
              onTap: () { /* TODO: Scroll to live spaces */ },
            );
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: _showCreateSpaceDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create Space'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Space>>(
          stream: _spacesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                children: List.generate(4, (_) => const SpaceCardSkeleton()),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No live spaces right now.', style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)));
            } else {
              final spaces = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                itemCount: spaces.length,
                itemBuilder: (context, index) {
                  final space = spaces[index];
                  return SpaceCard(
                    space: space,
                    onTap: () => _navigateToSpace(space),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class CreateSpaceDialog extends StatefulWidget {
  const CreateSpaceDialog({Key? key}) : super(key: key);

  @override
  State<CreateSpaceDialog> createState() => _CreateSpaceDialogState();
}

class _CreateSpaceDialogState extends State<CreateSpaceDialog> {
  final _formKey = GlobalKey<FormState>();
  String _topic = '';
  String _tags = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a Space'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Topic'),
              validator: (value) => value!.isEmpty ? 'Please enter a topic' : null,
              onSaved: (value) => _topic = value!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
              onSaved: (value) => _tags = value!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.of(context).pop({
                'topic': _topic,
                'tags': _tags.split(',').map((e) => e.trim()).toList(),
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class SpaceCard extends StatelessWidget {
  final Space space;
  final VoidCallback onTap;

  const SpaceCard({Key? key, required this.space, required this.onTap}) : super(key: key);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                space.topic,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: space.tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Placeholder for speaker avatars
                  Row(
                    children: const [
                      CircleAvatar(radius: 15), 
                      SizedBox(width: -8),
                      CircleAvatar(radius: 15),
                      SizedBox(width: -8),
                      CircleAvatar(radius: 15),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Placeholder for speaker count
                  Text('15 speakers', style: textTheme.bodySmall),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
