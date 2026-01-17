import 'package:flutter/material.dart';
import 'package:thittam1hub/models/spark_comment.dart';

class CommentItem extends StatelessWidget {
  final SparkComment comment;
  final bool isReply;
  final VoidCallback onReplyTap;
  final VoidCallback onLikeTap;
  final bool isLiked;

  const CommentItem({
    Key? key,
    required this.comment,
    this.isReply = false,
    required this.onReplyTap,
    required this.onLikeTap,
    this.isLiked = false,
  }) : super(key: key);

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 48 : 16,
        right: 16,
        top: 12,
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: cs.surfaceContainerHighest,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!)
                : null,
            child: comment.authorAvatar == null
                ? Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: isReply ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author and time
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Content
                Text(
                  comment.content,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                
                // Actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLikeTap,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : cs.onSurfaceVariant,
                          ),
                          if (comment.likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likeCount}',
                              style: textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (!isReply)
                      GestureDetector(
                        onTap: onReplyTap,
                        child: Text(
                          'Reply',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Nested replies (max 2 levels)
                if (!isReply && comment.replies.isNotEmpty)
                  Column(
                    children: comment.replies.map((reply) {
                      return CommentItem(
                        comment: reply,
                        isReply: true,
                        onReplyTap: onReplyTap,
                        onLikeTap: () {},
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
