import 'package:flutter/material.dart';
import '../theme.dart';

enum StyledAvatarSize { xs, sm, md, lg, xl }

class StyledAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final StyledAvatarSize size;
  final bool isOnline;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final IconData? fallbackIcon;

  const StyledAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = StyledAvatarSize.md,
    this.isOnline = false,
    this.onTap,
    this.backgroundColor,
    this.fallbackIcon,
  });

  double get _size => switch (size) {
    StyledAvatarSize.xs => 24,
    StyledAvatarSize.sm => 32,
    StyledAvatarSize.md => 48,
    StyledAvatarSize.lg => 64,
    StyledAvatarSize.xl => 96,
  };

  double get _fontSize => switch (size) {
    StyledAvatarSize.xs => 10,
    StyledAvatarSize.sm => 12,
    StyledAvatarSize.md => 18,
    StyledAvatarSize.lg => 24,
    StyledAvatarSize.xl => 36,
  };

  double get _iconSize => switch (size) {
    StyledAvatarSize.xs => 14,
    StyledAvatarSize.sm => 18,
    StyledAvatarSize.md => 24,
    StyledAvatarSize.lg => 32,
    StyledAvatarSize.xl => 48,
  };

  double get _indicatorSize => switch (size) {
    StyledAvatarSize.xs => 8,
    StyledAvatarSize.sm => 10,
    StyledAvatarSize.md => 14,
    StyledAvatarSize.lg => 16,
    StyledAvatarSize.xl => 20,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? cs.primaryContainer;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(
                color: cs.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: _buildContent(context, cs),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _indicatorSize,
                height: _indicatorSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                  border: Border.all(
                    color: cs.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: _size,
        height: _size,
        errorBuilder: (context, error, stackTrace) => _buildFallback(context, cs),
      );
    }
    return _buildFallback(context, cs);
  }

  Widget _buildFallback(BuildContext context, ColorScheme cs) {
    if (initials != null && initials!.isNotEmpty) {
      return Center(
        child: Text(
          initials!.toUpperCase(),
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: cs.onPrimaryContainer,
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        fallbackIcon ?? Icons.person,
        size: _iconSize,
        color: cs.onPrimaryContainer,
      ),
    );
  }
}
