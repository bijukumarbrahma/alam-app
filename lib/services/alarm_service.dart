import 'dart:io';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static Future<void> setAlarm(AlarmItem alarmItem) async {
    final alarmSettings = AlarmSettings(
      id: alarmItem.id,
      dateTime: alarmItem.nextAlarmDateTime,
      assetAudioPath: alarmItem.audioPath,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: alarmItem.label.isEmpty ? 'Wake Up' : alarmItem.label,
        body: 'Time: ${alarmItem.formattedTime}',
        stopButton: 'Stop',
        androidSnoozeButton: 'Snooze',
        iconColor: const Color(0xFF7C4DFF),
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> snoozeAlarm(int id, {int minutes = 5}) async {
    final alarms = await Alarm.getAlarms();
    final alarm = alarms.where((a) => a.id == id).firstOrNull;

    if (alarm != null) {
      final snoozedSettings = alarm.copyWith(
        dateTime: DateTime.now().add(Duration(minutes: minutes)),
      );
      await Alarm.set(alarmSettings: snoozedSettings);
    }
  }

  static Future<List<AlarmSettings>> getActiveAlarms() async {
    return await Alarm.getAlarms();
  }
}
