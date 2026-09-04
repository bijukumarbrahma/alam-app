import 'dart:convert';

class AlarmItem {
  final int id;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final String? audioPath;
  final String? audioName;
  final List<int> repeatDays; // 1=Mon, 2=Tue, ..., 7=Sun

  AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    this.label = '',
    this.isEnabled = true,
    this.audioPath,
    this.audioName,
    this.repeatDays = const [],
  });

  AlarmItem copyWith({
    int? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    String? audioPath,
    String? audioName,
    List<int>? repeatDays,
  }) {
    return AlarmItem(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      audioPath: audioPath ?? this.audioPath,
      audioName: audioName ?? this.audioName,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'audioPath': audioPath,
      'audioName': audioName,
      'repeatDays': repeatDays,
    };
  }

  factory AlarmItem.fromJson(Map<String, dynamic> json) {
    return AlarmItem(
      id: json['id'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      audioPath: json['audioPath'] as String?,
      audioName: json['audioName'] as String?,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AlarmItem.fromJsonString(String jsonString) {
    return AlarmItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  String get formattedTime {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';

    final weekdays = [1, 2, 3, 4, 5];
    final weekend = [6, 7];
    if (repeatDays.length == 5 &&
        weekdays.every((d) => repeatDays.contains(d))) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        weekend.every((d) => repeatDays.contains(d))) {
      return 'Weekends';
    }

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => dayNames[d]).join(', ');
  }

  DateTime get nextAlarmDateTime {
    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (repeatDays.isEmpty) {
      // One-time alarm
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }
      return alarmTime;
    }

    // Repeating alarm - find next matching day
    for (int i = 0; i < 7; i++) {
      final candidate = alarmTime.add(Duration(days: i));
      final candidateDow = candidate.weekday; // 1=Monday, 7=Sunday
      if (repeatDays.contains(candidateDow)) {
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }

    // Fallback: next week
    return alarmTime.add(const Duration(days: 7));
  }
}
