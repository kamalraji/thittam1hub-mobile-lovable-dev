import 'package:flutter/material.dart';
import 'package:thittam1hub/theme.dart';

/// Button variant types
enum StyledButtonVariant { primary, secondary, outlined, danger, ghost }

/// A reusable themed button component that adapts to light/dark mode
class StyledButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final StyledButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const StyledButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = StyledButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Color mapping based on variant
    final (bgColor, fgColor, borderColor) = switch (variant) {
      StyledButtonVariant.primary => (cs.primary, cs.onPrimary, cs.primary),
      StyledButtonVariant.secondary => (cs.secondary, cs.onSecondary, cs.secondary),
      StyledButtonVariant.outlined => (Colors.transparent, cs.primary, cs.outline),
      StyledButtonVariant.danger => (AppColors.error, Colors.white, AppColors.error),
      StyledButtonVariant.ghost => (Colors.transparent, cs.onSurface, Colors.transparent),
    };

    final buttonPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: BorderSide(color: borderColor),
          padding: buttonPadding,
          elevation: variant == StyledButtonVariant.ghost ? 0 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fgColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Icon-only button variant
class StyledIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final StyledButtonVariant variant;
  final double size;
  final String? tooltip;

  const StyledIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = StyledButtonVariant.ghost,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final color = switch (variant) {
      StyledButtonVariant.primary => cs.primary,
      StyledButtonVariant.secondary => cs.secondary,
      StyledButtonVariant.outlined => cs.onSurface,
      StyledButtonVariant.danger => AppColors.error,
      StyledButtonVariant.ghost => cs.onSurfaceVariant,
    };

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: size),
      tooltip: tooltip,
    );
  }
}
