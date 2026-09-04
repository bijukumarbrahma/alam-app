import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request all essential permissions required for reliable alarms,
  /// especially when screen is off or device is in Doze/battery saving mode.
  static Future<void> checkAndRequestPermissions(BuildContext context) async {
    if (!Platform.isAndroid) return;

    // 1. Notification Permission (Android 13+)
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }

    // 2. Schedule Exact Alarm Permission (Android 12+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    if (!exactAlarmStatus.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }

    // 3. Ignore Battery Optimizations (Critical for screen-off alarms)
    final batteryOptStatus =
        await Permission.ignoreBatteryOptimizations.status;
    if (!batteryOptStatus.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  /// Request storage/audio permission when picking audio files
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // On Android 13+ (SDK 33+), audio files use Permission.audio
    final audioStatus = await Permission.audio.status;
    if (audioStatus.isGranted) return true;

    final reqAudio = await Permission.audio.request();
    if (reqAudio.isGranted) return true;

    // Fallback to general storage for Android 12 and below
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final reqStorage = await Permission.storage.request();
    return reqStorage.isGranted;
  }
}
