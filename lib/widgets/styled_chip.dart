import 'package:flutter/material.dart';
import 'package:thittam1hub/theme.dart';

/// A reusable themed chip component that adapts to light/dark mode
class StyledChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final bool showDeleteIcon;
  final VoidCallback? onDelete;

  const StyledChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
    this.icon,
    this.showDeleteIcon = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipColor = color ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? chipColor : cs.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? cs.onPrimary : cs.onSurface,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (showDeleteIcon && onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A filter chip variant with selected state
class StyledFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? selectedColor;

  const StyledFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor ?? cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? (selectedColor ?? cs.primary) : cs.outline,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// A tag-style chip for displaying categories or labels
class StyledTagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StyledTagChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tagColor = color ?? cs.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tagColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tagColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
