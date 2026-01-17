import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/saved_event.dart';

/// Service for managing saved/bookmarked events
class SavedEventsService {
  final _supabase = SupabaseConfig.client;

  /// Get all saved events for the current user
  Future<List<SavedEvent>> getSavedEvents() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('saved_events')
          .select('''
            id,
            event_id,
            reminder_enabled,
            reminder_time,
            notes,
            created_at,
            events!inner(
              id,
              name,
              start_date,
              end_date,
              branding,
              mode
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => SavedEvent.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Get saved events error: $e');
      return [];
    }
  }

  /// Save an event to bookmarks
  Future<bool> saveEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('saved_events').insert({
        'user_id': userId,
        'event_id': eventId,
      });
      
      debugPrint('✅ Event saved: $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ Save event error: $e');
      return false;
    }
  }

  /// Remove an event from bookmarks
  Future<bool> unsaveEvent(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('saved_events')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
      
      debugPrint('✅ Event unsaved: $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ Unsave event error: $e');
      return false;
    }
  }

  /// Check if an event is saved
  Future<bool> isEventSaved(String eventId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('saved_events')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Check saved event error: $e');
      return false;
    }
  }

  /// Toggle reminder for a saved event
  Future<bool> toggleReminder(String savedEventId, bool enabled) async {
    try {
      await _supabase
          .from('saved_events')
          .update({'reminder_enabled': enabled})
          .eq('id', savedEventId);
      
      debugPrint('✅ Reminder toggled: $enabled');
      return true;
    } catch (e) {
      debugPrint('❌ Toggle reminder error: $e');
      return false;
    }
  }

  /// Set reminder time for a saved event
  Future<bool> setReminderTime(String savedEventId, DateTime reminderTime) async {
    try {
      await _supabase
          .from('saved_events')
          .update({
            'reminder_enabled': true,
            'reminder_time': reminderTime.toIso8601String(),
          })
          .eq('id', savedEventId);
      
      debugPrint('✅ Reminder time set: $reminderTime');
      return true;
    } catch (e) {
      debugPrint('❌ Set reminder time error: $e');
      return false;
    }
  }

  /// Update notes for a saved event
  Future<bool> updateNotes(String savedEventId, String notes) async {
    try {
      await _supabase
          .from('saved_events')
          .update({'notes': notes})
          .eq('id', savedEventId);
      
      debugPrint('✅ Notes updated');
      return true;
    } catch (e) {
      debugPrint('❌ Update notes error: $e');
      return false;
    }
  }

  /// Get count of saved events
  Future<int> getSavedEventsCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('saved_events')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Get saved events count error: $e');
      return 0;
    }
  }
}
