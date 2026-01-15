import 'package:flutter/material.dart';
import 'package:thittam1hub/theme.dart';

/// Button variant types
enum StyledButtonVariant { primary, secondary, outlined, danger, ghost }

/// A compact themed button with press animation
class StyledButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final StyledButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final bool compact;

  const StyledButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = StyledButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.compact = true,
  });

  @override
  State<StyledButton> createState() => _StyledButtonState();
}

class _StyledButtonState extends State<StyledButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bgColor, fgColor, borderColor) = switch (widget.variant) {
      StyledButtonVariant.primary => (cs.primary, cs.onPrimary, cs.primary),
      StyledButtonVariant.secondary => (cs.secondary, cs.onSecondary, cs.secondary),
      StyledButtonVariant.outlined => (Colors.transparent, cs.primary, cs.outline),
      StyledButtonVariant.danger => (AppColors.error, Colors.white, AppColors.error),
      StyledButtonVariant.ghost => (Colors.transparent, cs.onSurface, Colors.transparent),
    };

    final buttonPadding = widget.padding ?? EdgeInsets.symmetric(
      horizontal: widget.compact ? 14 : 20,
      vertical: widget.compact ? 10 : 12,
    );

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              side: BorderSide(color: borderColor),
              padding: buttonPadding,
              elevation: widget.variant == StyledButtonVariant.ghost ? 0 : 0,
              minimumSize: Size(0, widget.compact ? 36 : 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: widget.compact ? 16 : 18),
                        SizedBox(width: widget.compact ? 6 : 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.compact ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Compact icon-only button
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
    this.size = 20,
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
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
