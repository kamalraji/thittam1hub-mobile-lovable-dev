import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thittam1hub/models/zone_models.dart';

/// Service for Zone tab - Event day activities
class ZoneService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Get events happening today that the user is registered for
  Future<List<ZoneEvent>> getTodayEvents() async {
    if (_userId == null) return [];

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get events the user is registered for that are happening today
      final response = await _client
          .from('events')
          .select('id, name, description, start_date, end_date, branding')
          .gte('end_date', startOfDay.toIso8601String())
          .lte('start_date', endOfDay.toIso8601String())
          .eq('status', 'PUBLISHED')
          .order('start_date');

      final events = <ZoneEvent>[];
      for (final json in response as List) {
        // Check if user is checked in
        final checkinResponse = await _client
            .from('event_checkins')
            .select('id')
            .eq('event_id', json['id'])
            .eq('user_id', _userId!)
            .isFilter('checkout_time', null)
            .maybeSingle();

        final isCheckedIn = checkinResponse != null;
        
        events.add(ZoneEvent(
          id: json['id'] as String,
          name: json['name'] as String,
          description: json['description'] as String?,
          startDate: DateTime.parse(json['start_date'] as String),
          endDate: DateTime.parse(json['end_date'] as String),
          isCheckedIn: isCheckedIn,
        ));
      }

      return events;
    } catch (e) {
      debugPrint('Error getting today events: $e');
      return [];
    }
  }

  /// Get current active event (user is checked in)
  Future<ZoneEvent?> getCurrentEvent() async {
    if (_userId == null) return null;

    try {
      // Find active check-in
      final checkinResponse = await _client
          .from('event_checkins')
          .select('event_id, events(id, name, description, start_date, end_date)')
          .eq('user_id', _userId!)
          .isFilter('checkout_time', null)
          .order('checkin_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (checkinResponse == null) return null;

      final eventData = checkinResponse['events'] as Map<String, dynamic>?;
      if (eventData == null) return null;

      return ZoneEvent.fromJson(eventData, isCheckedIn: true);
    } catch (e) {
      debugPrint('Error getting current event: $e');
      return null;
    }
  }

  /// Check in to an event
  Future<bool> checkIn(String eventId, {String? location}) async {
    if (_userId == null) return false;

    try {
      await _client.from('event_checkins').insert({
        'user_id': _userId,
        'event_id': eventId,
        'checkin_time': DateTime.now().toIso8601String(),
        'location': location,
      });
      return true;
    } catch (e) {
      debugPrint('Error checking in: $e');
      return false;
    }
  }

  /// Check out from an event
  Future<bool> checkOut(String eventId) async {
    if (_userId == null) return false;

    try {
      await _client
          .from('event_checkins')
          .update({'checkout_time': DateTime.now().toIso8601String()})
          .eq('event_id', eventId)
          .eq('user_id', _userId!)
          .isFilter('checkout_time', null);
      return true;
    } catch (e) {
      debugPrint('Error checking out: $e');
      return false;
    }
  }

  /// Get live sessions for an event
  Future<List<EventSession>> getLiveSessions(String eventId) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('event_sessions')
          .select()
          .eq('event_id', eventId)
          .lte('start_time', now.toIso8601String())
          .gte('end_time', now.toIso8601String())
          .order('start_time');

      return (response as List)
          .map((json) => EventSession.fromJson(json as Map<String, dynamic>)
            ..copyWith(status: 'live'))
          .toList();
    } catch (e) {
      debugPrint('Error getting live sessions: $e');
      return [];
    }
  }

  /// Get upcoming sessions for an event
  Future<List<EventSession>> getUpcomingSessions(String eventId, {int limit = 5}) async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('event_sessions')
          .select()
          .eq('event_id', eventId)
          .gt('start_time', now.toIso8601String())
          .order('start_time')
          .limit(limit);

      return (response as List)
          .map((json) => EventSession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting upcoming sessions: $e');
      return [];
    }
  }

  /// Get nearby attendees at the same event
  Future<List<AttendeeRadar>> getNearbyAttendees(String eventId, {int limit = 12}) async {
    if (_userId == null) return [];

    try {
      // Get other users checked in to the same event
      final response = await _client
          .from('event_checkins')
          .select('user_id, impact_profiles(id, user_id, full_name, avatar_url, headline, is_online)')
          .eq('event_id', eventId)
          .neq('user_id', _userId!)
          .isFilter('checkout_time', null)
          .limit(limit);

      final attendees = <AttendeeRadar>[];
      for (final json in response as List) {
        final profile = json['impact_profiles'] as Map<String, dynamic>?;
        if (profile == null) continue;

        attendees.add(AttendeeRadar(
          id: profile['id'] as String,
          userId: profile['user_id'] as String,
          fullName: profile['full_name'] as String,
          avatarUrl: profile['avatar_url'] as String?,
          headline: profile['headline'] as String?,
          isOnline: profile['is_online'] as bool? ?? false,
        ));
      }

      return attendees;
    } catch (e) {
      debugPrint('Error getting nearby attendees: $e');
      return [];
    }
  }

  /// Get active polls for an event
  Future<List<EventPoll>> getActivePolls(String eventId) async {
    try {
      final response = await _client
          .from('event_polls')
          .select('*, event_poll_options(*)')
          .eq('event_id', eventId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final polls = <EventPoll>[];
      for (final json in response as List) {
        final options = (json['event_poll_options'] as List<dynamic>?)
            ?.map((o) => PollOption(
                  id: o['id'] as String,
                  text: o['text'] as String,
                  voteCount: o['vote_count'] as int? ?? 0,
                ))
            .toList() ?? [];

        // Check if user has voted
        String? userVote;
        if (_userId != null) {
          final voteResponse = await _client
              .from('event_poll_votes')
              .select('option_id')
              .eq('poll_id', json['id'])
              .eq('user_id', _userId!)
              .maybeSingle();
          userVote = voteResponse?['option_id'] as String?;
        }

        polls.add(EventPoll(
          id: json['id'] as String,
          eventId: json['event_id'] as String,
          question: json['question'] as String,
          options: options,
          createdAt: DateTime.parse(json['created_at'] as String),
          expiresAt: json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : null,
          isActive: json['is_active'] as bool? ?? true,
          totalVotes: options.fold(0, (sum, o) => sum + o.voteCount),
          userVote: userVote,
        ));
      }

      return polls;
    } catch (e) {
      debugPrint('Error getting active polls: $e');
      return [];
    }
  }

  /// Submit a vote for a poll
  Future<bool> submitPollVote(String pollId, String optionId) async {
    if (_userId == null) return false;

    try {
      await _client.from('event_poll_votes').upsert({
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': _userId,
        'voted_at': DateTime.now().toIso8601String(),
      }, onConflict: 'poll_id,user_id');

      // Increment vote count
      await _client.rpc('increment_poll_vote', params: {'option_id': optionId});

      return true;
    } catch (e) {
      debugPrint('Error submitting poll vote: $e');
      return false;
    }
  }

  /// Get announcements for an event
  Future<List<EventAnnouncement>> getAnnouncements(String eventId, {int limit = 10}) async {
    try {
      final response = await _client
          .from('event_announcements')
          .select()
          .eq('event_id', eventId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EventAnnouncement.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting announcements: $e');
      return [];
    }
  }

  /// Get count of attendees at an event
  Future<int> getAttendeeCount(String eventId) async {
    try {
      final response = await _client
          .from('event_checkins')
          .select('id')
          .eq('event_id', eventId)
          .isFilter('checkout_time', null);

      return (response as List).length;
    } catch (e) {
      debugPrint('Error getting attendee count: $e');
      return 0;
    }
  }
}

extension on EventSession {
  EventSession copyWith({String? status}) {
    return EventSession(
      id: id,
      eventId: eventId,
      title: title,
      description: description,
      speakerName: speakerName,
      speakerAvatar: speakerAvatar,
      room: room,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      attendeeCount: attendeeCount,
      streamUrl: streamUrl,
      tags: tags,
    );
  }
}
