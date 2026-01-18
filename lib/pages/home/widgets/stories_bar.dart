import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:thittam1hub/pages/home/home_service.dart';
import 'package:thittam1hub/theme.dart';
import 'package:thittam1hub/widgets/shimmer_loading.dart';

class StoriesBar extends StatelessWidget {
  final List<StoryItem> stories;
  final Function(StoryItem) onStoryTap;
  final VoidCallback onAddTap;

  const StoriesBar({
    Key? key,
    required this.stories,
    required this.onStoryTap,
    required this.onAddTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppLayout.storiesBarHeight,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AddStoryButton(onTap: onAddTap);
          }
          
          final story = stories[index - 1];
          return _StoryItem(
            story: story,
            onTap: () => onStoryTap(story),
          );
        },
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.1),
                    cs.tertiary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.2),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: cs.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryItem extends StatefulWidget {
  final StoryItem story;
  final VoidCallback onTap;

  const _StoryItem({required this.story, required this.onTap});

  @override
  State<_StoryItem> createState() => _StoryItemState();
}

class _StoryItemState extends State<_StoryItem> with SingleTickerProviderStateMixin {
  late AnimationController _ringAnimController;

  @override
  void initState() {
    super.initState();
    _ringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Animate ring for live or active content
    if (widget.story.isLive || widget.story.type == StoryType.discoverPeople) {
      _ringAnimController.repeat();
    }
  }

  @override
  void dispose() {
    _ringAnimController.dispose();
    super.dispose();
  }

  Color _getRingColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.story.type) {
      case StoryType.dailyMission:
        return cs.primary;
      case StoryType.liveSpace:
        return Colors.red;
      case StoryType.activeGame:
        return Colors.purple;
      case StoryType.onlineConnection:
        return Colors.green;
      case StoryType.discoverPeople:
        return Colors.orange;
    }
  }

  List<Color> _getGradientColors(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.story.type) {
      case StoryType.dailyMission:
        return [cs.primary, cs.tertiary];
      case StoryType.liveSpace:
        return [Colors.red, Colors.pink];
      case StoryType.activeGame:
        return [Colors.purple, Colors.deepPurple];
      case StoryType.onlineConnection:
        return [Colors.green, Colors.teal];
      case StoryType.discoverPeople:
        return [Colors.orange, Colors.pink, Colors.purple];
    }
  }

  IconData _getDefaultIcon() {
    switch (widget.story.type) {
      case StoryType.dailyMission:
        return Icons.flag_rounded;
      case StoryType.liveSpace:
        return Icons.mic_rounded;
      case StoryType.activeGame:
        return Icons.gamepad_rounded;
      case StoryType.onlineConnection:
        return Icons.person_rounded;
      case StoryType.discoverPeople:
        return Icons.favorite_rounded;
    }
  }

  String _getLabel() {
    switch (widget.story.type) {
      case StoryType.dailyMission:
        return 'Mission';
      case StoryType.liveSpace:
        return 'Live';
      case StoryType.activeGame:
        return 'Game';
      case StoryType.onlineConnection:
        return widget.story.title.split(' ').first;
      case StoryType.discoverPeople:
        return 'For You';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ringColor = _getRingColor(context);
    final gradientColors = _getGradientColors(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Animated rotating gradient ring
                AnimatedBuilder(
                  animation: _ringAnimController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _ringAnimController.value * 2 * math.pi,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              ...gradientColors,
                              gradientColors.first,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Inner white/surface ring
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surface,
                  ),
                ),
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage: widget.story.avatarUrl != null 
                      ? NetworkImage(widget.story.avatarUrl!)
                      : null,
                  child: widget.story.avatarUrl == null 
                      ? Icon(_getDefaultIcon(), color: ringColor, size: 22)
                      : null,
                ),
                // Live indicator
                if (widget.story.isLive)
                  Positioned(
                    bottom: 0,
                    child: _LiveIndicator(color: ringColor),
                  ),
                // Match score badge for discover people
                if (widget.story.type == StoryType.discoverPeople && widget.story.matchScore != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.story.matchScore}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: Text(
                _getLabel(),
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated pulsing live indicator
class _LiveIndicator extends StatefulWidget {
  final Color color;
  const _LiveIndicator({required this.color});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

class StoriesBarSkeleton extends StatelessWidget {
  const StoriesBarSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppLayout.storiesBarHeight,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerPlaceholder(
                  width: 56,
                  height: 56,
                  isCircle: true,
                ),
                const SizedBox(height: 4),
                ShimmerPlaceholder(
                  width: 40,
                  height: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
