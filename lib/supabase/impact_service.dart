import 'package:flutter/foundation.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/models/connection_request_item.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImpactService {
  final _supabase = SupabaseConfig.client;

  /// Get current user's impact profile
  Future<ImpactProfile?> getMyImpactProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('impact_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ImpactProfile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching my impact profile: $e');
      return null;
    }
  }

  /// Compute a match score (0-100) between two profiles based on
  /// skills/interests overlap and looking-for complementarity.
  /// Weights: skills 50%, interests 30%, looking-for complementarity 20%.
  int calculateMatchScore(ImpactProfile me, ImpactProfile other) {
    int pct(Set a, Set b) => a.isEmpty ? 0 : ((a.intersection(b).length / a.length) * 100).round();

    final meSkills = me.skills.toSet();
    final otherSkills = other.skills.toSet();
    final meInterests = me.interests.toSet();
    final otherInterests = other.interests.toSet();
    final meLF = me.lookingFor.toSet();
    final otherLF = other.lookingFor.toSet();

    // Direct overlaps
    final skillsOverlap = pct(meSkills, otherSkills);
    final interestsOverlap = pct(meInterests, otherInterests);

    // Complementarity: my skills match what they are looking for OR vice versa
    final skillToLF = pct(meSkills, otherLF);
    final theirSkillToMyLF = pct(otherSkills, meLF);
    final complement = ((skillToLF + theirSkillToMyLF) / 2).round();

    final score = (skillsOverlap * 0.5 + interestsOverlap * 0.3 + complement * 0.2).round();
    return score.clamp(0, 100);
  }

  /// Get a profile by user id
  Future<ImpactProfile?> getImpactProfileByUserId(String userId) async {
    try {
      final response = await _supabase.from('impact_profiles').select('*').eq('user_id', userId).maybeSingle();
      if (response == null) return null;
      return ImpactProfile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching impact profile by user id: $e');
      return null;
    }
  }

  /// Fetch incoming pending connection requests for current user (with requester profile info)
  Future<List<ConnectionRequestItem>> getIncomingPendingRequests() async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) return [];

      // Step 1: Get pending connection requests
      final rows = await _supabase
          .from('connections')
          .select('id, requester_id, connection_type, created_at, receiver_id, status')
          .eq('receiver_id', myId)
          .eq('status', 'PENDING')
          .order('created_at', ascending: false);

      final myProfile = await getMyImpactProfile();
      final items = <ConnectionRequestItem>[];
      
      for (final r in (rows as List)) {
        final requesterId = r['requester_id'] as String;
        
        // Step 2: Fetch requester's impact_profile
        final requesterProfile = await getImpactProfileByUserId(requesterId);
        
        // Compute match score if my profile available
        int match = 50;
        try {
          if (myProfile != null && requesterProfile != null) {
            match = calculateMatchScore(myProfile, requesterProfile);
          }
        } catch (e) {
          debugPrint('Error computing match score for request: $e');
        }
        
        items.add(ConnectionRequestItem(
          id: r['id'] as String,
          requesterId: requesterId,
          requesterName: requesterProfile?.fullName ?? 'Someone',
          requesterAvatar: requesterProfile?.avatarUrl,
          connectionType: r['connection_type'] as String? ?? 'NETWORKING',
          createdAt: DateTime.parse(r['created_at'] as String),
          matchScore: match,
        ));
      }
      return items;
    } catch (e) {
      debugPrint('Error fetching incoming pending requests: $e');
      return [];
    }
  }

  /// Accept or decline a connection request
  Future<void> respondToConnectionRequest({required String requestId, required bool accept}) async {
    try {
      await _supabase
          .from('connections')
          .update({'status': accept ? 'ACCEPTED' : 'DECLINED', 'responded_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
      debugPrint(accept ? '✅ Connection accepted' : '🚫 Connection declined');
    } catch (e) {
      debugPrint('❌ Error responding to connection request: $e');
      rethrow;
    }
  }
  /// Fetches a list of impact profiles with optional filters
  Future<List<ImpactProfile>> getImpactProfiles({
    List<String>? skills,
    List<String>? interests,
    List<String>? lookingFor,
    bool filterByEvent = true,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      var query = _supabase.from('impact_profiles').select('*');

      // Exclude current user
      if (userId != null) {
        query = query.neq('user_id', userId);
      }

      final response = await query;
      var profiles = (response as List)
          .map((data) => ImpactProfile.fromMap(data as Map<String, dynamic>))
          .toList();

      // Apply client-side filters
      if (skills != null && skills.isNotEmpty) {
        profiles = profiles.where((p) => p.skills.any((s) => skills.contains(s))).toList();
      }
      if (interests != null && interests.isNotEmpty) {
        profiles = profiles.where((p) => p.interests.any((i) => interests.contains(i))).toList();
      }
      if (lookingFor != null && lookingFor.isNotEmpty) {
        profiles = profiles.where((p) => p.lookingFor.any((l) => lookingFor.contains(l))).toList();
      }

      return profiles;
    } catch (e) {
      debugPrint('Error fetching impact profiles: $e');
      return [];
    }
  }

  /// Send connection request
  Future<void> sendConnectionRequest(String targetUserId, String connectionType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('connections').insert({
        'requester_id': userId,
        'receiver_id': targetUserId,
        'status': 'PENDING',
        'connection_type': connectionType,
      });
      debugPrint('✅ Connection request sent');
    } catch (e) {
      debugPrint('❌ Error sending connection request: $e');
      rethrow;
    }
  }

  /// Skip a profile (optional: track for better recommendations)
  Future<void> skipProfile(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Optional: Track skips for recommendation algorithm
      await _supabase.from('profile_skips').insert({
        'user_id': userId,
        'skipped_user_id': targetUserId,
      });
      debugPrint('⏭️  Profile skipped');
    } catch (e) {
      debugPrint('❌ Error skipping profile: $e');
    }
  }

  /// Save a profile to favorites
  Future<void> saveProfile(String targetUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _supabase.from('saved_profiles').insert({
        'user_id': userId,
        'saved_user_id': targetUserId,
      });
      debugPrint('⭐ Profile saved');
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      rethrow;
    }
  }

  /// Update impact profile
  Future<void> updateImpactProfile(ImpactProfile profile) async {
    try {
      await _supabase
          .from('impact_profiles')
          .update(profile.toMap())
          .eq('id', profile.id);
      debugPrint('✅ Impact profile updated');
    } catch (e) {
      debugPrint('❌ Error updating impact profile: $e');
      rethrow;
    }
  }

  /// Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('impact_profiles')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      debugPrint('📡 Online status: $isOnline');
    } catch (e) {
      debugPrint('❌ Error updating online status: $e');
    }
  }

  /// Subscribe to online status changes for Pulse profiles
  RealtimeChannel subscribeToOnlineStatus(Function(String userId, bool isOnline) onStatusChange) {
    final channel = _supabase.channel('online_status')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'impact_profiles',
        callback: (payload) {
          try {
            final data = payload.newRecord;
            final userId = data['user_id'] as String?;
            final isOnline = data['is_online'] as bool? ?? false;
            if (userId != null) {
              onStatusChange(userId, isOnline);
            }
          } catch (e) {
            debugPrint('Error in online status callback: $e');
          }
        },
      )
      .subscribe();
    return channel;
  }

  /// Get mutual connections between current user and target user
  Future<List<ImpactProfile>> getMutualConnections(String targetUserId) async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) return [];

      // Get my accepted connections
      final myConnections = await _supabase
          .from('connections')
          .select('requester_id, receiver_id')
          .eq('status', 'ACCEPTED')
          .or('requester_id.eq.$myId,receiver_id.eq.$myId');

      // Extract user IDs (exclude myself)
      final myConnectionIds = <String>{};
      for (final c in (myConnections as List)) {
        final requesterId = c['requester_id'] as String;
        final receiverId = c['receiver_id'] as String;
        if (requesterId != myId) myConnectionIds.add(requesterId);
        if (receiverId != myId) myConnectionIds.add(receiverId);
      }

      // Get target user's accepted connections
      final theirConnections = await _supabase
          .from('connections')
          .select('requester_id, receiver_id')
          .eq('status', 'ACCEPTED')
          .or('requester_id.eq.$targetUserId,receiver_id.eq.$targetUserId');

      // Extract user IDs (exclude target)
      final theirConnectionIds = <String>{};
      for (final c in (theirConnections as List)) {
        final requesterId = c['requester_id'] as String;
        final receiverId = c['receiver_id'] as String;
        if (requesterId != targetUserId) theirConnectionIds.add(requesterId);
        if (receiverId != targetUserId) theirConnectionIds.add(receiverId);
      }

      // Find intersection
      final mutualIds = myConnectionIds.intersection(theirConnectionIds).toList();
      if (mutualIds.isEmpty) return [];

      // Fetch profiles
      final profiles = await _supabase
          .from('impact_profiles')
          .select('*')
          .inFilter('user_id', mutualIds);

      return (profiles as List)
          .map((data) => ImpactProfile.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching mutual connections: $e');
      return [];
    }
  }
}
