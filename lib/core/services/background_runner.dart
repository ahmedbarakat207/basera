import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:basera/core/services/accessibility_monitoring_service.dart';
import 'package:basera/core/utils/child_history_service.dart';
import 'package:basera/core/services/basera_database.dart';
import 'package:basera/core/services/sync_service.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'basera_background',
    'Basera Monitoring Service',
    description: 'This channel is used to keep the Basera monitoring service alive.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'basera_background',
      initialNotificationTitle: 'Basera',
      initialNotificationContent: 'Monitoring running in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize essential native services in this isolated background thread
    await Firebase.initializeApp();
    await BaseraDatabase.instance.database;

    // Check if we should actually be monitoring
    final role = await ChildHistoryService.instance.getUserRole();
    if (role == 'child') {
      AccessibilityMonitoringService.instance.startMonitoring();
      SyncService.instance.startListening();
    } else {
      // If parent, stop the service to save battery
      service.stopSelf();
    }
  } catch (e) {
    debugPrint('Background service initialization failed: $e');
  }
}
