import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thittam1hub/models/models.dart';
import 'package:thittam1hub/models/saved_event.dart';

/// Centralized cache service for offline data access
/// Uses SharedPreferences for timestamps and Hive for complex objects
class CacheService {
  static const Duration defaultTTL = Duration(hours: 1);
  static const Duration profileTTL = Duration(hours: 24);
  static const Duration eventsTTL = Duration(minutes: 30);
  static const Duration savedEventsTTL = Duration(hours: 1);

  // Cache keys
  static const String userProfileKey = 'cached_user_profile';
  static const String eventsListKey = 'cached_events';
  static const String savedEventsKey = 'cached_saved_events';
  
  // Hive box names
  static const String _profileBoxName = 'profile_cache';
  static const String _eventsBoxName = 'events_cache';
  static const String _savedEventsBoxName = 'saved_events_cache';
  static const String _timestampsBoxName = 'cache_timestamps';

  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();
  
  CacheService._();

  Box<String>? _profileBox;
  Box<String>? _eventsBox;
  Box<String>? _savedEventsBox;
  Box<int>? _timestampsBox;
  
  bool _initialized = false;

  /// Initialize Hive boxes - must be called before using cache
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      await Hive.initFlutter();
      
      _profileBox = await Hive.openBox<String>(_profileBoxName);
      _eventsBox = await Hive.openBox<String>(_eventsBoxName);
      _savedEventsBox = await Hive.openBox<String>(_savedEventsBoxName);
      _timestampsBox = await Hive.openBox<int>(_timestampsBoxName);
      
