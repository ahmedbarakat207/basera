import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_accessibility_service/accessibility_event.dart';
import 'package:basera/core/services/firebase_backend_service.dart';
import 'package:basera/core/utils/child_history_service.dart';

class AccessibilityMonitoringService {
  static final AccessibilityMonitoringService instance = AccessibilityMonitoringService._internal();
  AccessibilityMonitoringService._internal();

  StreamSubscription<AccessibilityEvent>? _subscription;
  String _lastUrl = '';

  Future<void> initialize() async {
    if (!kIsWeb) {
      final isGranted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
      if (isGranted) {
        startMonitoring();
      }
    }
  }

  Future<bool> requestPermission() async {
    final isGranted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (!isGranted) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
      return await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    }
    return true;
  }

  void startMonitoring() {
    if (_subscription != null) return;

    _subscription = FlutterAccessibilityService.accessStream.listen((event) async {
      // Check if user is currently logged in as a child
      final role = await ChildHistoryService.instance.getUserRole();
      if (role != 'child') return;

      if (event.packageName == 'com.android.chrome' || 
          event.packageName == 'com.android.browser' ||
          event.packageName == 'org.mozilla.firefox') {
        
        // event.text can be String or List depending on the package version.
        // We'll safely convert it.
        final rawText = event.text;
        List<String> texts = [];
        if (rawText is List) {
          texts = rawText.map((e) => e.toString()).toList();
        } else if (rawText is String) {
          texts = [rawText];
        }

        for (final text in texts) {
          final trimmed = text.trim();
          if (_isUrl(trimmed) && trimmed != _lastUrl) {
            _lastUrl = trimmed;
            debugPrint('Background Accessibility: Detected URL $trimmed');
            
            String validatedUrl = trimmed;
            if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
              validatedUrl = 'https://$trimmed';
            }
            
            try {
              await FirebaseBackendService.instance.syncUrlVisitDirect(validatedUrl);
              await ChildHistoryService.instance.addVisitedUrl(validatedUrl);
            } catch (e) {
              debugPrint('Error syncing background URL: $e');
            }
          }
        }
      }
    });
  }

  bool _isUrl(String text) {
    if (text.isEmpty) return false;
    // Don't flag random UI elements or single words
    if (text.contains(' ') && !text.startsWith('http')) return false;
    
    if (text.startsWith('http://') || text.startsWith('https://')) return true;
    if (text.contains('.com') || text.contains('.org') || text.contains('.net') || 
        text.contains('.gov') || text.contains('.edu') || text.contains('.io') ||
        text.contains('.co') || text.contains('.tv') || text.contains('.xyz')) {
      return true;
    }
    return false;
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }
}
