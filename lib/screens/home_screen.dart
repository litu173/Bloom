import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../models/types.dart';
import '../services/dates.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/home_widgets.dart';
import 'alarm_setup_screen.dart';

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

int _minutesUntilNext(Alarm a) {
  final parts = (a.time.isEmpty ? '00:00' : a.time).split(':').map(int.parse).toList();
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;
  final target = parts[0] * 60 + parts[1];
  final days = a.days;
  if (days.isEmpty) {
    return target > nowMin ? target - nowMin : target - nowMin + 1440;
  }
  final todayIdx = now.weekday % 7;
  for (var offset = 0; offset < 7; offset++) {
    final day = (todayIdx + offset) % 7;
    if (!days.contains(day)) continue;
    if (offset == 0 && target <= nowMin) continue;
    return offset * 1440 + (target - nowMin);
  }
  return 7 * 1440 + (target - nowMin);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final level = levelInfo(state.stats.xp);
    final todayIndex = DateTime.now().weekday % 7;

    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    final week = List.generate(7, (i) {
      final d = sunday.add(Duration(days: i));
      return state.bloomDays.contains(isoDay(d));
    });

    final sorted = [...state.alarms]..sort((a, b) {
        if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
        return _minutesUntilNext(a).compareTo(_minutesUntilNext(b));
      });
    final next = sorted.where((a) => a.enabled).isEmpty ? null : sorted.firstWhere((a) => a.enabled);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_greeting()}, Wren', style: AppText.muted(c)),
                    const SizedBox(height: 4),
                    Text('Rest easy tonight', style: AppText.body(c, size: 28, weight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    _iconButton(
                      c,
                      icon: state.isDark ? Icons.wb_sunny : Icons.dark_mode,
                      onTap: state.toggleTheme,
                    ),
                    const SizedBox(width: 8),
                    _iconButton(
                      c,
                      icon: Icons.add,
                      filled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlarmSetupScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            WeeklyStrip(
              week: week,
              todayIndex: todayIndex,
              colors: c,
              onOpen: () => state.setView(AppView.insights),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => state.setView(AppView.insights),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    _levelRing(c, level.progress, level.level),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${level.name} · ${state.stats.streak}-day streak', style: AppText.body(c)),
                          Text(
                            level.toNext != null ? '${level.toNext} XP to next bloom' : 'Fully in bloom 🌸',
                            style: AppText.muted(c),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.mutedForeground),
                  ],
                ),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: c.heroGradient,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Text('NEXT GENTLE WAKE',
                        style: AppText.muted(c, size: 12).copyWith(letterSpacing: 2)),
                    const SizedBox(height: 8),
                    _nextTime(c, next.time),
                    const SizedBox(height: 4),
                    Text(kChallengeMeta[next.challenge]!.label, style: AppText.muted(c)),
                  ],
                ),
              ),
            ],
            BedtimeCard(
              bedtime: state.bedtime,
              colors: c,
              onOpen: () => state.setView(AppView.bedtime),
            ),
            const SizedBox(height: 20),
            ...sorted.map((a) => _alarmTile(context, c, state, a)),
            const SizedBox(height: 20),
            _pillButton(c, Icons.auto_awesome, 'Preview a gentle wake-up', state.previewAlarm),
            const SizedBox(height: 10),
            _pillButton(c, Icons.nightlight_round, 'Wind down now', () => state.setView(AppView.windDown)),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(AppColors c, {required IconData icon, required VoidCallback onTap, bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? c.primary : c.card,
          border: filled ? null : Border.all(color: c.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: filled ? c.primaryForeground : c.primary),
      ),
    );
  }

  Widget _levelRing(AppColors c, double progress, int levelNum) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: c.inputBackground,
              valueColor: AlwaysStoppedAnimation(c.primary),
            ),
          ),
          Text('$levelNum', style: AppText.body(c, size: 15, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _nextTime(AppColors c, String time) {
    final t = formatTime(time);
    return RichText(
      text: TextSpan(
        style: AppText.body(c, size: 52, weight: FontWeight.w400),
        children: [
          TextSpan(text: '${t.hr}:${t.min} '),
          TextSpan(text: t.period, style: AppText.muted(c, size: 18)),
        ],
      ),
    );
  }

  Widget _alarmTile(BuildContext context, AppColors c, AppState state, Alarm a) {
    final t = formatTime(a.time);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AlarmSetupScreen(initial: a)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: a.enabled ? 1 : 0.4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppText.body(c, size: 24, weight: FontWeight.w400),
                        children: [
                          TextSpan(text: '${t.hr}:${t.min} '),
                          TextSpan(text: t.period, style: AppText.muted(c, size: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(a.label, style: AppText.muted(c)),
                        const SizedBox(width: 8),
                        ...List.generate(7, (di) {
                          final on = a.days.contains(di);
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Opacity(
                              opacity: on ? 1 : 0.35,
                              child: Text(kDayLabels[di],
                                  style: AppText.body(c,
                                      size: 11, color: on ? c.calmRose : c.mutedForeground)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Switch(
              value: a.enabled,
              activeColor: c.primary,
              onChanged: (_) => state.toggleAlarm(a.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(AppColors c, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: c.card.withOpacity(0.6),
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c.mutedForeground),
            const SizedBox(width: 8),
            Text(label, style: AppText.muted(c)),
          ],
        ),
      ),
    );
  }
}
