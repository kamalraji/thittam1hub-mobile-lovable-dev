import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/profile_stats.dart';
import 'package:thittam1hub/models/profile_post.dart';

/// Service for managing user profiles and notification preferences
class ProfileService {
  /// Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data == null) return null;

      // The table may not store email; ensure required fields exist to avoid null cast errors
      final mutable = Map<String, dynamic>.from(data);
      mutable['email'] = mutable['email'] ?? SupabaseConfig.auth.currentUser?.email ?? '';
      // Ensure qr_code has a fallback (use userId as a stable default if missing)
      mutable['qr_code'] = mutable['qr_code'] ?? userId;

      return UserProfile.fromJson(mutable);
    } catch (e) {
      debugPrint('❌ Get user profile error: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await SupabaseConfig.client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
      debugPrint('✅ User profile updated');
    } catch (e) {
      debugPrint('❌ Update user profile error: $e');
      rethrow;
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences?> getNotificationPreferences(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (data == null) {
        // Return default preferences if none exist
        return NotificationPreferences(userId: userId);
      }
      return NotificationPreferences.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get notification preferences error: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences(NotificationPreferences prefs) async {
    try {
      // Upsert (insert or update)
      await SupabaseConfig.client
          .from('notification_preferences')
          .upsert(prefs.toJson());
      debugPrint('✅ Notification preferences updated');
    } catch (e) {
      debugPrint('❌ Update notification preferences error: $e');
      rethrow;
    }
  }

  /// Get count of events user has attended (past events with CONFIRMED status)
  Future<int> getEventsAttendedCount(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await SupabaseConfig.client
          .from('registrations')
          .select('event_id, events!inner(end_date)')
          .eq('user_id', userId)
          .eq('status', 'CONFIRMED')
          .lt('events.end_date', now);
      return response.length;
    } catch (e) {
      debugPrint('❌ Get events attended count error: $e');
      return 0;
    }
  }

  /// Get count of upcoming events user is registered for
  Future<int> getUpcomingEventsCount(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await SupabaseConfig.client
          .from('registrations')
          .select('event_id, events!inner(start_date)')
          .eq('user_id', userId)
          .eq('status', 'CONFIRMED')
          .gte('events.start_date', now);
      return response.length;
    } catch (e) {
      debugPrint('❌ Get upcoming events count error: $e');
      return 0;
    }
  }

  /// Get count of saved (favorited) events
  Future<int> getSavedEventsCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('saved_events')
          .select('id')
          .eq('user_id', userId);
      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Get saved events count error: $e');
      return 0;
    }
  }

  /// Upload avatar image to Supabase storage
  Future<String?> uploadAvatar(String userId, Uint8List imageBytes, String fileName) async {
    try {
      final path = 'avatars/$userId/$fileName';
      
      // Upload to storage
      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(path, imageBytes);
      
      // Get public URL
      final url = SupabaseConfig.client.storage.from('avatars').getPublicUrl(path);
      debugPrint('✅ Avatar uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Upload avatar error: $e');
      return null;
    }
  }

  /// Delete avatar from storage
  Future<void> deleteAvatar(String userId, String avatarUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(avatarUrl);
      final path = uri.pathSegments.skip(uri.pathSegments.indexOf('avatars')).join('/');
      
      await SupabaseConfig.client.storage.from('avatars').remove([path]);
      debugPrint('✅ Avatar deleted');
    } catch (e) {
      debugPrint('❌ Delete avatar error: $e');
    }
  }

  /// Upload cover image to Supabase storage
  Future<String?> uploadCoverImage(String userId, Uint8List imageBytes, String fileName) async {
    try {
      final path = 'covers/$userId/$fileName';
      
      // Upload to avatars bucket (reusing for covers)
      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(path, imageBytes);
      
      // Get public URL
      final url = SupabaseConfig.client.storage.from('avatars').getPublicUrl(path);
      debugPrint('✅ Cover uploaded: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Upload cover error: $e');
      return null;
    }
  }

  /// Delete cover image from storage
  Future<void> deleteCoverImage(String userId, String coverUrl) async {
    try {
      final uri = Uri.parse(coverUrl);
      final path = uri.pathSegments.skip(uri.pathSegments.indexOf('avatars')).join('/');
      
      await SupabaseConfig.client.storage.from('avatars').remove([path]);
      debugPrint('✅ Cover deleted');
    } catch (e) {
      debugPrint('❌ Delete cover error: $e');
    }
  }

  /// Set cover gradient theme
  Future<void> setCoverGradient(String userId, String? gradientId) async {
    try {
      await SupabaseConfig.client
          .from('user_profiles')
          .update({
            'cover_gradient_id': gradientId,
            'cover_image_url': null, // Clear custom image when setting gradient
          })
          .eq('id', userId);
      debugPrint('✅ Cover gradient set');
    } catch (e) {
      debugPrint('❌ Set cover gradient error: $e');
      rethrow;
    }
  }

  /// Get tickets count for user
  Future<int> getTicketsCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('registrations')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'CONFIRMED');
      return response.length;
    } catch (e) {
      debugPrint('❌ Get tickets count error: $e');
      return 0;
    }
  }

  /// Get event history (past events attended)
  Future<List<EventHistory>> getEventHistory(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await SupabaseConfig.client
          .from('registrations')
          .select('''
            id,
            status,
            created_at,
            events!inner(
              id,
              name,
              start_date,
              end_date,
              branding
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'CONFIRMED')
          .lt('events.end_date', now)
          // Order by the related table column using referencedTable
          .order('end_date', ascending: false, referencedTable: 'events');
      
      return response.map((json) => EventHistory.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get event history error: $e');
      return [];
    }
  }

  /// Get comprehensive profile stats
  Future<ProfileStats> getProfileStats(String userId) async {
    try {
      final results = await Future.wait([
        getEventsAttendedCount(userId),
        getUpcomingEventsCount(userId),
        getSavedEventsCount(userId),
        getConnectionsCount(userId),
        getPostsCount(userId),
        _getImpactData(userId),
      ]);

      final impactData = results[5] as Map<String, dynamic>;

      return ProfileStats(
        eventsAttended: results[0] as int,
        upcomingEvents: results[1] as int,
        savedEvents: results[2] as int,
        connectionsCount: results[3] as int,
        postsCount: results[4] as int,
        impactScore: impactData['impact_score'] ?? 0,
        badgesEarned: impactData['badges_count'] ?? 0,
        currentStreak: impactData['streak_count'] ?? 0,
        longestStreak: impactData['longest_streak'] ?? 0,
      );
    } catch (e) {
      debugPrint('❌ Get profile stats error: $e');
      return const ProfileStats();
    }
  }

  /// Get impact profile data (score, streak, badges)
  Future<Map<String, dynamic>> _getImpactData(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('impact_profiles')
          .select('impact_score, streak_count, badges')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return {'impact_score': 0, 'streak_count': 0, 'badges_count': 0};
      }

      final badges = response['badges'] as List<dynamic>? ?? [];
      return {
        'impact_score': response['impact_score'] ?? 0,
        'streak_count': response['streak_count'] ?? 0,
        'badges_count': badges.length,
      };
    } catch (e) {
      debugPrint('❌ Get impact data error: $e');
      return {'impact_score': 0, 'streak_count': 0, 'badges_count': 0};
    }
  }

  /// Get connections count for user
  Future<int> getConnectionsCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('connections')
          .select('id')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'ACCEPTED');
      return response.length;
    } catch (e) {
      debugPrint('❌ Get connections count error: $e');
      return 0;
    }
  }

  /// Get user's posts count
  Future<int> getPostsCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('spark_posts')
          .select('id')
          .eq('author_id', userId);
      return response.length;
    } catch (e) {
      debugPrint('❌ Get posts count error: $e');
      return 0;
    }
  }

  /// Get user's posts for profile display
  Future<List<ProfilePost>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      final response = await SupabaseConfig.client
          .from('spark_posts')
          .select('*')
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => ProfilePost.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Get user posts error: $e');
      return [];
    }
  }

  /// Get upcoming events for user
  Future<List<Map<String, dynamic>>> getUpcomingEvents(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await SupabaseConfig.client
          .from('registrations')
          .select('''
            id,
            status,
            events!inner(
              id,
              name,
              start_date,
              end_date,
              branding
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'CONFIRMED')
          .gte('events.start_date', now)
          .order('start_date', ascending: true, referencedTable: 'events')
          .limit(10);

      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('❌ Get upcoming events error: $e');
      return [];
    }
  }
}

/// Event history item for displaying past attended events
class EventHistory {
  final String registrationId;
  final String eventId;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;
  final String? bannerUrl;
  final RegistrationStatus status;
  final DateTime registeredAt;

  const EventHistory({
    required this.registrationId,
    required this.eventId,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    this.bannerUrl,
    required this.status,
    required this.registeredAt,
  });

  factory EventHistory.fromJson(Map<String, dynamic> json) {
    final event = json['events'] as Map<String, dynamic>;
    final branding = event['branding'] as Map<String, dynamic>?;
    
    return EventHistory(
      registrationId: json['id'] as String,
      eventId: event['id'] as String,
      eventName: event['name'] as String,
      startDate: DateTime.parse(event['start_date'] as String),
      endDate: DateTime.parse(event['end_date'] as String),
      bannerUrl: branding?['banner_url'] as String?,
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RegistrationStatus.CONFIRMED,
      ),
      registeredAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
