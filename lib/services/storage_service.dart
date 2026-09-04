import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class StorageService {
  static const String _alarmsKey = 'saved_alarms';

  static Future<List<AlarmItem>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_alarmsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList
        .map((json) => AlarmItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAlarms(List<AlarmItem> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_alarmsKey, jsonString);
  }

  static Future<void> addAlarm(AlarmItem alarm) async {
    final alarms = await getAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  static Future<void> updateAlarm(AlarmItem alarm) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index != -1) {
      alarms[index] = alarm;
      await saveAlarms(alarms);
    }
  }

  static Future<void> deleteAlarm(int id) async {
    final alarms = await getAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }

  static Future<int> getNextId() async {
    final alarms = await getAlarms();
    if (alarms.isEmpty) return 1;
    return alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
  }
}
