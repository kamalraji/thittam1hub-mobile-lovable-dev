import 'package:flutter/foundation.dart';

enum NotificationType {
  CONNECTION_REQUEST,
  CONNECTION_ACCEPTED,
  CIRCLE_INVITE,
  SPARK_REACTION,
  NEW_BADGE,
  LEVEL_UP,
  MUTUAL_CONNECTION,
}

@immutable
class NotificationItem {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? avatarUrl;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.avatarUrl,
    this.actionUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.CONNECTION_REQUEST,
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      avatarUrl: map['avatar_url'] as String?,
      actionUrl: map['action_url'] as String?,
      isRead: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'avatar_url': avatarUrl,
        'action_url': actionUrl,
        'read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        userId: userId,
        type: type,
        title: title,
        message: message,
        avatarUrl: avatarUrl,
        actionUrl: actionUrl,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
