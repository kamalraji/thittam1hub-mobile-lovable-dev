import 'package:flutter/material.dart';
import 'package:thittam1hub/theme.dart';

/// A reusable themed card component that adapts to light/dark mode
class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double? elevation;

  const StyledCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    return Container(
      margin: margin,
      child: Material(
        color: backgroundColor ?? cs.surfaceContainerHighest,
        borderRadius: radius,
        elevation: elevation ?? 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding ?? AppSpacing.paddingMd,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: cs.outline.withValues(alpha: 0.6),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A variant of StyledCard with gradient background
class StyledGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;

  const StyledGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    final colors = gradientColors ?? [AppColors.primary, AppColors.accent];

    return Container(
      margin: margin,
      child: Material(
        borderRadius: radius,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding ?? AppSpacing.paddingMd,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
