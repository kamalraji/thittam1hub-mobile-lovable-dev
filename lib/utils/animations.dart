import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animation configuration constants for consistent timing
class AnimConfig {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 50);
  
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
}

/// Calculate stagger delay for list animations
Duration staggerDelay(int index, {int maxItems = 10}) {
  return Duration(milliseconds: AnimConfig.stagger.inMilliseconds * index.clamp(0, maxItems));
}

// =============================================================================
// BRANDED REFRESH INDICATOR
// =============================================================================

/// Custom refresh indicator with branded loading animation
class BrandedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const BrandedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;
    final bgColor = backgroundColor ?? (isDark ? const Color(0xFF1E1E2E) : Colors.white);

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await onRefresh();
      },
      color: primaryColor,
      backgroundColor: bgColor,
      strokeWidth: 3,
      displacement: 60,
      child: child,
    );
  }
}

// =============================================================================
// LOADING DOTS ANIMATION
// =============================================================================

/// Animated loading dots (three dots that bounce sequentially)
class LoadingDots extends StatefulWidget {
  final Color? color;
  final double size;
  final Duration duration;

  const LoadingDots({
    super.key,
    this.color,
    this.size = 8,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final bounce = value < 0.5 
                ? Curves.easeOut.transform(value * 2)
                : Curves.easeIn.transform((1 - value) * 2);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.3),
              child: Transform.translate(
                offset: Offset(0, -bounce * widget.size),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// =============================================================================
// FADE SLIDE TRANSITION
// =============================================================================

/// A widget that fades and slides in its child
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0, 0.05),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _offset = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// TAP SCALE WIDGET
// =============================================================================

/// A widget that scales down on tap for interactive feedback
class TapScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;
  final bool enabled;

  const TapScaleWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.duration = const Duration(milliseconds: 100),
    this.enabled = true,
  });

  @override
  State<TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<TapScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// SHIMMER LOADING
// =============================================================================

/// Shimmer loading effect placeholder
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2D32) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3A3D42) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_shimmer.value - 0.3).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SKELETON WIDGETS
// =============================================================================

