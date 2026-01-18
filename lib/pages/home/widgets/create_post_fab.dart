import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/widgets/glassmorphism_bottom_sheet.dart';
import 'package:thittam1hub/pages/home/widgets/new_spark_post_content.dart';

class CreatePostFab extends StatefulWidget {
  final VoidCallback onPostCreated;

  const CreatePostFab({
    Key? key,
    required this.onPostCreated,
  }) : super(key: key);

  @override
  State<CreatePostFab> createState() => _CreatePostFabState();
}

class _CreatePostFabState extends State<CreatePostFab> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  // Staggered animations for each option
  late Animation<double> _option1Animation;
  late Animation<double> _option2Animation;
  late Animation<double> _option3Animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOut),
    );

    // Staggered animations
    _option1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _option2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _option3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _rotationController.forward();
      } else {
        _animationController.reverse();
        _rotationController.reverse();
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
        onSubmit: (type, title, content, tags, {gifUrl, imageUrl, linkUrl, pollId}) async {
          await sparkService.createSparkPost(
            type: type,
            title: title,
            content: content,
            tags: tags,
            gifUrl: gifUrl,
            imageUrl: imageUrl,
            linkUrl: linkUrl,
            pollId: pollId,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop blur when expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5 * _expandAnimation.value,
                      sigmaY: 5 * _expandAnimation.value,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.2 * _expandAnimation.value),
                    ),
                  );
                },
              ),
            ),
          ),

        // FAB Column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expanded options with stagger
            _AnimatedFabOption(
              animation: _option3Animation,
              icon: Icons.mic_rounded,
              label: 'Go Live',
              gradientColors: [Colors.red.shade500, Colors.pink.shade400],
              onTap: _goLive,
            ),
            const SizedBox(height: 10),
            _AnimatedFabOption(
              animation: _option2Animation,
              icon: Icons.poll_rounded,
              label: 'Poll',
              gradientColors: [
                Colors.purple.shade500,
                Colors.deepPurple.shade400
              ],
              onTap: _createPoll,
            ),
            const SizedBox(height: 10),
            _AnimatedFabOption(
              animation: _option1Animation,
              icon: Icons.edit_rounded,
              label: 'Post',
              gradientColors: [cs.primary, cs.tertiary],
              onTap: _createPost,
            ),
            const SizedBox(height: 12),

            // Main FAB with glassmorphism
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggle,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: RotationTransition(
                          turns: _rotationAnimation,
                          child: Icon(
                            _isExpanded ? Icons.close_rounded : Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedFabOption extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _AnimatedFabOption({
    required this.animation,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          alignment: Alignment.centerRight,
          child: Transform.translate(
            offset: Offset(20 * (1 - animation.value), 0),
            child: Opacity(
              opacity: animation.value.clamp(0.0, 1.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.15)
                              : cs.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : cs.outline.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          label,
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Icon button with gradient
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
