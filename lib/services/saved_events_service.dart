import 'package:flutter/foundation.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';
import 'package:thittam1hub/models/saved_event.dart';
import 'package:thittam1hub/services/cache_service.dart';
import 'package:thittam1hub/services/connectivity_service.dart';
import 'package:thittam1hub/services/offline_action_queue.dart';

/// Service for managing saved/bookmarked events with optimistic updates
class SavedEventsService {
  final _supabase = SupabaseConfig.client;
  final CacheService _cache = CacheService.instance;
  final OfflineActionQueue _queue = OfflineActionQueue.instance;

  // Local optimistic state for instant UI updates
  final Set<String> _optimisticSavedEvents = {};
  final Set<String> _optimisticUnsavedEvents = {};

  /// Check if event is optimistically saved (for instant UI)
  bool isOptimisticallySaved(String eventId) {
    if (_optimisticUnsavedEvents.contains(eventId)) return false;
    if (_optimisticSavedEvents.contains(eventId)) return true;
    return false;
  }

  /// Get all saved events for the current user with cache-first strategy
  Future<List<SavedEvent>> getSavedEvents({bool forceRefresh = false}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Try cache first (unless forced refresh)
      if (!forceRefresh) {
        final cached = await _cache.getCachedSavedEvents(userId);
        if (cached != null) {
          debugPrint('📦 Saved events loaded from cache: ${cached.length} items');
          return cached;
        }
      }

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

      final savedEvents = (response as List)
          .map((data) => SavedEvent.fromMap(data as Map<String, dynamic>))
          .toList();
      
      // Cache the results
      await _cache.cacheSavedEvents(savedEvents, userId);
      
      // Clear optimistic state since we have fresh data
      _optimisticSavedEvents.clear();
      _optimisticUnsavedEvents.clear();
      
      return savedEvents;
    } catch (e) {
      debugPrint('❌ Get saved events error: $e');
      
      // On network error, return stale cache if available
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final staleCache = await _cache.getCachedSavedEventsStale(userId);
        if (staleCache != null) {
          debugPrint('📦 Returning stale cached saved events due to network error');
          return staleCache;
        }
      }
      
      return [];
    }
  }

  /// Save an event with optimistic update
  /// Returns immediately, queues for sync if offline
  Future<bool> saveEvent(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Optimistic update - instant UI feedback
    _optimisticSavedEvents.add(eventId);
    _optimisticUnsavedEvents.remove(eventId);
    debugPrint('⚡ Optimistic save: $eventId');

    // If offline, queue for later
    if (!ConnectivityService.instance.isOnline) {
      await _queue.enqueue(OfflineAction(
        id: 'save_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.saveEvent,
        payload: {'eventId': eventId},
        createdAt: DateTime.now(),
      ));
      debugPrint('📥 Save event queued for offline sync');
      return true;
    }

    // Online - sync immediately
    try {
      await _supabase.from('saved_events').insert({
        'user_id': userId,
        'event_id': eventId,
      });
      
      // Invalidate cache
      await _cache.invalidateCache('${CacheService.savedEventsKey}_$userId');
      
      debugPrint('✅ Event saved: $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ Save event error: $e');
      
      // Revert optimistic update on failure
      _optimisticSavedEvents.remove(eventId);
      
      // Queue for retry
      await _queue.enqueue(OfflineAction(
        id: 'save_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.saveEvent,
        payload: {'eventId': eventId},
        createdAt: DateTime.now(),
      ));
      
      return false;
    }
  }

  /// Unsave an event with optimistic update
  Future<bool> unsaveEvent(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // Optimistic update - instant UI feedback
    _optimisticUnsavedEvents.add(eventId);
    _optimisticSavedEvents.remove(eventId);
    debugPrint('⚡ Optimistic unsave: $eventId');

    // If offline, queue for later
    if (!ConnectivityService.instance.isOnline) {
      await _queue.enqueue(OfflineAction(
        id: 'unsave_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.unsaveEvent,
        payload: {'eventId': eventId},
        createdAt: DateTime.now(),
      ));
      debugPrint('📥 Unsave event queued for offline sync');
      return true;
    }

    // Online - sync immediately
    try {
      await _supabase
          .from('saved_events')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
      
      // Invalidate cache
      await _cache.invalidateCache('${CacheService.savedEventsKey}_$userId');
      
      debugPrint('✅ Event unsaved: $eventId');
      return true;
    } catch (e) {
      debugPrint('❌ Unsave event error: $e');
      
      // Revert optimistic update on failure
      _optimisticUnsavedEvents.remove(eventId);
      
      // Queue for retry
      await _queue.enqueue(OfflineAction(
        id: 'unsave_${eventId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.unsaveEvent,
        payload: {'eventId': eventId},
        createdAt: DateTime.now(),
      ));
      
      return false;
    }
  }

  /// Check if an event is saved (includes optimistic state)
  Future<bool> isEventSaved(String eventId) async {
    // Check optimistic state first for instant response
    if (_optimisticUnsavedEvents.contains(eventId)) return false;
    if (_optimisticSavedEvents.contains(eventId)) return true;

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

  /// Toggle reminder with optimistic update
  Future<bool> toggleReminder(String savedEventId, bool enabled) async {
    // If offline, queue for later
    if (!ConnectivityService.instance.isOnline) {
      await _queue.enqueue(OfflineAction(
        id: 'reminder_${savedEventId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.toggleReminder,
        payload: {'savedEventId': savedEventId, 'enabled': enabled},
        createdAt: DateTime.now(),
      ));
      debugPrint('📥 Toggle reminder queued for offline sync');
      return true;
    }

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
