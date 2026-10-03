import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/types.dart';
import '../models/gamification.dart';
import '../services/dates.dart';
import '../services/storage_service.dart';
import '../services/ringtones.dart';

enum AppView { home, ringing, challenge, success, insights, bedtime, windDown }

const int kSnoozeMinutes = 5;

List<Alarm> _seedAlarms() => [
      Alarm(
        id: 'a1',
        time: '07:00',
        label: 'Weekday rise',
        days: [1, 2, 3, 4, 5],
        enabled: true,
        challenge: ChallengeType.math,
        ringtone: 'bloom',
      ),
      Alarm(
        id: 'a2',
        time: '08:30',
        label: 'Slow weekend',
        days: [0, 6],
        enabled: false,
        challenge: ChallengeType.memory,
        ringtone: 'chimes',
      ),
    ];

Bedtime _seedBedtime() => Bedtime(
      sleep: '22:30',
      wake: '07:00',
      days: const [0, 1, 2, 3, 4, 5, 6],
      enabled: false,
    );

class AppState extends ChangeNotifier {
  final StorageService storage;
  final RingtoneService ringtones = RingtoneService();

  AppState(this.storage) {
    alarms = storage.load<List<dynamic>>('alarms', [], (j) => j as List<dynamic>)
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
    if (alarms.isEmpty) alarms = _seedAlarms();

    isDark = storage.load<bool>('theme-dark', true, (j) => j as bool);

    final statsJson = storage.load<Map<String, dynamic>?>('stats', null, (j) => j as Map<String, dynamic>?);
    stats = statsJson != null ? Stats.fromJson(statsJson) : Stats.seed();

    final bedtimeJson = storage.load<Map<String, dynamic>?>('bedtime', null, (j) => j as Map<String, dynamic>?);
    bedtime = bedtimeJson != null ? Bedtime.fromJson(bedtimeJson) : _seedBedtime();

    bloomDays = storage.loadSet('bloomDays', seedBloomDays);

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  // ---- persisted state ----
  late List<Alarm> alarms;
  late bool isDark;
  late Stats stats;
  late Bedtime bedtime;
  late Set<String> bloomDays;

  // ---- transient state ----
  AppView view = AppView.home;
  int difficulty = 2;
  int snoozesLeft = 2;
  bool lastPerfect = false;
  int lastXp = 0;
  String? lastBadge;
  Alarm? ringingAlarm;
  Alarm? editingAlarm; // null = "add" mode when the setup sheet is open

  Timer? _tickTimer;
  DateTime? _snoozeUntil;
  bool _snoozedThisWake = false;
  final Set<String> _fired = {};

  void _persistAlarms() => storage.save('alarms', alarms.map((a) => a.toJson()).toList());
  void _persistTheme() => storage.save('theme-dark', isDark);
  void _persistStats() => storage.save('stats', stats.toJson());
  void _persistBedtime() => storage.save('bedtime', bedtime.toJson());
  void _persistBloomDays() => storage.saveSet('bloomDays', bloomDays);

  void setView(AppView v) {
    view = v;
    notifyListeners();
  }

  void toggleTheme() {
    isDark = !isDark;
    _persistTheme();
    notifyListeners();
  }

  void toggleAlarm(String id) {
    alarms = alarms.map((a) => a.id == id ? a.copyWith(enabled: !a.enabled) : a).toList();
    _persistAlarms();
    notifyListeners();
  }

  void saveAlarm(Alarm a) {
    final exists = alarms.any((x) => x.id == a.id);
    alarms = exists ? alarms.map((x) => x.id == a.id ? a : x).toList() : [...alarms, a];
    _persistAlarms();
    notifyListeners();
  }

  void deleteAlarm(String id) {
    alarms = alarms.where((x) => x.id != id).toList();
    _persistAlarms();
    notifyListeners();
  }

  void updateBedtime(Bedtime b) {
    bedtime = b;
    _persistBedtime();
    notifyListeners();
  }

  void previewAlarm() {
    final a = alarms.where((x) => x.enabled).isNotEmpty
        ? alarms.firstWhere((x) => x.enabled)
        : (alarms.isNotEmpty ? alarms.first : null);
    if (a != null) _triggerRing(a, real: false);
  }

  void _triggerRing(Alarm a, {bool real = true}) {
    ringingAlarm = a;
    snoozesLeft = 2;
    _snoozeUntil = null;
    _snoozedThisWake = false;
    view = AppView.ringing;
    ringtones.startAlarm(a.ringtone, gradual: a.gradualVolume);
    if (a.vibrate) _startVibration();

    if (real) {
      if (a.deleteAfter) {
        alarms = alarms.where((x) => x.id != a.id).toList();
        _persistAlarms();
      } else if (a.days.isEmpty) {
        alarms = alarms.map((x) => x.id == a.id ? x.copyWith(enabled: false) : x).toList();
        _persistAlarms();
      }
    }
    notifyListeners();
  }

  Timer? _vibeTimer;
  Future<void> _startVibration() async {
    _vibeTimer?.cancel();
    if (await Vibration.hasVibrator() != true) return;
    Vibration.vibrate(pattern: [0, 400, 200, 400]);
    _vibeTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      Vibration.vibrate(pattern: [0, 400, 200, 400]);
    });
  }

  void _stopSoundAndVibe() {
    ringtones.stopAlarm();
    _vibeTimer?.cancel();
    Vibration.cancel();
  }

  void beginChallenge() {
    view = AppView.challenge;
    notifyListeners();
  }

  void snooze() {
    if (snoozesLeft <= 0) return;
    _snoozedThisWake = true;
    snoozesLeft -= 1;
    stats.streak = (stats.streak - 1).clamp(0, 1 << 30);
    _persistStats();
    _snoozeUntil = DateTime.now().add(const Duration(minutes: kSnoozeMinutes));
    _stopSoundAndVibe();
    view = AppView.home;
    notifyListeners();
  }

  void completeChallenge(bool perfect) {
    lastPerfect = perfect;
    difficulty = (difficulty + (perfect ? 1 : -1)).clamp(1, 3);

    final xpGain = kXpPerWake + (perfect ? kXpPerfectBonus : 0);
    lastXp = xpGain;

    final challenge = ringingAlarm?.challenge ?? ChallengeType.math;
    final now = DateTime.now();
    final wakeMinutes = now.hour * 60 + now.minute;

    final before = earnedIds(stats);
    stats.xp += xpGain;
    stats.streak += 1;
    stats.totalWakes += 1;
    stats.perfectCount += perfect ? 1 : 0;
    stats.noSnoozeStreak = _snoozedThisWake ? 0 : stats.noSnoozeStreak + 1;
    stats.counts[challenge] = (stats.counts[challenge] ?? 0) + 1;
    stats.earliestWakeMinutes =
        wakeMinutes < stats.earliestWakeMinutes ? wakeMinutes : stats.earliestWakeMinutes;
    final after = earnedIds(stats);
    final freshId = after.difference(before).isNotEmpty ? after.difference(before).first : null;
    lastBadge = freshId != null
        ? kAchievements.firstWhere((a) => a.id == freshId).name
        : null;
    _persistStats();

    bloomDays = {...bloomDays, isoDay(DateTime.now())};
    _persistBloomDays();

    _snoozeUntil = null;
    ringingAlarm = null;
    _stopSoundAndVibe();
    view = AppView.success;
    notifyListeners();
  }

  void finishSuccess() {
    view = AppView.home;
    notifyListeners();
  }

  void _tick() {
    final now = DateTime.now();

    if (_snoozeUntil != null && now.isAfter(_snoozeUntil!)) {
      _snoozeUntil = null;
      if (ringingAlarm != null && view != AppView.challenge) {
        view = AppView.ringing;
        ringtones.startAlarm(ringingAlarm!.ringtone, gradual: ringingAlarm!.gradualVolume);
        if (ringingAlarm!.vibrate) _startVibration();
        notifyListeners();
      }
      return;
    }

    if (view != AppView.home && view != AppView.insights) return;

    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';
    final day = now.weekday % 7; // DateTime: Mon=1..Sun=7 -> convert to 0=Sun..6=Sat
    final minuteKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$hh$mm';

    if (bedtime.enabled) {
      final remindAt = minusMinutes(bedtime.sleep, bedtime.reminder);
      if (remindAt == time && bedtime.days.contains(day)) {
        final key = 'winddown-$minuteKey';
        if (!_fired.contains(key)) {
          _fired.add(key);
          view = AppView.windDown;
          notifyListeners();
          return;
        }
      }
    }

    final ringers = [...alarms, if (bedtime.enabled) bedtime.toWakeAlarm()];
    for (final a in ringers) {
      if (!a.enabled || a.time != time) continue;
      final repeats = a.days.isEmpty || a.days.contains(day);
      if (!repeats) continue;
      final key = '${a.id}-$minuteKey';
      if (_fired.contains(key)) continue;
      _fired.add(key);
      _triggerRing(a);
      break;
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _vibeTimer?.cancel();
    ringtones.dispose();
    super.dispose();
  }
}
