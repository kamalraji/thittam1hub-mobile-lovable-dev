import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/supabase/spark_service.dart';
import 'package:thittam1hub/widgets/shimmer_loading.dart';

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

class _SparkFeedCardState extends State<SparkFeedCard> with TickerProviderStateMixin {
  bool _showSparkAnimation = false;
  late AnimationController _sparkAnimationController;
  late Animation<double> _sparkScaleAnimation;
  late AnimationController _tapScaleController;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    _sparkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sparkScaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _sparkAnimationController, curve: Curves.elasticOut),
    );
    
    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _tapScaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _tapScaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sparkAnimationController.dispose();
    _tapScaleController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.hasSparked) {
      HapticFeedback.mediumImpact();
      setState(() => _showSparkAnimation = true);
      _sparkAnimationController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
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

  Color _getTypeColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (widget.post.type) {
      case SparkPostType.IDEA:
        return Colors.amber;
      case SparkPostType.SEEKING:
        return Colors.blue;
      case SparkPostType.OFFERING:
        return Colors.green;
      case SparkPostType.QUESTION:
        return Colors.purple;
      case SparkPostType.ANNOUNCEMENT:
        return cs.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.post.type) {
      case SparkPostType.IDEA:
        return Icons.lightbulb_outline_rounded;
      case SparkPostType.SEEKING:
        return Icons.search_rounded;
      case SparkPostType.OFFERING:
        return Icons.card_giftcard_rounded;
      case SparkPostType.QUESTION:
        return Icons.help_outline_rounded;
      case SparkPostType.ANNOUNCEMENT:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(context);
    
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onTapDown: (_) => _tapScaleController.forward(),
      onTapUp: (_) => _tapScaleController.reverse(),
      onTapCancel: () => _tapScaleController.reverse(),
      child: AnimatedBuilder(
        animation: _tapScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _tapScaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark 
                      ? cs.outline.withValues(alpha: 0.15)
                      : cs.outline.withValues(alpha: 0.08),
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row with enhanced styling
                        Row(
                          children: [
                            // Avatar with online indicator
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.primary.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    backgroundImage: widget.post.authorAvatar != null
                                        ? NetworkImage(widget.post.authorAvatar!)
                                        : null,
                                    child: widget.post.authorAvatar == null
                                        ? Text(
                                            widget.post.authorName.isNotEmpty
                                                ? widget.post.authorName[0].toUpperCase()
                                                : '?',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: cs.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                // Online indicator
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
                                        width: 2,
                                      ),
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
                                  Row(
                                    children: [
                                      Text(
                                        widget.post.authorName,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '· ${_formatTimeAgo(widget.post.createdAt)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Post type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getTypeIcon(),
                                          size: 12,
                                          color: typeColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.post.type.name,
                                          style: textTheme.labelSmall?.copyWith(
                                            color: typeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
                              onPressed: () {},
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        
                        // Title with better typography
                        Text(
                          widget.post.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Content
                        Text(
                          widget.post.content,
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Tags with gradient pills
                        if (widget.post.tags.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: widget.post.tags.take(4).map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary.withValues(alpha: 0.08),
                                      cs.tertiary.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 14),
                        
                        // Divider
                        Divider(
                          color: cs.outline.withValues(alpha: 0.1),
                          height: 1,
                        ),
                        const SizedBox(height: 10),
                        
                        // Enhanced actions row
                        Row(
                          children: [
                            // Spark button with animation
                            _ActionButton(
                              icon: Icons.bolt_rounded,
                              count: widget.post.sparkCount,
                              isActive: widget.hasSparked,
                              activeColor: Colors.amber.shade600,
                              onTap: widget.onSparkTap,
                            ),
                            const SizedBox(width: 16),
                            
                            // Comment button
                            _ActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              count: widget.post.commentCount,
                              onTap: widget.onCommentTap,
                            ),
                            
                            const Spacer(),
                            
                            // Share button
                            IconButton(
                              icon: Icon(
                                Icons.share_outlined,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: widget.onShareTap,
                              visualDensity: VisualDensity.compact,
                            ),
                            
                            // Bookmark button
                            IconButton(
                              icon: Icon(
                                Icons.bookmark_border_rounded,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () {},
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Double-tap spark animation overlay
                  if (_showSparkAnimation)
                    Positioned.fill(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _sparkScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _sparkScaleAnimation.value,
                              child: Opacity(
                                opacity: (1.5 - _sparkScaleAnimation.value).clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 64,
                                    color: Colors.amber.shade600,
                                  ),
                                ),
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
        },
      ),
    );
  }
}

/// Reusable action button with animated counter
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.count,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = isActive ? (activeColor ?? cs.primary) : cs.onSurfaceVariant;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (count > 0) ...[
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  '$count',
                  key: ValueKey(count),
                  style: textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerPlaceholder(
                width: 48,
                height: 48,
                isCircle: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerPlaceholder(
                      width: 120,
                      height: 14,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    ShimmerPlaceholder(
                      width: 80,
                      height: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShimmerPlaceholder(
            width: double.infinity,
            height: 18,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 10),
          ShimmerPlaceholder(
            width: double.infinity,
            height: 60,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ShimmerPlaceholder(
                width: 70,
                height: 28,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 10),
              ShimmerPlaceholder(
                width: 70,
                height: 28,
                borderRadius: BorderRadius.circular(14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
