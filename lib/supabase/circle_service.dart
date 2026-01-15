import 'package:flutter/foundation.dart';
import 'package:thittam1hub/models/circle.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CircleService {
  final _supabase = SupabaseConfig.client;

  // ================== READ Operations ==================

  /// Get a single circle by ID
  Future<Circle?> getCircleById(String circleId) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('id', circleId)
          .maybeSingle();

      if (response == null) return null;
      return Circle.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching circle: $e');
      return null;
    }
  }

  /// Fetches all public circles
  Future<List<Circle>> getAllPublicCircles({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('is_public', true)
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching public circles: $e');
      return [];
    }
  }

  /// Fetches circles by category
  Future<List<Circle>> getCirclesByCategory(String category, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('category', category)
          .eq('is_public', true)
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching circles by category: $e');
      return [];
    }
  }

  /// Fetches circles for a specific event
  Future<List<Circle>> getCirclesByEvent(String eventId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('event_id', eventId)
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching event circles: $e');
      return [];
    }
  }

  /// Fetches circles created by current user
  Future<List<Circle>> getMyCreatedCircles() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching my created circles: $e');
      return [];
    }
  }

  /// Fetches circles the user has joined
  Future<List<Circle>> getMyJoinedCircles() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get circle IDs user is member of
      final memberRows = await _supabase
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId);

      final circleIds = (memberRows as List)
          .map((e) => e['circle_id'] as String)
          .toList();

      if (circleIds.isEmpty) return [];

      // Fetch circle details
      final response = await _supabase
          .from('circles')
          .select('*')
          .inFilter('id', circleIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching my joined circles: $e');
      return [];
    }
  }

  /// Fetches circle IDs the user has joined
  Future<Set<String>> getUserCircles() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      // Get circle IDs user is member of
      final memberRows = await _supabase
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId);

      return (memberRows as List)
          .map((e) => e['circle_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint('Error fetching user circles: $e');
      return {};
    }
  }

  /// Fetches auto-matched circles based on user interests
  Future<List<Circle>> getAutoMatchedCircles() async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('is_public', true)
          .order('member_count', ascending: false)
          .limit(2);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching auto-matched circles: $e');
      return [];
    }
  }

  /// Fetches popular circles
  Future<List<Circle>> getPopularCircles({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('is_public', true)
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching popular circles: $e');
      return [];
    }
  }

  /// Fetches recommended circles for the user
  Future<List<Circle>> getRecommendedCircles({int limit = 5}) async {
    try {
      // TODO: Implement smarter recommendation based on user interests/skills
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recommended circles: $e');
      return [];
    }
  }

  /// Search circles by name or tags
  Future<List<Circle>> searchCircles(String query, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('circles')
          .select('*')
          .eq('is_public', true)
          .or('name.ilike.%$query%,tags.cs.{$query}')
          .order('member_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => Circle.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching circles: $e');
      return [];
    }
  }

  // ================== CREATE Operations ==================

  /// Create a new circle and auto-join the creator as admin
  Future<String> createCircle({
    required String name,
    String? description,
    required String icon,
    required bool isPublic,
    String? eventId,
    String type = 'USER_CREATED',
    String category = 'INTEREST',
    int? maxMembers,
    List<String> tags = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final inserted = await _supabase.from('circles').insert({
        'name': name,
        'description': description,
        'icon': icon,
        'created_by': userId,
        'is_public': isPublic,
        'is_private': !isPublic,
        'event_id': eventId,
        'type': type,
        'category': category,
        'max_members': maxMembers,
        'member_count': 1,
        'tags': tags,
      }).select('id').single();

      final circleId = inserted['id'] as String;

      // Add creator as admin member
      await _supabase.from('circle_members').insert({
        'circle_id': circleId,
        'user_id': userId,
        'role': 'ADMIN',
      });

      debugPrint('🆕 Created circle: $circleId');
      return circleId;
    } catch (e) {
      debugPrint('❌ Error creating circle: $e');
      rethrow;
    }
  }

  // ================== UPDATE Operations ==================

  /// Update circle details (only creator/admin can update)
  Future<void> updateCircle({
    required String circleId,
    String? name,
    String? description,
    String? icon,
    bool? isPublic,
    String? category,
    int? maxMembers,
    List<String>? tags,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (icon != null) updates['icon'] = icon;
      if (isPublic != null) {
        updates['is_public'] = isPublic;
        updates['is_private'] = !isPublic;
      }
      if (category != null) updates['category'] = category;
      if (maxMembers != null) updates['max_members'] = maxMembers;
      if (tags != null) updates['tags'] = tags;

      if (updates.isEmpty) return;

      await _supabase
          .from('circles')
          .update(updates)
          .eq('id', circleId)
          .eq('created_by', userId); // Only creator can update

      debugPrint('✅ Updated circle: $circleId');
    } catch (e) {
      debugPrint('❌ Error updating circle: $e');
      rethrow;
    }
  }

  // ================== DELETE Operations ==================

  /// Delete a circle (only creator can delete)
  Future<void> deleteCircle(String circleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase
          .from('circles')
          .delete()
          .eq('id', circleId)
          .eq('created_by', userId); // Only creator can delete

      debugPrint('🗑️ Deleted circle: $circleId');
    } catch (e) {
      debugPrint('❌ Error deleting circle: $e');
      rethrow;
    }
  }

  // ================== MEMBERSHIP Operations ==================

  /// Check if user is a member of a circle
  Future<bool> isUserMember(String circleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('circle_members')
          .select('user_id')
          .eq('circle_id', circleId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking circle membership: $e');
      return false;
    }
  }

  /// Get user's role in a circle
  Future<String?> getUserRole(String circleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('circle_members')
          .select('role')
          .eq('circle_id', circleId)
          .eq('user_id', userId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  /// Get all circle IDs the user is a member of
  Future<Set<String>> getUserCircleIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('circle_members')
          .select('circle_id')
          .eq('user_id', userId);

      return (response as List)
          .map((e) => e['circle_id'] as String)
          .toSet();
    } catch (e) {
      debugPrint('Error fetching user circles: $e');
      return {};
    }
  }

  /// Get all members of a circle
  Future<List<CircleMember>> getCircleMembers(String circleId) async {
    try {
      final response = await _supabase
          .from('circle_members')
          .select('*')
          .eq('circle_id', circleId)
          .order('joined_at', ascending: true);

      return (response as List)
          .map((data) => CircleMember.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching circle members: $e');
      return [];
    }
  }

  /// Get member count for a circle
  Future<int> getMemberCount(String circleId) async {
    try {
      final response = await _supabase
          .from('circle_members')
          .select('user_id')
          .eq('circle_id', circleId);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting member count: $e');
      return 0;
    }
  }

  /// Join a circle
  Future<void> joinCircle(String circleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Check if circle has max members limit
      final circle = await getCircleById(circleId);
      if (circle != null && circle.maxMembers != null) {
        final currentCount = await getMemberCount(circleId);
        if (currentCount >= circle.maxMembers!) {
          throw Exception('Circle is full');
        }
      }

      await _supabase.from('circle_members').insert({
        'circle_id': circleId,
        'user_id': userId,
        'role': 'MEMBER',
      });

      // Update member count
      await _updateMemberCount(circleId, 1);

      debugPrint('✅ Joined circle: $circleId');
    } catch (e) {
      debugPrint('❌ Error joining circle: $e');
      rethrow;
    }
  }

  /// Leave a circle
  Future<void> leaveCircle(String circleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase
          .from('circle_members')
          .delete()
          .match({'circle_id': circleId, 'user_id': userId});

      // Update member count
      await _updateMemberCount(circleId, -1);

      debugPrint('🚪 Left circle: $circleId');
    } catch (e) {
      debugPrint('❌ Error leaving circle: $e');
      rethrow;
    }
  }

  /// Update member role (admin only)
  Future<void> updateMemberRole({
    required String circleId,
    required String targetUserId,
    required String newRole,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Verify current user is admin
      final currentRole = await getUserRole(circleId);
      if (currentRole != 'ADMIN') {
        throw Exception('Only admins can change roles');
      }

      await _supabase
          .from('circle_members')
          .update({'role': newRole})
          .eq('circle_id', circleId)
          .eq('user_id', targetUserId);

      debugPrint('👑 Updated role for $targetUserId to $newRole');
    } catch (e) {
      debugPrint('❌ Error updating member role: $e');
      rethrow;
    }
  }

  /// Remove a member from circle (admin only)
  Future<void> removeMember({
    required String circleId,
    required String targetUserId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Verify current user is admin
      final currentRole = await getUserRole(circleId);
      if (currentRole != 'ADMIN') {
        throw Exception('Only admins can remove members');
      }

      await _supabase
          .from('circle_members')
          .delete()
          .eq('circle_id', circleId)
          .eq('user_id', targetUserId);

      // Update member count
      await _updateMemberCount(circleId, -1);

      debugPrint('🚫 Removed member $targetUserId from circle');
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      rethrow;
    }
  }

  /// Helper to update member count
  Future<void> _updateMemberCount(String circleId, int delta) async {
    try {
      final circle = await getCircleById(circleId);
      if (circle == null) return;

      final newCount = (circle.memberCount + delta).clamp(0, 999999);
      await _supabase
          .from('circles')
          .update({'member_count': newCount})
          .eq('id', circleId);
    } catch (e) {
      debugPrint('Error updating member count: $e');
    }
  }

  // ================== MESSAGING Operations ==================

  /// Send a message in a circle
  Future<void> sendMessage(String circleId, String content) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('circle_messages').insert({
        'circle_id': circleId,
        'user_id': userId,
        'content': content,
      });

      debugPrint('💬 Message sent to circle: $circleId');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages for a circle
  Future<List<CircleMessage>> getMessages(String circleId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('circle_messages')
          .select('*')
          .eq('circle_id', circleId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => CircleMessage.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  /// Get real-time stream of messages for a circle
  Stream<List<CircleMessage>> getMessagesStream(String circleId) {
    return _supabase
        .from('circle_messages')
        .stream(primaryKey: ['id'])
        .eq('circle_id', circleId)
        .order('created_at', ascending: false)
        .map((payload) =>
            payload.map((e) => CircleMessage.fromMap(e)).toList());
  }

  /// Delete a message (only message author or admin)
  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase
          .from('circle_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', userId); // Only author can delete

      debugPrint('🗑️ Deleted message: $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  // ================== REAL-TIME Subscriptions ==================

  /// Subscribe to circle updates
  RealtimeChannel subscribeToCircle(String circleId, Function(Circle) onUpdate) {
    return _supabase
        .channel('circle_$circleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'circles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: circleId,
          ),
          callback: (payload) {
            try {
              final data = payload.newRecord;
              final circle = Circle.fromMap(data);
              onUpdate(circle);
            } catch (e) {
              debugPrint('Error in circle update callback: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to member changes in a circle
  RealtimeChannel subscribeToMembers(
    String circleId,
    Function(List<CircleMember>) onMembersChange,
  ) {
    return _supabase
        .channel('circle_members_$circleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'circle_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'circle_id',
            value: circleId,
          ),
          callback: (payload) async {
            try {
              // Refetch all members on any change
              final members = await getCircleMembers(circleId);
              onMembersChange(members);
            } catch (e) {
              debugPrint('Error in members callback: $e');
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to new messages in a circle
  RealtimeChannel subscribeToNewMessages(
    String circleId,
    Function(CircleMessage) onNewMessage,
  ) {
    return _supabase
        .channel('circle_messages_$circleId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'circle_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'circle_id',
            value: circleId,
          ),
          callback: (payload) {
            try {
              final data = payload.newRecord;
              final message = CircleMessage.fromMap(data);
              onNewMessage(message);
            } catch (e) {
              debugPrint('Error in new message callback: $e');
            }
          },
        )
        .subscribe();
  }
}
