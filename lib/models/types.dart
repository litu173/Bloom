import 'package:uuid/uuid.dart';

enum ChallengeType { math, memory, tap, puzzle }

extension ChallengeTypeX on ChallengeType {
  String get id => name;

  static ChallengeType fromId(String? id) {
    return ChallengeType.values.firstWhere(
      (c) => c.name == id,
      orElse: () => ChallengeType.math,
    );
  }
}

class ChallengeMeta {
  final String label;
  final String blurb;
  const ChallengeMeta(this.label, this.blurb);
}

const Map<ChallengeType, ChallengeMeta> kChallengeMeta = {
  ChallengeType.math: ChallengeMeta('Gentle math', 'Three soft sums to stir the mind'),
  ChallengeType.tap: ChallengeMeta('Tap the blooms', 'Follow a calm sequence of petals'),
  ChallengeType.puzzle: ChallengeMeta('Little puzzle', 'Continue the gentle pattern'),
  ChallengeType.memory: ChallengeMeta('Remember the number', 'Recall a number shown briefly'),
};

const List<String> kDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const List<String> kDayLabelsLong = [
  'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
];

bool _sameDays(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  final sa = [...a]..sort();
  final sb = [...b]..sort();
  for (var i = 0; i < sa.length; i++) {
    if (sa[i] != sb[i]) return false;
  }
  return true;
}

/// Short human label for a repeat schedule, e.g. "Weekdays".
String repeatLabel(List<int> days) {
  if (days.isEmpty) return 'Never';
  if (_sameDays(days, [0, 1, 2, 3, 4, 5, 6])) return 'Every day';
  if (_sameDays(days, [1, 2, 3, 4, 5])) return 'Weekdays';
  if (_sameDays(days, [0, 6])) return 'Weekends';
  const order = [1, 2, 3, 4, 5, 6, 0];
  return order
      .where((d) => days.contains(d))
      .map((d) => kDayLabelsLong[d].substring(0, 3))
      .join(' ');
}

/// A poetic default alarm name matching the repeat schedule.
String defaultLabelForDays(List<int> days) {
  if (days.isEmpty) return 'One gentle rise';
  if (_sameDays(days, [0, 1, 2, 3, 4, 5, 6])) return 'Daily bloom';
  if (_sameDays(days, [1, 2, 3, 4, 5])) return 'Weekday sunrise';
  if (_sameDays(days, [0, 6])) return 'Slow weekend';
  return 'Custom rhythm';
}

const List<String> kAutoLabels = [
  'Alarm',
  'One gentle rise',
  'Daily bloom',
  'Weekday sunrise',
  'Slow weekend',
  'Custom rhythm',
];

class FormattedTime {
  final String hr;
  final String min;
  final String period;
  const FormattedTime(this.hr, this.min, this.period);
}

/// "07:00" -> hour/min/period for display.
FormattedTime formatTime(String t) {
  final parts = (t.isEmpty ? '00:00' : t).split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
  final period = h >= 12 ? 'PM' : 'AM';
  final hr = h % 12 == 0 ? 12 : h % 12;
  return FormattedTime(
    hr.toString().padLeft(2, '0'),
    m.toString().padLeft(2, '0'),
    period,
  );
}

class Duration12 {
  final int h;
  final int m;
  const Duration12(this.h, this.m);
}

/// Time in bed between sleep and wake, handling the overnight wrap.
Duration12 sleepDuration(String sleep, String wake) {
  final s = sleep.split(':').map(int.parse).toList();
  final w = wake.split(':').map(int.parse).toList();
  var mins = (w[0] * 60 + w[1]) - (s[0] * 60 + s[1]);
  if (mins <= 0) mins += 24 * 60;
  return Duration12(mins ~/ 60, mins % 60);
}

