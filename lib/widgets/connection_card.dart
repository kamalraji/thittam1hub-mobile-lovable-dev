import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thittam1hub/models/connection.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/theme.dart';

/// Card widget for displaying a connection
class ConnectionCard extends StatelessWidget {
  final Connection connection;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onConnect;
  final bool showActions;

  const ConnectionCard({
    super.key,
    required this.connection,
    this.onTap,
    this.onMessage,
    this.onAccept,
    this.onDecline,
    this.onConnect,
    this.showActions = true,
  });

  Color _getMatchColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with online indicator
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: cs.primary.withValues(alpha: 0.2),
                            backgroundImage: connection.otherUserAvatar != null
                                ? NetworkImage(connection.otherUserAvatar!)
                                : null,
                            child: connection.otherUserAvatar == null
                                ? Text(
                                    connection.otherUserName[0].toUpperCase(),
                                    style: context.textStyles.titleLarge?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          if (connection.isOnline)
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cs.surface, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    connection.otherUserName,
                                    style: context.textStyles.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Match score badge
                                if (connection.matchScore > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMatchColor(connection.matchScore).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${connection.matchScore}%',
                                      style: context.textStyles.labelSmall?.copyWith(
                                        color: _getMatchColor(connection.matchScore),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (connection.otherUserHeadline != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                connection.otherUserHeadline!,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (connection.otherUserOrganization != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      connection.otherUserOrganization!,
                                      style: context.textStyles.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Action buttons
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    _buildActions(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // For pending requests (incoming)
    if (connection.isPending && onAccept != null && onDecline != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onDecline?.call();
              },
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Decline'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAccept?.call();
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept'),
            ),
          ),
        ],
      );
    }

    // For suggestions (not connected)
    if (onConnect != null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onConnect?.call();
          },
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Connect'),
        ),
      );
    }

    // For accepted connections
    if (connection.isAccepted && onMessage != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onMessage?.call();
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Profile'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

/// Card widget for displaying a suggested profile
class SuggestionCard extends StatelessWidget {
  final ImpactProfile profile;
  final int matchScore;
  final String? matchReason;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onSkip;

  const SuggestionCard({
    super.key,
    required this.profile,
    this.matchScore = 0,
    this.matchReason,
    this.onTap,
    this.onConnect,
    this.onSkip,
  });

  Color _getMatchColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.primary.withValues(alpha: 0.2),
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.fullName[0].toUpperCase(),
                                style: context.textStyles.titleLarge?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      if (profile.isOnline)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.fullName,
                                style: context.textStyles.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (matchScore > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getMatchColor(matchScore).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${matchScore}%',
                                  style: context.textStyles.labelSmall?.copyWith(
                                    color: _getMatchColor(matchScore),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (profile.headline.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.headline,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (matchReason != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  matchReason!,
                                  style: context.textStyles.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onSkip != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onSkip?.call();
                        },
                        child: const Text('Skip'),
                      ),
                    ),
                  if (onSkip != null) const SizedBox(width: 12),
                  Expanded(
                    flex: onSkip != null ? 1 : 0,
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onConnect?.call();
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
