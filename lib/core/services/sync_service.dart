import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'basera_database.dart';
import 'firebase_backend_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  StreamSubscription? _connectionSubscription;
  bool _isSyncing = false;

  SyncService._init();

  void startListening() {
    _connectionSubscription?.cancel();
    _connectionSubscription = InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.connected) {
        debugPrint('SyncService: Internet connection restored. Triggering sync.');
        syncPendingData();
      }
    });
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final unsynced = await BaseraDatabase.instance.getUnsyncedUrls();
      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('SyncService: Found ${unsynced.length} unsynced URLs. Syncing to Firestore...');
      
      // Ensure Firebase backend is ready and user is signed in
      if (FirebaseBackendService.instance.isFirebaseAvailable && 
          FirebaseBackendService.instance.currentUser != null) {
        
        for (final row in unsynced) {
          final url = row['url'] as String;
          try {
            await FirebaseBackendService.instance.syncUrlVisitDirect(url);
            await BaseraDatabase.instance.markUrlAsSynced(url);
            debugPrint('SyncService: Successfully synced $url');
          } catch (e) {
            debugPrint('SyncService: Failed to sync $url: $e');
            // Keep it unsynced for next retry
          }
        }
      }
    } catch (e) {
      debugPrint('SyncService: Error during synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void stopListening() {
    _connectionSubscription?.cancel();
  }
}
