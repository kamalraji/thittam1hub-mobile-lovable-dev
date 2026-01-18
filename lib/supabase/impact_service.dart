import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/models/connection_request_item.dart';
import 'package:thittam1hub/models/match_insight.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImpactService {
  final _supabase = SupabaseConfig.client;

  /// Get current user's impact profile (creates one if doesn't exist)
  Future<ImpactProfile?> getMyImpactProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('impact_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Auto-create a profile for the user
        return await _createDefaultImpactProfile(userId);
      }
      return ImpactProfile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching my impact profile: $e');
      return null;
    }
  }

  /// Create a default impact profile for new users
  Future<ImpactProfile?> _createDefaultImpactProfile(String userId) async {
    try {
      // Get user metadata from auth
      final user = _supabase.auth.currentUser;
      final fullName = user?.userMetadata?['full_name'] as String? ?? 
                       user?.email?.split('@').first ?? 
                       'New User';
      final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

      final profileData = {
        'user_id': userId,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'headline': 'Just joined! 👋',
        'bio': null,
        'organization': null,
        'looking_for': <String>[],
        'interests': <String>[],
        'skills': <String>[],
        'relationship_status': 'OPEN_TO_CONNECT',
        'education_status': 'PROFESSIONAL',
        'impact_score': 0,
        'level': 1,
        'badges': <String>[],
        'vibe_emoji': '🚀',
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
        'streak_count': 0,
        'streak_actions_today': 0,
        'is_premium': false,
        'is_verified': false,
        'is_boosted': false,
        'super_like_count': 0,
      };

      final response = await _supabase
          .from('impact_profiles')
          .insert(profileData)
          .select()
          .single();

      debugPrint('✅ Created default impact profile for user');
      return ImpactProfile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error creating default impact profile: $e');
      return null;
    }
  }

  /// Compute a match score (0-100) between two profiles based on
  /// skills/interests overlap and looking-for complementarity.
  /// Weights: skills 50%, interests 30%, looking-for complementarity 20%.
  int calculateMatchScore(ImpactProfile me, ImpactProfile other) {
    final result = calculateMatchInsights(me, other);
    return result.totalScore;
  }
  
  /// Calculate detailed match insights explaining WHY two profiles match
  /// Returns a MatchResult with breakdown of all match categories
  MatchResult calculateMatchInsights(ImpactProfile me, ImpactProfile other) {
    final insights = <MatchInsight>[];
    
    final meSkills = me.skills.toSet();
    final otherSkills = other.skills.toSet();
    final meInterests = me.interests.toSet();
    final otherInterests = other.interests.toSet();
    final meLF = me.lookingFor.toSet();
    final otherLF = other.lookingFor.toSet();

    // 1. SKILLS MATCH (Professional - like LinkedIn)
    final sharedSkills = meSkills.intersection(otherSkills);
    if (sharedSkills.isNotEmpty) {
      final contribution = (sharedSkills.length * 12).clamp(0, 40);
      insights.add(MatchInsight(
        category: MatchCategory.skills,
        title: 'Shared Expertise',
        description: 'You both have ${sharedSkills.length} skill${sharedSkills.length > 1 ? 's' : ''} in common',
        items: sharedSkills.toList(),
        contribution: contribution,
        icon: Icons.code_rounded,
        color: Colors.blue,
        emoji: '💻',
      ));
    }
    
    // 2. INTERESTS MATCH (Social - like Instagram)
    final sharedInterests = meInterests.intersection(otherInterests);
    if (sharedInterests.isNotEmpty) {
      final contribution = (sharedInterests.length * 10).clamp(0, 30);
      insights.add(MatchInsight(
        category: MatchCategory.interests,
        title: 'Common Passions',
        description: 'You share ${sharedInterests.length} interest${sharedInterests.length > 1 ? 's' : ''}',
        items: sharedInterests.toList(),
        contribution: contribution,
        icon: Icons.favorite_rounded,
        color: Colors.pink,
        emoji: '💕',
      ));
    }
    
    // 3. GOAL COMPLEMENTARITY (You offer what they seek)
    final iCanHelp = meSkills.intersection(otherLF);
    final theyCanHelp = otherSkills.intersection(meLF);
    if (iCanHelp.isNotEmpty || theyCanHelp.isNotEmpty) {
      final allComplementary = {...iCanHelp, ...theyCanHelp};
      String description;
      if (iCanHelp.isNotEmpty && theyCanHelp.isNotEmpty) {
        description = 'You can help with ${iCanHelp.first}, they can help with ${theyCanHelp.first}';
      } else if (iCanHelp.isNotEmpty) {
        description = 'You can help them with ${iCanHelp.join(", ")}';
      } else {
        description = 'They can help you with ${theyCanHelp.join(", ")}';
      }
      
      insights.add(MatchInsight(
        category: MatchCategory.goals,
        title: 'Perfect Fit',
        description: description,
        items: allComplementary.toList(),
        contribution: 25,
        icon: Icons.handshake_rounded,
        color: Colors.teal,
        isComplementary: true,
        emoji: '🎯',
      ));
    }
    
    // 4. SAME EVENT/ACTIVITY
    if (me.currentEventId != null && 
        other.currentEventId != null && 
        me.currentEventId == other.currentEventId) {
      insights.add(MatchInsight(
        category: MatchCategory.activity,
        title: 'Same Event',
        description: 'You\'re both attending this event',
        items: [],
        contribution: 15,
        icon: Icons.event_rounded,
        color: Colors.purple,
        emoji: '📍',
      ));
    }
    
    // 5. ORGANIZATION MATCH
    if (me.organization != null && 
        other.organization != null &&
        me.organization!.toLowerCase() == other.organization!.toLowerCase()) {
      insights.add(MatchInsight(
        category: MatchCategory.organization,
        title: 'Same Organization',
        description: 'You\'re both from ${me.organization}',
        items: [me.organization!],
        contribution: 12,
        icon: Icons.business_rounded,
        color: Colors.blueGrey,
        emoji: '🏢',
      ));
    }
    
    // 6. EDUCATION MATCH
    if (me.educationStatus == other.educationStatus && 
        me.educationStatus != 'PROFESSIONAL') {
      final eduLabel = _getEducationLabel(me.educationStatus);
      insights.add(MatchInsight(
        category: MatchCategory.education,
        title: 'Academic Match',
        description: 'You\'re both $eduLabel',
        items: [eduLabel],
        contribution: 8,
        icon: Icons.school_rounded,
        color: Colors.green,
        emoji: '🎓',
      ));
    }
    
    // Calculate total score
    final totalScore = insights
        .fold<int>(0, (sum, i) => sum + i.contribution)
        .clamp(0, 100);
    
    // Sort by contribution
    insights.sort((a, b) => b.contribution.compareTo(a.contribution));
    
    // Determine summary
    final summaryEmoji = _getScoreEmoji(totalScore);
    final summaryText = _getSummaryText(insights);
    final primaryCategory = insights.isNotEmpty ? insights.first.category : null;
    final matchStory = _generateMatchStory(me, other, insights, totalScore);
    
    return MatchResult(
      totalScore: totalScore,
      insights: insights,
      summaryEmoji: summaryEmoji,
      summaryText: summaryText,
      primaryCategory: primaryCategory,
      matchStory: matchStory,
    );
  }
  
  String _getScoreEmoji(int score) {
    if (score >= 85) return '🔥';
    if (score >= 70) return '⭐';
    if (score >= 50) return '✨';
    if (score >= 30) return '👍';
    return '👋';
  }
  
  String _getSummaryText(List<MatchInsight> insights) {
    if (insights.isEmpty) return 'New potential connection';
    
    final categories = insights.map((i) => i.category).toSet();
    
    if (categories.contains(MatchCategory.goals)) {
      return 'You can help each other grow';
    }
    if (categories.contains(MatchCategory.skills) && 
        categories.contains(MatchCategory.interests)) {
      return 'Strong professional & social match';
    }
    if (categories.contains(MatchCategory.skills)) {
      return 'Professional expertise alignment';
    }
    if (categories.contains(MatchCategory.interests)) {
      return 'You share common passions';
    }
    if (categories.contains(MatchCategory.activity)) {
      return 'You\'re at the same event!';
    }
    if (categories.contains(MatchCategory.organization)) {
      return 'Colleagues in the same org';
    }
    if (categories.contains(MatchCategory.education)) {
      return 'Same academic journey';
    }
    
    return 'Potential connection';
  }
  
  String? _generateMatchStory(
    ImpactProfile me, 
    ImpactProfile other, 
    List<MatchInsight> insights, 
    int score,
  ) {
    if (insights.isEmpty) return null;
    
    final parts = <String>[];
    parts.add('You and ${other.fullName} are a **$score% match**!');
    
    // Add skill story
    final skillInsight = insights.where((i) => i.category == MatchCategory.skills).firstOrNull;
    if (skillInsight != null && skillInsight.items.isNotEmpty) {
      if (skillInsight.items.length == 1) {
        parts.add('You both know ${skillInsight.items.first}.');
      } else {
        parts.add('You share expertise in ${skillInsight.items.take(2).join(" and ")}.');
      }
    }
    
    // Add goal story
    final goalInsight = insights.where((i) => i.category == MatchCategory.goals).firstOrNull;
    if (goalInsight != null) {
      parts.add(goalInsight.description + '.');
    }
    
    // Add interest story
    final interestInsight = insights.where((i) => i.category == MatchCategory.interests).firstOrNull;
    if (interestInsight != null && interestInsight.items.isNotEmpty) {
      parts.add('You\'re both into ${interestInsight.items.first}.');
    }
    
    return parts.join(' ');
  }
  
  String _getEducationLabel(String status) {
    switch (status) {
      case 'UNDERGRADUATE': return 'undergrad students';
      case 'GRADUATE': return 'grad students';
      case 'PHD': return 'PhD candidates';
      case 'HIGH_SCHOOL': return 'high school students';
      default: return 'students';
    }
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

  /// Get a profile by ID (alias for getImpactProfileByUserId)
  Future<ImpactProfile?> getProfileById(String userId) async {
    return getImpactProfileByUserId(userId);
  }

  /// Get connection status between current user and target user
  Future<String?> getConnectionStatus(String targetUserId) async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) return null;

      // Check if there's a connection record in either direction
      final response = await _supabase
          .from('connections')
          .select('status')
          .or('and(requester_id.eq.$myId,receiver_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,receiver_id.eq.$myId)')
          .maybeSingle();

      return response?['status'] as String?;
    } catch (e) {
      debugPrint('Error fetching connection status: $e');
      return null;
    }
  }
}
