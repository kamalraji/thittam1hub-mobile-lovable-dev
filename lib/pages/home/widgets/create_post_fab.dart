import 'package:flutter/material.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
import 'package:thittam1hub/pages/impact/spark_page.dart';

class CreatePostFab extends StatefulWidget {
  final VoidCallback onPostCreated;

  const CreatePostFab({
    Key? key,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<CreatePostFab> createState() => _CreatePostFabState();
}

class _CreatePostFabState extends State<CreatePostFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _createPost() {
    _toggle();
    final sparkService = SparkService();
    
    showGlassBottomSheet(
      context: context,
      title: 'New Post',
      child: NewSparkPostContent(
        onSubmit: (type, title, content, tags) async {
          await sparkService.createSparkPost(
            type: type,
            title: title,
            content: content,
            tags: tags,
          );
          widget.onPostCreated();
        },
      ),
    );
  }

  void _createPoll() {
    _toggle();
    _showPollDialog();
  }

  void _goLive() {
    _toggle();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live feature coming soon!')),
    );
  }

  void _showPollDialog() {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final questionController = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();

    showGlassBottomSheet(
      context: context,
      title: 'Create Quick Poll',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: 'Question',
                hintText: 'What do you want to ask?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: option1Controller,
              decoration: InputDecoration(
                labelText: 'Option 1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: option2Controller,
              decoration: InputDecoration(
                labelText: 'Option 2',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Create poll
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poll created!')),
                  );
                  widget.onPostCreated();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Poll'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded options
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _expandAnimation.value,
              alignment: Alignment.bottomRight,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _FabOption(
                      icon: Icons.mic,
                      label: 'Go Live',
                      color: Colors.red,
                      onTap: _goLive,
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      icon: Icons.poll,
                      label: 'Poll',
                      color: Colors.purple,
                      onTap: _createPoll,
                    ),
                    const SizedBox(height: 8),
                    _FabOption(
                      icon: Icons.edit,
                      label: 'Post',
                      color: cs.primary,
                      onTap: _createPost,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: cs.primary,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              color: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FabOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: 'fab_$label',
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }
}
