import 'package:flutter/material.dart';
import 'types.dart';

class Stats {
  int xp;
  int streak;
  int totalWakes;
  int perfectCount;
  int noSnoozeStreak;
  Map<ChallengeType, int> counts;
  int earliestWakeMinutes;

  Stats({
    this.xp = 0,
    this.streak = 0,
    this.totalWakes = 0,
    this.perfectCount = 0,
    this.noSnoozeStreak = 0,
    Map<ChallengeType, int>? counts,
    this.earliestWakeMinutes = 24 * 60,
  }) : counts = counts ??
            {
              ChallengeType.math: 0,
              ChallengeType.memory: 0,
              ChallengeType.tap: 0,
              ChallengeType.puzzle: 0,
            };

  factory Stats.seed() => Stats(
        xp: 210,
        streak: 12,
        totalWakes: 34,
        perfectCount: 8,
        noSnoozeStreak: 4,
        counts: {
          ChallengeType.math: 12,
          ChallengeType.memory: 6,
          ChallengeType.tap: 9,
          ChallengeType.puzzle: 3,
        },
        earliestWakeMinutes: 6 * 60 + 15,
      );

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streak': streak,
        'totalWakes': totalWakes,
        'perfectCount': perfectCount,
        'noSnoozeStreak': noSnoozeStreak,
        'counts': counts.map((k, v) => MapEntry(k.id, v)),
        'earliestWakeMinutes': earliestWakeMinutes,
      };

  factory Stats.fromJson(Map<String, dynamic> json) {
    final rawCounts = (json['counts'] as Map?)?.cast<String, dynamic>() ?? {};
    return Stats(
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      totalWakes: json['totalWakes'] as int? ?? 0,
      perfectCount: json['perfectCount'] as int? ?? 0,
      noSnoozeStreak: json['noSnoozeStreak'] as int? ?? 0,
      counts: {
        for (final c in ChallengeType.values) c: (rawCounts[c.id] as int?) ?? 0,
      },
      earliestWakeMinutes: json['earliestWakeMinutes'] as int? ?? 24 * 60,
    );
  }
}

class LevelDef {
  final String name;
  final int xp;
  const LevelDef(this.name, this.xp);
}

const List<LevelDef> kLevels = [
  LevelDef('Seedling', 0),
  LevelDef('Sprout', 30),
  LevelDef('Bud', 80),
  LevelDef('Bloom', 150),
  LevelDef('Blossom', 250),
  LevelDef('Wildflower', 400),
  LevelDef('Garden', 600),
  LevelDef('Meadow', 900),
];

class LevelInfo {
  final int level;
  final String name;
  final int curBase;
  final int? nextBase;
  final int intoLevel;
  final int span;
  final double progress;
  final int? toNext;

  const LevelInfo({
    required this.level,
    required this.name,
    required this.curBase,
    required this.nextBase,
    required this.intoLevel,
    required this.span,
    required this.progress,
    required this.toNext,
  });
}

LevelInfo levelInfo(int xp) {
  var idx = 0;
  for (var i = 0; i < kLevels.length; i++) {
    if (xp >= kLevels[i].xp) idx = i;
  }
  final cur = kLevels[idx];
  final next = idx + 1 < kLevels.length ? kLevels[idx + 1] : null;
  final curBase = cur.xp;
  final nextBase = next?.xp;
  final span = (nextBase != null && nextBase > curBase) ? nextBase - curBase : 1;
  final intoLevel = xp - curBase;
  return LevelInfo(
    level: idx + 1,
    name: cur.name,
    curBase: curBase,
    nextBase: nextBase,
    intoLevel: intoLevel,
    span: span,
    progress: nextBase != null ? (intoLevel / span).clamp(0.0, 1.0) : 1.0,
    toNext: nextBase != null ? nextBase - xp : null,
  );
}

const int kXpPerWake = 10;
const int kXpPerfectBonus = 8;

class Achievement {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final bool Function(Stats s, int level) earned;

  const Achievement({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.color,
    required this.earned,
  });
}

final List<Achievement> kAchievements = [
  Achievement(
    id: 'first-bloom',
    name: 'First Bloom',
    desc: 'Complete your first gentle wake',
    icon: Icons.local_florist,
    color: const Color(0xFFF2506E),
    earned: (s, _) => s.totalWakes >= 1,
  ),
  Achievement(
    id: 'clear-dawn',
    name: 'Clear Dawn',
    desc: 'Solve a challenge on the first try',
    icon: Icons.auto_awesome,
    color: const Color(0xFFFF8AA3),
    earned: (s, _) => s.perfectCount >= 1,
  ),
  Achievement(
    id: 'early-riser',
    name: 'Early Riser',
    desc: 'Wake before 6:30 in the morning',
    icon: Icons.wb_twilight,
    color: const Color(0xFFE6A15C),
    earned: (s, _) => s.earliestWakeMinutes <= 6 * 60 + 30,
  ),
  Achievement(
    id: 'week-in-bloom',
    name: 'Week in Bloom',
    desc: 'Reach a 7-morning streak',
    icon: Icons.favorite,
    color: const Color(0xFFE8637F),
    earned: (s, _) => s.streak >= 7,
  ),
  Achievement(
    id: 'math-mind',
    name: 'Math Mind',
    desc: 'Solve 10 gentle-math wakes',
    icon: Icons.psychology,
    color: const Color(0xFFC98AA0),
    earned: (s, _) => (s.counts[ChallengeType.math] ?? 0) >= 10,
  ),
  Achievement(
    id: 'memory-master',
    name: 'Memory Master',
    desc: 'Solve 10 memory wakes',
    icon: Icons.center_focus_strong,
    color: const Color(0xFF8F6FD0),
    earned: (s, _) => (s.counts[ChallengeType.memory] ?? 0) >= 10,
  ),
  Achievement(
    id: 'green-thumb',
    name: 'Green Thumb',
    desc: 'Try every kind of challenge',
    icon: Icons.eco,
    color: const Color(0xFF7FAE7A),
    earned: (s, _) =>
        (s.counts[ChallengeType.math] ?? 0) > 0 &&
        (s.counts[ChallengeType.memory] ?? 0) > 0 &&
        (s.counts[ChallengeType.tap] ?? 0) > 0 &&
        (s.counts[ChallengeType.puzzle] ?? 0) > 0,
  ),
  Achievement(
    id: 'snooze-free',
    name: 'Snooze-Free',
    desc: 'Wake 7 times without snoozing',
    icon: Icons.nightlight,
    color: const Color(0xFF6F9BD0),
    earned: (s, _) => s.noSnoozeStreak >= 7,
  ),
  Achievement(
    id: 'full-blossom',
    name: 'Full Blossom',
    desc: 'Reach the Blossom level',
    icon: Icons.emoji_events,
    color: const Color(0xFFF2B705),
    earned: (_, level) => level >= 5,
  ),
];

Set<String> earnedIds(Stats s) {
  final lvl = levelInfo(s.xp).level;
  return kAchievements.where((a) => a.earned(s, lvl)).map((a) => a.id).toSet();
}
