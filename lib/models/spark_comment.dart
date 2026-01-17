import 'package:flutter/foundation.dart';

@immutable
class SparkComment {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final int likeCount;
  final DateTime createdAt;
  final List<SparkComment> replies;

  const SparkComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    required this.likeCount,
    required this.createdAt,
    this.replies = const [],
  });

  factory SparkComment.fromMap(Map<String, dynamic> map) {
    return SparkComment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      parentId: map['parent_id'] as String?,
      content: map['content'] as String,
      authorName: map['author_name'] as String? ?? 'Anonymous',
      authorAvatar: map['author_avatar'] as String?,
      likeCount: map['like_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      replies: const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'parent_id': parentId,
        'content': content,
        'author_name': authorName,
        'author_avatar': authorAvatar,
        'like_count': likeCount,
        'created_at': createdAt.toIso8601String(),
      };

  SparkComment copyWith({
    List<SparkComment>? replies,
    int? likeCount,
  }) =>
      SparkComment(
        id: id,
        postId: postId,
        userId: userId,
        parentId: parentId,
        content: content,
        authorName: authorName,
        authorAvatar: authorAvatar,
        likeCount: likeCount ?? this.likeCount,
        createdAt: createdAt,
        replies: replies ?? this.replies,
      );
}
