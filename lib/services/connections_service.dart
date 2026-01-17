import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/connection.dart';
import 'package:thittam1hub/models/impact_profile.dart';
import 'package:thittam1hub/supabase/impact_service.dart';

/// Service for managing user connections
class ConnectionsService {
  final _supabase = SupabaseConfig.client;
  final _impactService = ImpactService();

  /// Get accepted connections (mutual connections)
  Future<List<Connection>> getAcceptedConnections() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('connections')
          .select('*')
          .eq('status', 'ACCEPTED')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      final connections = <Connection>[];
      for (final row in (response as List)) {
        final isRequester = row['requester_id'] == userId;
        final otherUserId = isRequester 
            ? row['receiver_id'] as String 
            : row['requester_id'] as String;

        // Fetch the other user's profile
        final profile = await _impactService.getImpactProfileByUserId(otherUserId);
        
        connections.add(Connection(
          id: row['id'] as String,
          otherUserId: otherUserId,
          otherUserName: profile?.fullName ?? 'Unknown',
          otherUserAvatar: profile?.avatarUrl,
          otherUserHeadline: profile?.headline,
          otherUserOrganization: profile?.organization,
          connectionType: row['connection_type'] as String? ?? 'NETWORKING',
          matchScore: row['match_score'] as int? ?? 0,
          connectedAt: DateTime.parse(row['created_at'] as String),
          isOnline: profile?.isOnline ?? false,
          status: 'ACCEPTED',
        ));
      }

      return connections;
    } catch (e) {
      debugPrint('❌ Get accepted connections error: $e');
      return [];
    }
  }

  /// Get pending connection requests (incoming)
  Future<List<Connection>> getIncomingPendingRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('connections')
          .select('*')
          .eq('receiver_id', userId)
          .eq('status', 'PENDING')
          .order('created_at', ascending: false);

      final connections = <Connection>[];
      for (final row in (response as List)) {
        final requesterId = row['requester_id'] as String;
        final profile = await _impactService.getImpactProfileByUserId(requesterId);
        
        connections.add(Connection(
          id: row['id'] as String,
          otherUserId: requesterId,
          otherUserName: profile?.fullName ?? 'Unknown',
          otherUserAvatar: profile?.avatarUrl,
          otherUserHeadline: profile?.headline,
          otherUserOrganization: profile?.organization,
          connectionType: row['connection_type'] as String? ?? 'NETWORKING',
          matchScore: row['match_score'] as int? ?? 0,
          connectedAt: DateTime.parse(row['created_at'] as String),
          isOnline: profile?.isOnline ?? false,
          status: 'PENDING',
        ));
      }

      return connections;
    } catch (e) {
      debugPrint('❌ Get incoming pending requests error: $e');
      return [];
    }
  }

  /// Get outgoing pending requests (sent by current user)
  Future<List<Connection>> getOutgoingPendingRequests() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('connections')
          .select('*')
          .eq('requester_id', userId)
          .eq('status', 'PENDING')
          .order('created_at', ascending: false);

      final connections = <Connection>[];
      for (final row in (response as List)) {
        final receiverId = row['receiver_id'] as String;
        final profile = await _impactService.getImpactProfileByUserId(receiverId);
        
        connections.add(Connection(
          id: row['id'] as String,
          otherUserId: receiverId,
          otherUserName: profile?.fullName ?? 'Unknown',
          otherUserAvatar: profile?.avatarUrl,
          otherUserHeadline: profile?.headline,
          otherUserOrganization: profile?.organization,
          connectionType: row['connection_type'] as String? ?? 'NETWORKING',
          matchScore: row['match_score'] as int? ?? 0,
          connectedAt: DateTime.parse(row['created_at'] as String),
          isOnline: profile?.isOnline ?? false,
          status: 'PENDING',
        ));
      }

      return connections;
    } catch (e) {
      debugPrint('❌ Get outgoing pending requests error: $e');
      return [];
    }
  }

  /// Get suggested connections (profiles not yet connected)
  Future<List<ImpactProfile>> getSuggestedConnections({int limit = 10}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get all existing connection user IDs
      final existingConnections = await _supabase
          .from('connections')
          .select('requester_id, receiver_id')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId');

      final connectedIds = <String>{userId};
      for (final row in (existingConnections as List)) {
        connectedIds.add(row['requester_id'] as String);
        connectedIds.add(row['receiver_id'] as String);
      }

      // Get profiles not in connected IDs
      final profiles = await _impactService.getImpactProfiles();
      
      // Filter out connected profiles and calculate match scores
      final myProfile = await _impactService.getMyImpactProfile();
      final suggestions = profiles
          .where((p) => !connectedIds.contains(p.userId))
          .toList();

      // Sort by match score if we have our profile
      if (myProfile != null) {
        suggestions.sort((a, b) {
          final scoreA = _impactService.calculateMatchScore(myProfile, a);
          final scoreB = _impactService.calculateMatchScore(myProfile, b);
          return scoreB.compareTo(scoreA);
        });
      }

      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Get suggested connections error: $e');
      return [];
    }
  }

  /// Accept a connection request
  Future<bool> acceptRequest(String connectionId) async {
    try {
      await _supabase
          .from('connections')
          .update({
            'status': 'ACCEPTED',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);
      
      debugPrint('✅ Connection accepted');
      return true;
    } catch (e) {
      debugPrint('❌ Accept request error: $e');
      return false;
    }
  }

  /// Decline a connection request
  Future<bool> declineRequest(String connectionId) async {
    try {
      await _supabase
          .from('connections')
          .update({
            'status': 'DECLINED',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId);
      
      debugPrint('✅ Connection declined');
      return true;
    } catch (e) {
      debugPrint('❌ Decline request error: $e');
      return false;
    }
  }

  /// Send a connection request
  Future<bool> sendRequest(String targetUserId, {String connectionType = 'NETWORKING'}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Calculate match score
      final myProfile = await _impactService.getMyImpactProfile();
      final theirProfile = await _impactService.getImpactProfileByUserId(targetUserId);
      int matchScore = 0;
      if (myProfile != null && theirProfile != null) {
        matchScore = _impactService.calculateMatchScore(myProfile, theirProfile);
      }

      await _supabase.from('connections').insert({
        'requester_id': userId,
        'receiver_id': targetUserId,
        'status': 'PENDING',
        'connection_type': connectionType,
        'match_score': matchScore,
      });
      
      debugPrint('✅ Connection request sent');
      return true;
    } catch (e) {
      debugPrint('❌ Send request error: $e');
      return false;
    }
  }

  /// Remove a connection
  Future<bool> removeConnection(String connectionId) async {
    try {
      await _supabase
          .from('connections')
          .delete()
          .eq('id', connectionId);
      
      debugPrint('✅ Connection removed');
      return true;
    } catch (e) {
      debugPrint('❌ Remove connection error: $e');
      return false;
    }
  }
}
