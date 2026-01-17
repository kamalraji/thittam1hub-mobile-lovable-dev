import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

/// Sync status for UI feedback
enum SyncStatus {
  idle,
  syncing,
  retrying,
  failed,
}

/// Represents a single action queued for sync
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;
  DateTime? nextRetryAt;
  String? lastError;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAt,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'nextRetryAt': nextRetryAt?.toIso8601String(),
    'lastError': lastError,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'] as String,
    type: OfflineActionType.values.firstWhere((e) => e.name == json['type']),
    payload: json['payload'] as Map<String, dynamic>,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    nextRetryAt: json['nextRetryAt'] != null 
        ? DateTime.parse(json['nextRetryAt'] as String) 
        : null,
    lastError: json['lastError'] as String?,
  );

  /// Check if action is ready to retry
  bool get isReadyToRetry {
    if (nextRetryAt == null) return true;
    return DateTime.now().isAfter(nextRetryAt!);
  }

  /// Time until next retry
  Duration? get timeUntilRetry {
    if (nextRetryAt == null) return null;
    final diff = nextRetryAt!.difference(DateTime.now());
    return diff.isNegative ? null : diff;
  }
}

/// Service for managing offline action queue with exponential backoff
/// Queues actions when offline and syncs when back online
class OfflineActionQueue {
  static final OfflineActionQueue instance = OfflineActionQueue._();
  OfflineActionQueue._();

  static const String _queueBoxName = 'offline_action_queue';
  
