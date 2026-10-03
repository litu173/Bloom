import 'package:flutter/material.dart';
import '../models/types.dart';
import '../services/dates.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class WeeklyStrip extends StatelessWidget {
  final List<bool> week; // Sun..Sat
  final int todayIndex;
  final VoidCallback onOpen;
  final AppColors colors;
  const WeeklyStrip({
    super.key,
    required this.week,
    required this.todayIndex,
    required this.onOpen,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This week', style: AppText.muted(c)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isToday = i == todayIndex;
                final isFuture = i > todayIndex;
                final on = week[i] && !isFuture;
                return Column(
                  children: [
                    Text(kDayLabels[i],
                        style: AppText.body(c,
                            size: 12, color: isToday ? c.primary : c.mutedForeground)),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: isFuture ? 0.4 : 1,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: on ? c.calmMist : c.inputBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isToday ? c.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: on ? const Text('🌸', style: TextStyle(fontSize: 15)) : null,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class BedtimeCard extends StatelessWidget {
  final Bedtime bedtime;
  final VoidCallback onOpen;
  final AppColors colors;
  const BedtimeCard({super.key, required this.bedtime, required this.onOpen, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final s = formatTime(bedtime.sleep);
    final w = formatTime(bedtime.wake);
    final dur = sleepDuration(bedtime.sleep, bedtime.wake);
    return GestureDetector(
      onTap: onOpen,
      child: Opacity(
        opacity: bedtime.enabled ? 1 : 0.55,
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bedtime', style: AppText.muted(c)),
                  Row(
                    children: [
                      Text(bedtime.enabled ? '${dur.h}h ${dur.m}m' : 'Off',
                          style: AppText.body(c, size: 13, color: c.primary)),
                      Icon(Icons.chevron_right, size: 16, color: c.primary),
                    ],
                  ),
                ],
              ),
              if (bedtime.enabled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _timeStat(c, Icons.dark_mode, 'Fall asleep', s)),
                    Container(width: 1, height: 32, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
                    Expanded(child: _timeStat(c, Icons.wb_twilight, 'Wake up', w)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeStat(AppColors c, IconData icon, String label, FormattedTime t) {
    return Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: c.calmMist, child: Icon(icon, size: 16, color: c.primary)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.muted(c, size: 12)),
            Text('${t.hr}:${t.min} ${t.period}', style: AppText.body(c, size: 16)),
          ],
        ),
      ],
    );
  }
}

class MonthCalendar extends StatelessWidget {
  final Set<String> bloomDays;
  final AppColors colors;
  const MonthCalendar({super.key, required this.bloomDays, required this.colors});

  static const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final now = DateTime.now();
    final y = now.year;
    final m = now.month; // 1-12
    final today = now.day;
    final total = daysInMonth(y, m - 1);
    final firstWeekday = DateTime(y, m, 1).weekday % 7; // 0=Sun
    final todayIso = isoDay(now);

    final cells = <int?>[
      ...List.filled(firstWeekday, null),
      ...List.generate(total, (i) => i + 1),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${monthNames[m - 1]} $y · a bloom for each gentle wake', style: AppText.muted(c)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final d in kDayLabels)
                Center(child: Text(d, style: AppText.muted(c, size: 12))),
              for (final day in cells)
                if (day == null)
                  const SizedBox.shrink()
                else
                  _dayCell(c, y, m, day, today, todayIso),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(AppColors c, int y, int m, int day, int today, String todayIso) {
    final iso = isoFromParts(y, m, day);
    final isToday = iso == todayIso;
    final isFuture = day > today;
    final on = bloomDays.contains(iso) && !isFuture;
    return Opacity(
      opacity: isFuture ? 0.35 : 1,
      child: Container(
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? c.calmMist : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isToday ? c.primary : Colors.transparent, width: 2),
        ),
        child: on
            ? const Text('🌸', style: TextStyle(fontSize: 12))
            : Text('$day', style: AppText.muted(c, size: 12)),
      ),
    );
  }
}
