import 'package:flutter/material.dart';
import 'package:thittam1hub/supabase/spark_service.dart';

class SparkFeedCard extends StatefulWidget {
  final SparkPost post;
  final bool hasSparked;
  final VoidCallback onDoubleTap;
  final VoidCallback onSparkTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const SparkFeedCard({
    Key? key,
    required this.post,
    required this.hasSparked,
    required this.onDoubleTap,
    required this.onSparkTap,
    required this.onCommentTap,
    required this.onShareTap,
  }) : super(key: key);

  @override
  State<SparkFeedCard> createState() => _SparkFeedCardState();
}

class _SparkFeedCardState extends State<SparkFeedCard> with SingleTickerProviderStateMixin {
  bool _showSparkAnimation = false;
  late AnimationController _sparkAnimationController;
  late Animation<double> _sparkScaleAnimation;

  @override
  void initState() {
    super.initState();
    _sparkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sparkScaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _sparkAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _sparkAnimationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.hasSparked) {
      setState(() => _showSparkAnimation = true);
      _sparkAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _showSparkAnimation = false);
            _sparkAnimationController.reset();
          }
        });
      });
      widget.onDoubleTap();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }

  String _getTypeEmoji() {
    switch (widget.post.type) {
      case SparkPostType.IDEA:
        return '💡';
      case SparkPostType.SEEKING:
        return '🔍';
      case SparkPostType.OFFERING:
        return '🎁';
      case SparkPostType.QUESTION:
        return '❓';
      case SparkPostType.ANNOUNCEMENT:
        return '📢';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.surfaceContainerHighest,
                        backgroundImage: widget.post.authorAvatar != null
                            ? NetworkImage(widget.post.authorAvatar!)
                            : null,
                        child: widget.post.authorAvatar == null
                            ? Text(
                                widget.post.authorName.isNotEmpty
                                    ? widget.post.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.authorName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatTimeAgo(widget.post.createdAt)} • ${_getTypeEmoji()} ${widget.post.type.name}',
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    widget.post.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Content
                  Text(
                    widget.post.content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Tags
                  if (widget.post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.post.tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#$tag',
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  // Actions row
                  Row(
                    children: [
                      // Spark button
                      InkWell(
                        onTap: widget.onSparkTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 20,
                                color: widget.hasSparked ? Colors.amber[700] : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.post.sparkCount}',
                                style: textTheme.labelLarge?.copyWith(
                                  color: widget.hasSparked ? Colors.amber[700] : cs.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Comment button
                      InkWell(
                        onTap: widget.onCommentTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 20, color: cs.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.post.commentCount}',
                                style: textTheme.labelLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Share button
                      IconButton(
                        icon: Icon(Icons.share_outlined, size: 20, color: cs.onSurfaceVariant),
                        onPressed: widget.onShareTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Spark animation overlay
            if (_showSparkAnimation)
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _sparkScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _sparkScaleAnimation.value,
                        child: Icon(
                          Icons.bolt,
                          size: 80,
                          color: Colors.amber.withValues(alpha: 0.8),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SparkFeedCardSkeleton extends StatelessWidget {
  const SparkFeedCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 10,
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
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
