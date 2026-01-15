import 'dart:async';

import 'package:thittam1hub/models/space.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

class SpaceService {
  final _supabase = SupabaseConfig.client;

  /// Fetches a list of currently live spaces.
  Stream<List<Space>> getLiveSpaces() {
    return _supabase
        .from('spaces')
        .stream(primaryKey: ['id'])
        .map((payload) => payload.map((e) => Space.fromMap(e)).toList());
  }

  /// Creates a new space.
  Future<Space?> createSpace(String topic, List<String> tags) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      final response = await _supabase.from('spaces').insert({
        'topic': topic,
        'created_by': userId,
        'tags': tags,
      }).select();

      final data = response as List;
      if (data.isNotEmpty) {
        return Space.fromMap(data.first as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error creating space: $e');
    }
    return null;
  }

  /// Joins the current user to a space, either as a speaker or audience.
  Future<void> joinSpace(String spaceId, {bool asSpeaker = false}) async {
    final userId = _supabase.auth.currentUser!.id;
    final targetTable = asSpeaker ? 'space_speakers' : 'space_audience';
    final otherTable = asSpeaker ? 'space_audience' : 'space_speakers';

    try {
      // First, remove the user from the other role to prevent duplicates.
      await _supabase.from(otherTable).delete().match({'space_id': spaceId, 'user_id': userId});

      // Now, add the user to their new role.
      await _supabase.from(targetTable).upsert({
        'space_id': spaceId,
        'user_id': userId,
      });
    } catch (e) {
      print('Error joining space: $e');
    }
  }

  /// Leaves a space for the current user.
  Future<void> leaveSpace(String spaceId) async {
    final userId = _supabase.auth.currentUser!.id;
    try {
      // The user can be either a speaker or an audience member, but not both.
      // We can try deleting from both tables in parallel for minor efficiency gain.
      await Future.wait([
        _supabase.from('space_speakers').delete().match({'space_id': spaceId, 'user_id': userId}),
        _supabase.from('space_audience').delete().match({'space_id': spaceId, 'user_id': userId})
      ]);
    } catch (e) {
      print('Error leaving space: $e');
    }
  }

  /// Gets a stream of speakers for a space.
  Stream<List<SpaceSpeaker>> getSpeakersStream(String spaceId) {
    return _supabase
        .from('space_speakers')
        .stream(primaryKey: ['space_id', 'user_id'])
        .eq('space_id', spaceId)
        .map((payload) => payload.map((e) => SpaceSpeaker.fromMap(e)).toList());
  }

  /// Gets a stream of audience members for a space.
  Stream<List<SpaceAudience>> getAudienceStream(String spaceId) {
    return _supabase
        .from('space_audience')
        .stream(primaryKey: ['space_id', 'user_id'])
        .eq('space_id', spaceId)
        .map((payload) => payload.map((e) => SpaceAudience.fromMap(e)).toList());
  }

  /// Mutes a speaker in a space.
  Future<void> muteSpeaker(String spaceId, String userId) async {
    try {
      await _supabase
          .from('space_speakers')
          .update({'is_muted': true})
          .match({'space_id': spaceId, 'user_id': userId});
    } catch (e) {
      print('Error muting speaker: $e');
    }
  }

  /// Unmutes a speaker in a space.
  Future<void> unmuteSpeaker(String spaceId, String userId) async {
    try {
      await _supabase
          .from('space_speakers')
          .update({'is_muted': false})
          .match({'space_id': spaceId, 'user_id': userId});
    } catch (e) {
      print('Error unmuting speaker: $e');
    }
  }
}