      _initialized = true;
      debugPrint('✅ CacheService initialized');
    } catch (e) {
      debugPrint('❌ CacheService init error: $e');
    }
  }

  /// Check if cache is valid (not expired)
  bool isCacheValid(String key, Duration ttl) {
    if (_timestampsBox == null) return false;
    
    final timestamp = _timestampsBox!.get(key);
    if (timestamp == null) return false;
    
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedAt) < ttl;
  }

  /// Update cache timestamp
  Future<void> _updateTimestamp(String key) async {
    await _timestampsBox?.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  // ==========================================
  // USER PROFILE CACHING
  // ==========================================

  /// Cache user profile
  Future<void> cacheUserProfile(UserProfile profile) async {
    if (_profileBox == null) return;
    
    try {
      final json = jsonEncode(profile.toJson());
      await _profileBox!.put('${userProfileKey}_${profile.id}', json);
      await _updateTimestamp('${userProfileKey}_${profile.id}');
      debugPrint('✅ Profile cached: ${profile.id}');
    } catch (e) {
      debugPrint('❌ Cache profile error: $e');
    }
  }

  /// Get cached user profile
  Future<UserProfile?> getCachedUserProfile(String userId) async {
    if (_profileBox == null) return null;
    
    try {
      final key = '${userProfileKey}_$userId';
      if (!isCacheValid(key, profileTTL)) return null;
      
      final json = _profileBox!.get(key);
      if (json == null) return null;
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get cached profile error: $e');
      return null;
    }
  }

  /// Get cached profile even if expired (for offline fallback)
  Future<UserProfile?> getCachedUserProfileStale(String userId) async {
    if (_profileBox == null) return null;
    
    try {
      final json = _profileBox!.get('${userProfileKey}_$userId');
      if (json == null) return null;
      
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('❌ Get stale cached profile error: $e');
      return null;
    }
  }

  // ==========================================
  // EVENTS CACHING
  // ==========================================

  /// Cache events list
  Future<void> cacheEvents(List<Event> events) async {
    if (_eventsBox == null) return;
    
    try {
      final jsonList = events.map((e) => e.toJson()).toList();
      await _eventsBox!.put(eventsListKey, jsonEncode(jsonList));
      await _updateTimestamp(eventsListKey);
      debugPrint('✅ Events cached: ${events.length} items');
    } catch (e) {
      debugPrint('❌ Cache events error: $e');
    }
  }

  /// Get cached events list
  Future<List<Event>?> getCachedEvents() async {
    if (_eventsBox == null) return null;
    
    try {
      if (!isCacheValid(eventsListKey, eventsTTL)) return null;
      
      final json = _eventsBox!.get(eventsListKey);
      if (json == null) return null;
      
      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Get cached events error: $e');
      return null;
    }
  }

  /// Get cached events even if expired (for offline fallback)
  Future<List<Event>?> getCachedEventsStale() async {
    if (_eventsBox == null) return null;
    
    try {
      final json = _eventsBox!.get(eventsListKey);
      if (json == null) return null;
      
      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Get stale cached events error: $e');
      return null;
    }
  }

  // ==========================================
  // SAVED EVENTS CACHING
  // ==========================================

  /// Cache saved events list
  Future<void> cacheSavedEvents(List<SavedEvent> events, String userId) async {
    if (_savedEventsBox == null) return;
    
    try {
      final jsonList = events.map((e) => e.toMap()).toList();
      // Also store event metadata for offline display
      final enrichedList = events.map((e) => {
        'id': e.id,
        'event_id': e.eventId,
        'event_name': e.eventName,
        'event_banner_url': e.eventBannerUrl,
        'event_start_date': e.eventStartDate.toIso8601String(),
        'event_end_date': e.eventEndDate.toIso8601String(),
        'venue': e.venue,
        'reminder_enabled': e.reminderEnabled,
        'reminder_time': e.reminderTime?.toIso8601String(),
        'notes': e.notes,
        'saved_at': e.savedAt.toIso8601String(),
      }).toList();
      
      await _savedEventsBox!.put('${savedEventsKey}_$userId', jsonEncode(enrichedList));
      await _updateTimestamp('${savedEventsKey}_$userId');
      debugPrint('✅ Saved events cached: ${events.length} items');
    } catch (e) {
      debugPrint('❌ Cache saved events error: $e');
    }
  }

  /// Get cached saved events list
  Future<List<SavedEvent>?> getCachedSavedEvents(String userId) async {
    if (_savedEventsBox == null) return null;
    
    try {
      final key = '${savedEventsKey}_$userId';
      if (!isCacheValid(key, savedEventsTTL)) return null;
      
      final json = _savedEventsBox!.get(key);
      if (json == null) return null;
      
      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      return data.map((e) => _savedEventFromCacheJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Get cached saved events error: $e');
      return null;
    }
  }

  /// Get cached saved events even if expired (for offline fallback)
  Future<List<SavedEvent>?> getCachedSavedEventsStale(String userId) async {
    if (_savedEventsBox == null) return null;
    
    try {
      final json = _savedEventsBox!.get('${savedEventsKey}_$userId');
      if (json == null) return null;
      
      final List<dynamic> data = jsonDecode(json) as List<dynamic>;
      return data.map((e) => _savedEventFromCacheJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Get stale cached saved events error: $e');
      return null;
    }
  }

  /// Parse SavedEvent from cached JSON format
  SavedEvent _savedEventFromCacheJson(Map<String, dynamic> json) {
    return SavedEvent(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String? ?? 'Unknown Event',
      eventBannerUrl: json['event_banner_url'] as String?,
      eventStartDate: DateTime.parse(json['event_start_date'] as String),
      eventEndDate: DateTime.parse(json['event_end_date'] as String),
      venue: json['venue'] as String?,
      reminderEnabled: json['reminder_enabled'] as bool? ?? false,
      reminderTime: json['reminder_time'] != null 
          ? DateTime.parse(json['reminder_time'] as String) 
          : null,
      notes: json['notes'] as String?,
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  // ==========================================
  // CACHE MANAGEMENT
  // ==========================================

  /// Invalidate specific cache
  Future<void> invalidateCache(String key) async {
    try {
      await _timestampsBox?.delete(key);
      debugPrint('✅ Cache invalidated: $key');
    } catch (e) {
      debugPrint('❌ Invalidate cache error: $e');
    }
  }

  /// Invalidate user-specific caches (on logout)
  Future<void> invalidateUserCache(String userId) async {
    try {
      await _profileBox?.delete('${userProfileKey}_$userId');
      await _savedEventsBox?.delete('${savedEventsKey}_$userId');
      await _timestampsBox?.delete('${userProfileKey}_$userId');
      await _timestampsBox?.delete('${savedEventsKey}_$userId');
      debugPrint('✅ User cache invalidated: $userId');
    } catch (e) {
      debugPrint('❌ Invalidate user cache error: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    try {
      await _profileBox?.clear();
      await _eventsBox?.clear();
      await _savedEventsBox?.clear();
      await _timestampsBox?.clear();
      debugPrint('✅ All caches cleared');
    } catch (e) {
      debugPrint('❌ Clear all cache error: $e');
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'initialized': _initialized,
      'profileEntries': _profileBox?.length ?? 0,
      'eventsEntries': _eventsBox?.length ?? 0,
      'savedEventsEntries': _savedEventsBox?.length ?? 0,
      'timestampEntries': _timestampsBox?.length ?? 0,
    };
  }
}
