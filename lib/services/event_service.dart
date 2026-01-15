import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/models.dart';

class EventService {
  /// Get all published public events
  Future<List<Event>> getAllEvents() async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          // Include COMPLETED so Past Events tab can render finished events
          .inFilter('status', ['PUBLISHED', 'ONGOING', 'COMPLETED'])
          .inFilter('visibility', ['PUBLIC'])
          .order('start_date', ascending: true);

      return (data as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get all events error: $e');
      return [];
    }
  }

  /// Get events by category
  Future<List<Event>> getEventsByCategory(EventCategory category) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .eq('category', category.name)
          .order('start_date', ascending: true);

      return (data as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get events by category error: $e');
      return [];
    }
  }

  /// Get events by mode
  Future<List<Event>> getEventsByMode(EventMode mode) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .eq('mode', mode.name)
          .order('start_date', ascending: true);

      return (data as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get events by mode error: $e');
      return [];
    }
  }

  /// Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .eq('id', eventId)
          .maybeSingle();

      if (data == null) return null;
      return Event.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get event by ID error: $e');
      return null;
    }
  }

  /// Get ticket tiers for an event
  Future<List<TicketTier>> getTicketTiers(String eventId) async {
    try {
      final data = await SupabaseConfig.client
          .from('ticket_tiers')
          .select()
          .eq('event_id', eventId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (data as List).map((json) => TicketTier.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get ticket tiers error: $e');
      return [];
    }
  }

  /// Get ticket tiers for multiple events in a single query
  /// Returns a map of eventId -> list of active tiers (sorted by sort_order)
  Future<Map<String, List<TicketTier>>> getTicketTiersForEvents(List<String> eventIds) async {
    if (eventIds.isEmpty) return {};
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
      return map;
    } catch (e) {
      debugPrint('❌ Get ticket tiers for events error: $e');
      return {};
    }
  }

  /// Search events by name
  Future<List<Event>> searchEvents(String query) async {
    try {
      final data = await SupabaseConfig.client
          .from('events')
          .select('*, organization:organizations(*)')
          .inFilter('status', ['PUBLISHED'])
          .inFilter('visibility', ['PUBLIC'])
          .ilike('name', '%$query%')
          .order('start_date', ascending: true);

      return (data as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Search events error: $e');
      return [];
    }
  }

  /// Get upcoming events
  Future<List<Event>> getUpcomingEvents() async {
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

      return (data as List).map((json) => Event.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Get upcoming events error: $e');
      return [];
    }
  }

  /// Create a new event
  Future<Event?> createEvent(Event event) async {
    try {
      final json = event.toJson();
      json.remove('organization'); // Remove nested object
      
      final data = await SupabaseConfig.client
          .from('events')
          .insert(json)
          .select('*, organization:organizations(*)')
          .single();

      return Event.fromJson(data);
    } catch (e) {
      debugPrint('❌ Create event error: $e');
      return null;
    }
  }

  /// Update an event
  Future<bool> updateEvent(Event event) async {
    try {
      final json = event.toJson();
      json.remove('organization'); // Remove nested object
      
      await SupabaseConfig.client
          .from('events')
          .update(json)
          .eq('id', event.id);

      return true;
    } catch (e) {
      debugPrint('❌ Update event error: $e');
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await SupabaseConfig.client.from('events').delete().eq('id', eventId);
      return true;
    } catch (e) {
      debugPrint('❌ Delete event error: $e');
      return false;
    }
  }

}
