import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:thittam1hub/services/connectivity_service.dart';
import 'package:thittam1hub/supabase/supabase_config.dart';

/// Types of actions that can be queued for offline sync
enum OfflineActionType {
  saveEvent,
  unsaveEvent,
  sparkPost,
  toggleReminder,
  addComment,
}

/// Represents a single action queued for sync
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'] as String,
    type: OfflineActionType.values.firstWhere((e) => e.name == json['type']),
    payload: json['payload'] as Map<String, dynamic>,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );
}

/// Service for managing offline action queue
/// Queues actions when offline and syncs when back online
class OfflineActionQueue {
  static final OfflineActionQueue instance = OfflineActionQueue._();
  OfflineActionQueue._();

  static const String _queueBoxName = 'offline_action_queue';
  static const int _maxRetries = 3;

  Box<String>? _queueBox;
  bool _initialized = false;
  bool _isSyncing = false;

  // Listeners for UI updates
  final List<VoidCallback> _onQueueChangedListeners = [];

  /// Number of pending actions
  int get pendingCount => _queueBox?.length ?? 0;

  /// Whether there are pending actions
  bool get hasPendingActions => pendingCount > 0;

  /// Initialize the queue
  Future<void> init() async {
    if (_initialized) return;

    try {
      _queueBox = await Hive.openBox<String>(_queueBoxName);
      _initialized = true;
      
      // Listen for reconnection to sync
      ConnectivityService.instance.addOnReconnectListener(_syncQueue);
      
      debugPrint('✅ OfflineActionQueue initialized (${pendingCount} pending)');
      
      // Try to sync any pending actions on init
      if (ConnectivityService.instance.isOnline && hasPendingActions) {
        _syncQueue();
      }
    } catch (e) {
      debugPrint('❌ OfflineActionQueue init error: $e');
    }
  }

  /// Add listener for queue changes
  void addOnQueueChangedListener(VoidCallback callback) {
    _onQueueChangedListeners.add(callback);
  }

  /// Remove queue change listener
  void removeOnQueueChangedListener(VoidCallback callback) {
    _onQueueChangedListeners.remove(callback);
  }

  void _notifyListeners() {
    for (final listener in List.from(_onQueueChangedListeners)) {
      try {
        listener();
      } catch (e) {
        debugPrint('❌ Queue listener error: $e');
      }
    }
  }

  /// Queue an action for offline sync
  Future<void> enqueue(OfflineAction action) async {
    if (_queueBox == null) return;

    try {
      await _queueBox!.put(action.id, jsonEncode(action.toJson()));
      debugPrint('📥 Action queued: ${action.type.name} (${action.id})');
      _notifyListeners();
      
      // Try to sync immediately if online
      if (ConnectivityService.instance.isOnline && !_isSyncing) {
        _syncQueue();
      }
    } catch (e) {
      debugPrint('❌ Enqueue action error: $e');
    }
  }

  /// Remove an action from queue (after successful sync or cancellation)
  Future<void> dequeue(String actionId) async {
    if (_queueBox == null) return;

    try {
      await _queueBox!.delete(actionId);
      debugPrint('📤 Action dequeued: $actionId');
      _notifyListeners();
    } catch (e) {
      debugPrint('❌ Dequeue action error: $e');
    }
  }

  /// Cancel a pending action (for undo functionality)
  Future<bool> cancelAction(String actionId) async {
    if (_queueBox == null) return false;
    
    if (_queueBox!.containsKey(actionId)) {
      await dequeue(actionId);
      debugPrint('🚫 Action cancelled: $actionId');
      return true;
    }
    return false;
  }

  /// Get all pending actions
  List<OfflineAction> getPendingActions() {
    if (_queueBox == null) return [];

    try {
      return _queueBox!.values.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return OfflineAction.fromJson(data);
      }).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      debugPrint('❌ Get pending actions error: $e');
      return [];
    }
  }

  /// Sync all queued actions to server
  Future<void> _syncQueue() async {
    if (_isSyncing || !ConnectivityService.instance.isOnline) return;
    if (_queueBox == null || _queueBox!.isEmpty) return;

    _isSyncing = true;
    debugPrint('🔄 Syncing ${pendingCount} offline actions...');

    final actions = getPendingActions();
    int successCount = 0;
    int failCount = 0;

    for (final action in actions) {
      try {
        final success = await _executeAction(action);
        
        if (success) {
          await dequeue(action.id);
          successCount++;
        } else {
          action.retryCount++;
          
          if (action.retryCount >= _maxRetries) {
            debugPrint('⚠️ Action exceeded max retries, removing: ${action.id}');
            await dequeue(action.id);
            failCount++;
          } else {
            // Update retry count
            await _queueBox!.put(action.id, jsonEncode(action.toJson()));
          }
        }
      } catch (e) {
        debugPrint('❌ Sync action error: $e');
        action.retryCount++;
        
        if (action.retryCount >= _maxRetries) {
          await dequeue(action.id);
          failCount++;
        } else {
          await _queueBox!.put(action.id, jsonEncode(action.toJson()));
        }
      }
    }

    _isSyncing = false;
    debugPrint('✅ Sync complete: $successCount success, $failCount failed');
  }

  /// Execute a single action against the server
  Future<bool> _executeAction(OfflineAction action) async {
    final supabase = SupabaseConfig.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    switch (action.type) {
      case OfflineActionType.saveEvent:
        await supabase.from('saved_events').insert({
          'user_id': userId,
          'event_id': action.payload['eventId'],
        });
        return true;

      case OfflineActionType.unsaveEvent:
        await supabase
            .from('saved_events')
            .delete()
            .eq('user_id', userId)
            .eq('event_id', action.payload['eventId']);
        return true;

      case OfflineActionType.sparkPost:
        // Check if already sparked
        final existing = await supabase
            .from('spark_reactions')
            .select('id')
            .eq('post_id', action.payload['postId'])
            .eq('user_id', userId)
            .eq('type', 'SPARK')
            .maybeSingle();

        if (existing == null) {
          await supabase.from('spark_reactions').insert({
            'post_id': action.payload['postId'],
            'user_id': userId,
            'type': 'SPARK',
          });
          await supabase.rpc('increment_spark_count', 
            params: {'post_id': action.payload['postId']});
        }
        return true;

      case OfflineActionType.toggleReminder:
        await supabase
            .from('saved_events')
            .update({'reminder_enabled': action.payload['enabled']})
            .eq('id', action.payload['savedEventId']);
        return true;

      case OfflineActionType.addComment:
        await supabase.from('spark_comments').insert({
          'post_id': action.payload['postId'],
          'user_id': userId,
          'parent_id': action.payload['parentId'],
          'content': action.payload['content'],
          'author_name': action.payload['authorName'],
          'author_avatar': action.payload['authorAvatar'],
        });
        return true;
    }
  }

  /// Force sync now (for manual retry)
  Future<void> forceSyncNow() async {
    if (ConnectivityService.instance.isOnline) {
      await _syncQueue();
    }
  }

  /// Clear all pending actions
  Future<void> clearAll() async {
    await _queueBox?.clear();
    _notifyListeners();
    debugPrint('🗑️ Offline action queue cleared');
  }

  void dispose() {
    ConnectivityService.instance.removeOnReconnectListener(_syncQueue);
    _onQueueChangedListeners.clear();
  }
}
