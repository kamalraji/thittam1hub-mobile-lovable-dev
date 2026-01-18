import 'package:flutter/foundation.dart';
import 'package:thittam1hub/models/notification_item.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _supabase = SupabaseConfig.client;

  /// Get all notifications for current user
  Future<List<NotificationItem>> getNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((data) => NotificationItem.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      debugPrint('✅ Notification marked as read');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);
      debugPrint('✅ All notifications marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }

  /// Subscribe to new notifications
  RealtimeChannel subscribeToNotifications(Function(NotificationItem) onNewNotification) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final channel = _supabase.channel('notifications_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          try {
            final data = payload.newRecord;
            final notification = NotificationItem.fromMap(data);
            onNewNotification(notification);
          } catch (e) {
            debugPrint('Error in notification callback: $e');
          }
        },
      )
      .subscribe();
    return channel;
  }

  /// Create notification (typically called by server-side trigger)
  Future<void> createNotification({
    required String targetUserId,
    required NotificationType type,
    required String title,
    required String message,
    String? avatarUrl,
    String? actionUrl,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': targetUserId,
        'type': type.name,
        'title': title,
        'message': message,
        'avatar_url': avatarUrl,
        'action_url': actionUrl,
        'read': false,
      });
      debugPrint('📬 Notification created');
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
    }
  }

  /// Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      debugPrint('🗑️ Notification deleted');
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notifications for current user
  Future<void> clearAllNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', userId);
      debugPrint('🗑️ All notifications cleared');
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
    }
  }

  /// Get notification preferences for current user
  Future<NotificationPreferences> getPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return const NotificationPreferences();

      final response = await _supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return const NotificationPreferences();
      return NotificationPreferences.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
      return const NotificationPreferences();
    }
  }

  /// Update a specific notification preference
  Future<void> updatePreference(String key, bool value) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('notification_preferences').upsert({
        'user_id': userId,
        key: value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Preference updated: $key = $value');
    } catch (e) {
      debugPrint('❌ Error updating preference: $e');
    }
  }
}

/// Model for notification preferences
class NotificationPreferences {
  final bool connectionRequests;
  final bool connectionAccepted;
  final bool circleInvites;
  final bool sparkReactions;
  final bool achievements;
  final bool highMatchOnline;

  const NotificationPreferences({
    this.connectionRequests = true,
    this.connectionAccepted = true,
    this.circleInvites = true,
    this.sparkReactions = true,
    this.achievements = true,
    this.highMatchOnline = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      connectionRequests: map['connection_requests'] ?? true,
      connectionAccepted: map['connection_accepted'] ?? true,
      circleInvites: map['circle_invites'] ?? true,
      sparkReactions: map['spark_reactions'] ?? true,
      achievements: map['achievements'] ?? true,
      highMatchOnline: map['high_match_online'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'connection_requests': connectionRequests,
    'connection_accepted': connectionAccepted,
    'circle_invites': circleInvites,
    'spark_reactions': sparkReactions,
    'achievements': achievements,
    'high_match_online': highMatchOnline,
  };

  NotificationPreferences copyWith({
    bool? connectionRequests,
    bool? connectionAccepted,
    bool? circleInvites,
    bool? sparkReactions,
    bool? achievements,
    bool? highMatchOnline,
  }) {
    return NotificationPreferences(
      connectionRequests: connectionRequests ?? this.connectionRequests,
      connectionAccepted: connectionAccepted ?? this.connectionAccepted,
      circleInvites: circleInvites ?? this.circleInvites,
      sparkReactions: sparkReactions ?? this.sparkReactions,
      achievements: achievements ?? this.achievements,
      highMatchOnline: highMatchOnline ?? this.highMatchOnline,
    );
  }
}
