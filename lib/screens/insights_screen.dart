import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/home_widgets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final level = levelInfo(state.stats.xp);
    final earned = earnedIds(state.stats);
    final earnedCount = kAchievements.where((a) => earned.contains(a.id)).length;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => state.setView(AppView.home),
                icon: Icon(Icons.chevron_left, color: c.primary, size: 20),
                label: Text('Home', style: AppText.body(c, size: 14, color: c.primary)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
              const SizedBox(height: 8),
              Text('Your rhythm', style: AppText.serif(c, size: 26)),
              const SizedBox(height: 4),
              Text('Gentle progress, never pressure.', style: AppText.muted(c)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bigRing(c, level.progress, level.level),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.name, style: AppText.serif(c, size: 22)),
                          const SizedBox(height: 2),
                          Text('Level ${level.level} · ${state.stats.xp} XP', style: AppText.muted(c)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: level.progress,
                              minHeight: 8,
                              backgroundColor: c.inputBackground,
                              valueColor: AlwaysStoppedAnimation(c.primary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            level.toNext != null ? '${level.toNext} XP to next bloom' : "You've reached full bloom",
                            style: AppText.muted(c, size: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _stat(c, 'Streak', '${state.stats.streak}', 'days')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat(c, 'Wakes', '${state.stats.totalWakes}', 'total')),
                  const SizedBox(width: 10),
                  Expanded(child: _stat(c, 'Clear', '${state.stats.perfectCount}', 'first-try')),
                ],
              ),
              MonthCalendar(bloomDays: state.bloomDays, colors: c),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Achievements', style: AppText.body(c, size: 18, weight: FontWeight.w600)),
                  Text('$earnedCount/${kAchievements.length}', style: AppText.muted(c)),
                ],
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.6,
                children: kAchievements.map((a) {
                  final has = earned.contains(a.id);
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: has ? c.card : c.inputBackground,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Opacity(
                      opacity: has ? 1 : 0.65,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: has ? a.color : c.muted,
                            child: Icon(has ? a.icon : Icons.lock_outline, size: 18, color: has ? Colors.white : c.mutedForeground),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(a.name, style: AppText.body(c, size: 13), overflow: TextOverflow.ellipsis),
                                Text(a.desc, style: AppText.muted(c, size: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A soft note', style: AppText.body(c, color: c.calmClay)),
                    const SizedBox(height: 6),
                    Text(
                      'Badges are here to celebrate, not to chase. Missed mornings are part of resting well, too — grow at your own gentle pace.',
                      style: AppText.muted(c),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigRing(AppColors c, double progress, int levelNum) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: c.inputBackground,
              valueColor: AlwaysStoppedAnimation(c.primary),
            ),
          ),
          Text('$levelNum', style: AppText.serif(c, size: 24)),
        ],
      ),
    );
  }

  Widget _stat(AppColors c, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.serif(c, size: 26)),
          Text(label, style: AppText.muted(c)),
          Text(unit, style: AppText.muted(c, size: 11)),
        ],
      ),
    );
  }
}