/// Subtract minutes from an "HH:MM" time, wrapping across midnight.
String minusMinutes(String time, int mins) {
  final parts = time.split(':').map(int.parse).toList();
  var total = (parts[0] * 60 + parts[1] - mins) % (24 * 60);
  if (total < 0) total += 24 * 60;
  final h = (total ~/ 60).toString().padLeft(2, '0');
  final m = (total % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

class Alarm {
  String id;
  String time; // "07:00"
  String label;
  List<int> days; // 0=Sun..6=Sat, empty = one-off
  bool enabled;
  bool preAlarm;
  bool gradualVolume;
  bool vibrate;
  bool deleteAfter;
  ChallengeType challenge;
  String ringtone;

  Alarm({
    String? id,
    required this.time,
    required this.label,
    required this.days,
    this.enabled = true,
    this.preAlarm = true,
    this.gradualVolume = true,
    this.vibrate = true,
    this.deleteAfter = false,
    this.challenge = ChallengeType.math,
    this.ringtone = 'bloom',
  }) : id = id ?? const Uuid().v4();

  Alarm copyWith({
    String? time,
    String? label,
    List<int>? days,
    bool? enabled,
    bool? preAlarm,
    bool? gradualVolume,
    bool? vibrate,
    bool? deleteAfter,
    ChallengeType? challenge,
    String? ringtone,
  }) {
    return Alarm(
      id: id,
      time: time ?? this.time,
      label: label ?? this.label,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      preAlarm: preAlarm ?? this.preAlarm,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      vibrate: vibrate ?? this.vibrate,
      deleteAfter: deleteAfter ?? this.deleteAfter,
      challenge: challenge ?? this.challenge,
      ringtone: ringtone ?? this.ringtone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'label': label,
        'days': days,
        'enabled': enabled,
        'preAlarm': preAlarm,
        'gradualVolume': gradualVolume,
        'vibrate': vibrate,
        'deleteAfter': deleteAfter,
        'challenge': challenge.id,
        'ringtone': ringtone,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String?,
        time: json['time'] as String? ?? '07:00',
        label: json['label'] as String? ?? 'Alarm',
        days: (json['days'] as List?)?.map((e) => e as int).toList() ?? [],
        enabled: json['enabled'] as bool? ?? true,
        preAlarm: json['preAlarm'] as bool? ?? true,
        gradualVolume: json['gradualVolume'] as bool? ?? true,
        vibrate: json['vibrate'] as bool? ?? true,
        deleteAfter: json['deleteAfter'] as bool? ?? false,
        challenge: ChallengeTypeX.fromId(json['challenge'] as String?),
        ringtone: json['ringtone'] as String? ?? 'bloom',
      );
}

class Bedtime {
  String sleep;
  String wake;
  List<int> days;
  bool enabled;
  int reminder; // minutes before, 0 = none
  String ringtone;
  bool gradualVolume;
  bool vibrate;
  ChallengeType challenge;

  Bedtime({
    required this.sleep,
    required this.wake,
    required this.days,
    this.enabled = false,
    this.reminder = 15,
    this.ringtone = 'birds',
    this.gradualVolume = true,
    this.vibrate = true,
    this.challenge = ChallengeType.math,
  });

  Bedtime copyWith({
    String? sleep,
    String? wake,
    List<int>? days,
    bool? enabled,
    int? reminder,
    String? ringtone,
    bool? gradualVolume,
    bool? vibrate,
    ChallengeType? challenge,
  }) {
    return Bedtime(
      sleep: sleep ?? this.sleep,
      wake: wake ?? this.wake,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      reminder: reminder ?? this.reminder,
      ringtone: ringtone ?? this.ringtone,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      vibrate: vibrate ?? this.vibrate,
      challenge: challenge ?? this.challenge,
    );
  }

  /// Build a ringing Alarm from this bedtime schedule's wake-up settings.
  Alarm toWakeAlarm() => Alarm(
        id: 'bedtime-wake',
        time: wake,
        label: 'Bedtime wake-up',
        days: days,
        enabled: enabled,
        preAlarm: false,
        gradualVolume: gradualVolume,
        vibrate: vibrate,
        deleteAfter: false,
        challenge: challenge,
        ringtone: ringtone,
      );

  Map<String, dynamic> toJson() => {
        'sleep': sleep,
        'wake': wake,
        'days': days,
        'enabled': enabled,
        'reminder': reminder,
        'ringtone': ringtone,
        'gradualVolume': gradualVolume,
        'vibrate': vibrate,
        'challenge': challenge.id,
      };

  factory Bedtime.fromJson(Map<String, dynamic> json) => Bedtime(
        sleep: json['sleep'] as String? ?? '22:30',
        wake: json['wake'] as String? ?? '07:00',
        days: (json['days'] as List?)?.map((e) => e as int).toList() ??
            [0, 1, 2, 3, 4, 5, 6],
        enabled: json['enabled'] as bool? ?? false,
        reminder: json['reminder'] as int? ?? 15,
        ringtone: json['ringtone'] as String? ?? 'birds',
        gradualVolume: json['gradualVolume'] as bool? ?? true,
        vibrate: json['vibrate'] as bool? ?? true,
        challenge: ChallengeTypeX.fromId(json['challenge'] as String?),
      );
}
