import 'package:flutter/material.dart';
import 'package:thittam1hub/pages/home/home_service.dart';

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
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      height: 100,
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outline.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(Icons.add, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              'Create',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
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

class _StoryItem extends StatelessWidget {
  final StoryItem story;
  final VoidCallback onTap;

  const _StoryItem({required this.story, required this.onTap});

  Color _getRingColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (story.type) {
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

  IconData _getDefaultIcon() {
    switch (story.type) {
      case StoryType.dailyMission:
        return Icons.flag;
      case StoryType.liveSpace:
        return Icons.mic;
      case StoryType.activeGame:
        return Icons.gamepad;
      case StoryType.onlineConnection:
        return Icons.person;
      case StoryType.discoverPeople:
        return Icons.favorite;
    }
  }

  String _getLabel() {
    switch (story.type) {
      case StoryType.dailyMission:
        return 'Mission';
      case StoryType.liveSpace:
        return 'Live';
      case StoryType.activeGame:
        return 'Game';
      case StoryType.onlineConnection:
        return story.title.split(' ').first;
      case StoryType.discoverPeople:
        return 'For You';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ringColor = _getRingColor(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [ringColor, ringColor.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.surface,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: cs.surfaceContainerHighest,
                      backgroundImage: story.avatarUrl != null 
                          ? NetworkImage(story.avatarUrl!)
                          : null,
                      child: story.avatarUrl == null 
                          ? Icon(_getDefaultIcon(), color: ringColor, size: 24)
                          : null,
                    ),
                  ),
                ),
                if (story.isLive)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ringColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          story.type == StoryType.liveSpace ? 'LIVE' : '•',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 68,
              child: Text(
                _getLabel(),
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
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

class StoriesBarSkeleton extends StatelessWidget {
  const StoriesBarSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