  // Retry configuration
  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 2);
  static const Duration _maxDelay = Duration(minutes: 5);
  static const double _jitterFactor = 0.3; // 30% random jitter

  Box<String>? _queueBox;
  bool _initialized = false;
  bool _isSyncing = false;
  Timer? _retryTimer;
  final Random _random = Random();

  // Current sync status
  SyncStatus _syncStatus = SyncStatus.idle;
  SyncStatus get syncStatus => _syncStatus;

  // Listeners for UI updates
  final List<VoidCallback> _onQueueChangedListeners = [];
  final List<void Function(SyncStatus)> _onStatusChangedListeners = [];

  /// Number of pending actions
  int get pendingCount => _queueBox?.length ?? 0;

  /// Whether there are pending actions
  bool get hasPendingActions => pendingCount > 0;

  /// Number of actions ready to retry now
  int get readyToRetryCount {
    return getPendingActions().where((a) => a.isReadyToRetry).length;
  }

  /// Initialize the queue
  Future<void> init() async {
    if (_initialized) return;

    try {
      _queueBox = await Hive.openBox<String>(_queueBoxName);
      _initialized = true;
      
      // Listen for reconnection to sync
      ConnectivityService.instance.addOnReconnectListener(_onReconnect);
      
      debugPrint('✅ OfflineActionQueue initialized (${pendingCount} pending)');
      
      // Try to sync any pending actions on init
      if (ConnectivityService.instance.isOnline && hasPendingActions) {
        _scheduleSync();
      }
    } catch (e) {
      debugPrint('❌ OfflineActionQueue init error: $e');
    }
  }

  void _onReconnect() {
    debugPrint('🌐 Reconnected - scheduling sync');
    _scheduleSync();
  }

  /// Add listener for queue changes
  void addOnQueueChangedListener(VoidCallback callback) {
    _onQueueChangedListeners.add(callback);
  }

  /// Remove queue change listener
  void removeOnQueueChangedListener(VoidCallback callback) {
    _onQueueChangedListeners.remove(callback);
  }

  /// Add listener for sync status changes
  void addOnStatusChangedListener(void Function(SyncStatus) callback) {
    _onStatusChangedListeners.add(callback);
  }

  /// Remove sync status listener
  void removeOnStatusChangedListener(void Function(SyncStatus) callback) {
    _onStatusChangedListeners.remove(callback);
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

  void _updateStatus(SyncStatus status) {
    if (_syncStatus == status) return;
    _syncStatus = status;
    for (final listener in List.from(_onStatusChangedListeners)) {
      try {
        listener(status);
      } catch (e) {
        debugPrint('❌ Status listener error: $e');
      }
    }
  }

  /// Calculate delay with exponential backoff and jitter
  Duration _calculateBackoffDelay(int retryCount) {
    // Exponential backoff: baseDelay * 2^retryCount
    final exponentialMs = _baseDelay.inMilliseconds * pow(2, retryCount);
    
    // Cap at max delay
    final cappedMs = min(exponentialMs.toInt(), _maxDelay.inMilliseconds);
    
    // Add jitter: random value between -jitter% and +jitter%
    final jitterMs = (cappedMs * _jitterFactor * (2 * _random.nextDouble() - 1)).toInt();
    final finalMs = max(cappedMs + jitterMs, _baseDelay.inMilliseconds);
    
    return Duration(milliseconds: finalMs);
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
        _scheduleSync();
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

  /// Schedule sync with intelligent timing
  void _scheduleSync({Duration delay = Duration.zero}) {
    _retryTimer?.cancel();
    
    if (delay == Duration.zero) {
      _syncQueue();
    } else {
      debugPrint('⏰ Scheduling sync in ${delay.inSeconds}s');
      _retryTimer = Timer(delay, _syncQueue);
    }
  }

  /// Sync all queued actions to server with exponential backoff
  Future<void> _syncQueue() async {
    if (_isSyncing || !ConnectivityService.instance.isOnline) return;
    if (_queueBox == null || _queueBox!.isEmpty) {
      _updateStatus(SyncStatus.idle);
      return;
    }

    _isSyncing = true;
    _updateStatus(SyncStatus.syncing);
    debugPrint('🔄 Syncing ${pendingCount} offline actions...');

    final actions = getPendingActions();
    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;
    Duration? nextRetryDelay;

    for (final action in actions) {
      // Skip actions not ready for retry yet
      if (!action.isReadyToRetry) {
        skippedCount++;
        final timeUntil = action.timeUntilRetry;
        if (timeUntil != null && (nextRetryDelay == null || timeUntil < nextRetryDelay)) {
          nextRetryDelay = timeUntil;
        }
        continue;
      }

      try {
        final success = await _executeAction(action);
        
        if (success) {
          await dequeue(action.id);
          successCount++;
          debugPrint('✅ Action synced: ${action.type.name}');
        } else {
          await _handleRetry(action, 'Action returned false');
          failCount++;
        }
      } catch (e) {
        debugPrint('❌ Sync action error: $e');
        await _handleRetry(action, e.toString());
        failCount++;
      }
    }

    _isSyncing = false;
    
    // Determine next status and schedule retry if needed
    if (hasPendingActions) {
      final pendingActions = getPendingActions();
      final hasFailedActions = pendingActions.any((a) => a.retryCount > 0);
      
      if (hasFailedActions) {
        _updateStatus(SyncStatus.retrying);
      }
      
      // Find the soonest retry time
      Duration? soonestRetry;
      for (final action in pendingActions) {
        final timeUntil = action.timeUntilRetry;
        if (timeUntil != null && (soonestRetry == null || timeUntil < soonestRetry)) {
          soonestRetry = timeUntil;
        }
      }
      
      if (soonestRetry != null) {
        _scheduleSync(delay: soonestRetry + const Duration(milliseconds: 100));
      }
    } else {
      _updateStatus(SyncStatus.idle);
    }

    debugPrint('📊 Sync complete: $successCount success, $failCount failed, $skippedCount skipped');
  }

  /// Handle retry logic with exponential backoff
  Future<void> _handleRetry(OfflineAction action, String error) async {
    action.retryCount++;
    action.lastError = error;
    
    if (action.retryCount >= _maxRetries) {
      debugPrint('⚠️ Action exceeded max retries ($action.retryCount/$_maxRetries), removing: ${action.id}');
      await dequeue(action.id);
      _updateStatus(SyncStatus.failed);
      return;
    }
    
    // Calculate next retry time with exponential backoff
    final delay = _calculateBackoffDelay(action.retryCount);
    action.nextRetryAt = DateTime.now().add(delay);
    
    debugPrint('🔁 Retry ${action.retryCount}/$_maxRetries for ${action.type.name} in ${delay.inSeconds}s');
    
    // Update in storage
    await _queueBox!.put(action.id, jsonEncode(action.toJson()));
    _notifyListeners();
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

  /// Force sync now (for manual retry) - ignores backoff timing
  Future<void> forceSyncNow() async {
    if (!ConnectivityService.instance.isOnline) return;
    
    // Reset all retry timers for immediate sync
    final actions = getPendingActions();
    for (final action in actions) {
      action.nextRetryAt = null;
      await _queueBox!.put(action.id, jsonEncode(action.toJson()));
    }
    
    _retryTimer?.cancel();
    await _syncQueue();
  }

  /// Retry a specific failed action immediately
  Future<void> retryAction(String actionId) async {
    if (_queueBox == null || !_queueBox!.containsKey(actionId)) return;
    
    try {
      final json = _queueBox!.get(actionId);
      if (json != null) {
        final action = OfflineAction.fromJson(jsonDecode(json));
        action.nextRetryAt = null; // Clear backoff timer
        await _queueBox!.put(actionId, jsonEncode(action.toJson()));
        _scheduleSync();
      }
    } catch (e) {
      debugPrint('❌ Retry action error: $e');
    }
  }

  /// Clear all pending actions
  Future<void> clearAll() async {
    _retryTimer?.cancel();
    await _queueBox?.clear();
    _updateStatus(SyncStatus.idle);
    _notifyListeners();
    debugPrint('🗑️ Offline action queue cleared');
  }

  void dispose() {
    _retryTimer?.cancel();
    ConnectivityService.instance.removeOnReconnectListener(_onReconnect);
    _onQueueChangedListeners.clear();
    _onStatusChangedListeners.clear();
  }
}
