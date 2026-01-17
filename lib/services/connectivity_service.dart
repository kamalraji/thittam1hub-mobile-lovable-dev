import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity and trigger callbacks on reconnect
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _initialized = false;
  
  final List<VoidCallback> _onReconnectListeners = [];

  /// Whether the device is currently online
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // Check initial connectivity state
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      
      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
      
      _initialized = true;
      debugPrint('✅ ConnectivityService initialized (online: $_isOnline)');
    } catch (e) {
      debugPrint('❌ ConnectivityService init error: $e');
      // Assume online if we can't check
      _isOnline = true;
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    
    debugPrint('📶 Connectivity changed: $_isOnline (was offline: $wasOffline)');
    
    // Trigger background sync when coming back online
    if (wasOffline && _isOnline) {
      debugPrint('📶 Back online - triggering background sync');
      _triggerBackgroundSync();
    }
  }

  /// Add a listener that will be called when the device reconnects
  void addOnReconnectListener(VoidCallback callback) {
    _onReconnectListeners.add(callback);
  }

  /// Remove a previously added reconnect listener
  void removeOnReconnectListener(VoidCallback callback) {
    _onReconnectListeners.remove(callback);
  }

  void _triggerBackgroundSync() {
    for (final listener in List.from(_onReconnectListeners)) {
      try {
        listener();
      } catch (e) {
        debugPrint('❌ Reconnect listener error: $e');
      }
    }
  }

  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
    _onReconnectListeners.clear();
    _initialized = false;
  }
}
