import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/utils/result.dart';

class EventService {
  /// Convert technical errors to user-friendly messages
  String _userFriendlyMessage(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (msg.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('permission') || msg.contains('unauthorized')) {
      return 'You don\'t have permission to view this content.';
    }
    return 'Failed to load events. Please try again.';
  }

  /// Get all published public events
  Future<Result<List<Event>>> getAllEvents() async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          // Include COMPLETED so Past Events tab can render finished events
          .inFilter('status', ['PUBLISHED', 'ONGOING', 'COMPLETED'])
          .inFilter('visibility', ['PUBLIC'])
          .order('start_date', ascending: true);

      final events = (data as List).map((json) => Event.fromJson(json)).toList();
      return Success(events);
    } catch (e) {
      debugPrint('❌ Get all events error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Get events by category
  Future<Result<List<Event>>> getEventsByCategory(EventCategory category) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .eq('category', category.name)
          .order('start_date', ascending: true);

      final events = (data as List).map((json) => Event.fromJson(json)).toList();
      return Success(events);
    } catch (e) {
      debugPrint('❌ Get events by category error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Get events by mode
  Future<Result<List<Event>>> getEventsByMode(EventMode mode) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .eq('mode', mode.name)
          .order('start_date', ascending: true);

      final events = (data as List).map((json) => Event.fromJson(json)).toList();
      return Success(events);
    } catch (e) {
      debugPrint('❌ Get events by mode error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Get event by ID
  Future<Result<Event?>> getEventById(String eventId) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .eq('id', eventId)
          .maybeSingle();

      if (data == null) return const Success(null);
      return Success(Event.fromJson(data));
    } catch (e) {
      debugPrint('❌ Get event by ID error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Get ticket tiers for an event
  Future<Result<List<TicketTier>>> getTicketTiers(String eventId) async {
    try {
      final data = await SupabaseConfig.client
          .from('ticket_tiers')
          .select()
          .eq('event_id', eventId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final tiers = (data as List).map((json) => TicketTier.fromJson(json)).toList();
      return Success(tiers);
    } catch (e) {
      debugPrint('❌ Get ticket tiers error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Get ticket tiers for multiple events in a single query
  /// Returns a map of eventId -> list of active tiers (sorted by sort_order)
  Future<Result<Map<String, List<TicketTier>>>> getTicketTiersForEvents(List<String> eventIds) async {
    if (eventIds.isEmpty) return const Success({});
    try {
      final data = await SupabaseConfig.client
          .from('ticket_tiers')
          .select()
          .inFilter('event_id', eventIds)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final tiers = (data as List).map((j) => TicketTier.fromJson(j as Map<String, dynamic>)).toList();
      final Map<String, List<TicketTier>> map = {};
      for (final t in tiers) {
        map.putIfAbsent(t.eventId, () => []).add(t);
      }
      return Success(map);
    } catch (e) {
      debugPrint('❌ Get ticket tiers for events error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Search events by name
  Future<Result<List<Event>>> searchEvents(String query) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .ilike('name', '%$query%')
          .order('start_date', ascending: true);

      final events = (data as List).map((json) => Event.fromJson(json)).toList();
      return Success(events);
    } catch (e) {
      debugPrint('❌ Search events error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Get upcoming events
  Future<Result<List<Event>>> getUpcomingEvents() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .gte('start_date', now)
          .order('start_date', ascending: true)
          .limit(20);

      final events = (data as List).map((json) => Event.fromJson(json)).toList();
      return Success(events);
    } catch (e) {
      debugPrint('❌ Get upcoming events error: $e');
      return Failure(_userFriendlyMessage(e), e);
    }
  }

  /// Create a new event
  Future<Result<Event>> createEvent(Event event) async {
    try {
      final json = event.toJson();
      json.remove('organization'); // Remove nested object
      
      final data = await SupabaseConfig.client
          .from('events')
          .insert(json)
          .select('*, organization:organizations(*)')
          .single();

      return Success(Event.fromJson(data));
    } catch (e) {
      debugPrint('❌ Create event error: $e');
      return Failure('Failed to create event. Please try again.', e);
    }
  }

  /// Update an event
  Future<Result<bool>> updateEvent(Event event) async {
    try {
      final json = event.toJson();
      json.remove('organization'); // Remove nested object
      
      await SupabaseConfig.client
          .from('events')
          .update(json)
          .eq('id', event.id);

      return const Success(true);
    } catch (e) {
      debugPrint('❌ Update event error: $e');
      return Failure('Failed to update event. Please try again.', e);
    }
  }

  /// Delete an event
  Future<Result<bool>> deleteEvent(String eventId) async {
    try {
      await SupabaseConfig.client.from('events').delete().eq('id', eventId);
      return const Success(true);
    } catch (e) {
      debugPrint('❌ Delete event error: $e');
      return Failure('Failed to delete event. Please try again.', e);
    }
  }
}
