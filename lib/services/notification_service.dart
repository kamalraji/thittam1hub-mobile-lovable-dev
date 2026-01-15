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
}