/// Event card skeleton placeholder
class EventCardSkeleton extends StatelessWidget {
  const EventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          ShimmerLoading(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          // Title
          ShimmerLoading(
            width: 200,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Subtitle
          ShimmerLoading(
            width: 140,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Tags row
          Row(
            children: [
              ShimmerLoading(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 8),
              ShimmerLoading(
                width: 80,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Profile card skeleton
class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // Avatar
          const ShimmerLoading(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          const SizedBox(height: 12),
          // Name
          ShimmerLoading(
            width: 120,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Subtitle
          ShimmerLoading(
            width: 180,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => Column(
              children: [
                ShimmerLoading(
                  width: 40,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                ShimmerLoading(
                  width: 50,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }
}

/// Circle/Space card skeleton  
class CircleCardSkeleton extends StatelessWidget {
  const CircleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Icon
          const ShimmerLoading(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: 140,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                ShimmerLoading(
                  width: 200,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          // Button
          ShimmerLoading(
            width: 70,
            height: 32,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }
}

/// Spark post skeleton
class SparkPostSkeleton extends StatelessWidget {
  const SparkPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          ShimmerLoading(
            width: 80,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Title
          ShimmerLoading(
            width: double.infinity,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Content lines
          ShimmerLoading(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          ShimmerLoading(
            width: 250,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Tags
          Row(
            children: [
              ShimmerLoading(
                width: 50,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 8),
              ShimmerLoading(
                width: 70,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Footer
          Row(
            children: [
              ShimmerLoading(
                width: 60,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(width: 16),
              ShimmerLoading(
                width: 80,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Score card skeleton for Impact Hub
class ScoreCardSkeleton extends StatelessWidget {
  const ScoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          ShimmerLoading(
            width: 140,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ShimmerLoading(
            width: double.infinity,
            height: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Points text
          ShimmerLoading(
            width: 180,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// AppBar profile avatar skeleton
class AppBarAvatarSkeleton extends StatelessWidget {
  const AppBarAvatarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      width: 40,
      height: 40,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    );
  }
}

/// Notification badge skeleton
class NotificationBadgeSkeleton extends StatelessWidget {
  const NotificationBadgeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          ShimmerLoading(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(4),
          ),
          const Positioned(
            right: 0,
            top: 0,
            child: ShimmerLoading(
              width: 12,
              height: 12,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Score chip skeleton for AppBar
class ScoreChipSkeleton extends StatelessWidget {
  const ScoreChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: 80,
      height: 32,
      borderRadius: BorderRadius.circular(16),
    );
  }
}

/// Popular/Recommended circle card skeleton (horizontal layout)
class PopularCircleCardSkeleton extends StatelessWidget {
  const PopularCircleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          const ShimmerLoading(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 12),
          // Name
          ShimmerLoading(
            width: 140,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          // Description
          ShimmerLoading(
            width: 180,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          const Spacer(),
          // Tags
          ShimmerLoading(
            width: 120,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Button
          ShimmerLoading(
            width: double.infinity,
            height: 36,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }
}

/// Space card skeleton
class SpaceCardSkeleton extends StatelessWidget {
  const SpaceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic
          ShimmerLoading(
            width: 200,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Tags
          Row(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ShimmerLoading(
                width: 60,
                height: 24,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ),
          const SizedBox(height: 16),
          // Footer with avatars
          Row(
            children: [
              // Avatars
              Row(
                children: List.generate(3, (i) => Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 0 : 0),
                  child: const ShimmerLoading(
                    width: 30,
                    height: 30,
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                )),
              ),
              const SizedBox(width: 12),
              ShimmerLoading(
                width: 80,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              ShimmerLoading(
                width: 60,
                height: 32,
                borderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vibe game card skeleton
class VibeGameSkeleton extends StatelessWidget {
  const VibeGameSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          ShimmerLoading(
            width: 100,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Question
          ShimmerLoading(
            width: double.infinity,
            height: 18,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          // Options
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerLoading(
              width: double.infinity,
              height: 40,
              borderRadius: BorderRadius.circular(10),
            ),
          )),
          const SizedBox(height: 8),
          // Footer
          ShimmerLoading(
            width: 150,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Channel/DM tile skeleton
class ChannelTileSkeleton extends StatelessWidget {
  const ChannelTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          const ShimmerLoading(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerLoading(
                      width: 100,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const Spacer(),
                    ShimmerLoading(
                      width: 50,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ShimmerLoading(
                  width: 180,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic list skeleton builder
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;

  const SkeletonList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.separator,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => separator ?? const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return FadeSlideTransition(
          delay: staggerDelay(index),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

// =============================================================================
// STAGGERED LIST
// =============================================================================

/// Staggered list builder with fade animations
class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final Widget? separator;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.separator,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: itemCount,
      separatorBuilder: (_, __) => separator ?? const SizedBox(height: 6),
      itemBuilder: (context, index) {
        return FadeSlideTransition(
          delay: staggerDelay(index),
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

// =============================================================================
// ANIMATED COUNT
// =============================================================================

/// Animated count display
class AnimatedCount extends StatefulWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.count,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _count;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _count = IntTween(begin: 0, end: widget.count).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _previousCount = oldWidget.count;
      _count = IntTween(begin: _previousCount, end: widget.count).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _count,
      builder: (context, child) {
        return Text('${_count.value}', style: widget.style);
      },
    );
  }
}

// =============================================================================
// BOUNCE ANIMATION
// =============================================================================

/// Bounce animation wrapper for selection states
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration duration;

  const BounceAnimation({
    super.key,
    required this.child,
    this.animate = false,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BounceAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}

// =============================================================================
// PROFILE PAGE SKELETONS
// =============================================================================

/// Profile page header skeleton (avatar ring + info)
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar with progress ring placeholder
        const ShimmerLoading(
          width: 96,
          height: 96,
          borderRadius: BorderRadius.all(Radius.circular(48)),
        ),
        const SizedBox(height: 16),
        // Name
        ShimmerLoading(
          width: 150,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        // Organization
        ShimmerLoading(
          width: 120,
          height: 16,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        // Email
        ShimmerLoading(
          width: 180,
          height: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        // Completeness badge
        ShimmerLoading(
          width: 200,
          height: 32,
          borderRadius: BorderRadius.circular(16),
        ),
      ],
    );
  }
}

/// Quick stats row skeleton
class QuickStatsRowSkeleton extends StatelessWidget {
  const QuickStatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ShimmerLoading(
                width: 40,
                height: 32,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              ShimmerLoading(
                width: 60,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

/// Menu card skeleton
class MenuCardSkeleton extends StatelessWidget {
  const MenuCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const ShimmerLoading(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ShimmerLoading(
              width: 120,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const ShimmerLoading(
            width: 20,
            height: 20,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

/// QR code page skeleton
class QrCodeSkeleton extends StatelessWidget {
  const QrCodeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // QR code placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const ShimmerLoading(
            width: 250,
            height: 250,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        // Name
        ShimmerLoading(
          width: 150,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        // Instructions
        ShimmerLoading(
          width: 200,
          height: 16,
          borderRadius: BorderRadius.circular(4),
        ),
        const Spacer(),
        // Button
        ShimmerLoading(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.circular(24),
        ),
      ],
    );
  }
}
