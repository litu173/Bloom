import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/picker_sheets.dart';

const _reminderOptions = [0, 5, 10, 15, 30, 45, 60];
String _reminderLabel(int m) => m == 0 ? 'None' : '$m min before';

class BedtimeScreen extends StatelessWidget {
  const BedtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final b = state.bedtime;
    final s = formatTime(b.sleep);
    final w = formatTime(b.wake);
    final dur = sleepDuration(b.sleep, b.wake);

    void set(Bedtime Function(Bedtime) update) => state.updateBedtime(update(b));

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
              Text('Bedtime', style: AppText.serif(c, size: 26)),
              const SizedBox(height: 4),
              Text('A steady wind-down helps your rhythm bloom.', style: AppText.muted(c)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.inputBackground.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sleep schedule', style: AppText.body(c)),
                          Text(b.enabled ? '${dur.h}h ${dur.m}m in bed' : 'Turned off', style: AppText.muted(c)),
                        ],
                      ),
                    ),
                    Switch(
                      value: b.enabled,
                      activeColor: c.primary,
                      onChanged: (v) => set((bt) => bt.copyWith(enabled: v)),
                    ),
                  ],
                ),
              ),
              if (b.enabled) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: c.inputBackground.withOpacity(0.6),
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _timeRow(context, c, Icons.dark_mode_outlined, 'Fall asleep', s, () async {
                        await showTimeSheet(
                          context: context,
                          colors: c,
                          title: 'Fall asleep',
                          value: b.sleep,
                          onSave: (t) => set((bt) => bt.copyWith(sleep: t)),
                        );
                      }),
                      Divider(height: 1, color: c.border, indent: 16, endIndent: 16),
                      _timeRow(context, c, Icons.wb_twilight, 'Wake up', w, () async {
                        await showTimeSheet(
                          context: context,
                          colors: c,
                          title: 'Wake up',
                          value: b.wake,
                          onSave: (t) => set((bt) => bt.copyWith(wake: t)),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Wake-up settings', style: AppText.muted(c)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.inputBackground.withOpacity(0.6),
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _navRow(c, 'Repeat', repeatLabel(b.days), () async {
                        await showRepeatSheet(
                          context: context,
                          colors: c,
                          days: b.days,
                          onChanged: (days) => set((bt) => bt.copyWith(days: days)),
                        );
                      }),
                      _sep(c),
                      _navRow(c, 'Bedtime reminder', _reminderLabel(b.reminder), () async {
                        await showAppBottomSheetReminder(context, c, b.reminder,
                            (v) => set((bt) => bt.copyWith(reminder: v)));
                      }),
                      _sep(c),
                      _navRow(c, 'Sound', _ringtoneName(b.ringtone), () async {
                        await showSoundSheet(
                          context: context,
                          colors: c,
                          player: state.ringtones,
                          value: b.ringtone,
                          onChanged: (id) => set((bt) => bt.copyWith(ringtone: id)),
                        );
                      }),
                      _sep(c),
                      _navRow(c, 'Wake-up challenge', kChallengeMeta[b.challenge]!.label, () async {
                        await showChallengeSheet(
                          context: context,
                          colors: c,
                          value: b.challenge,
                          onChanged: (ch) => set((bt) => bt.copyWith(challenge: ch)),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: c.inputBackground.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      _toggleRow(c, 'Gradual volume', 'Rises slowly like dawn light', b.gradualVolume,
                          (v) => set((bt) => bt.copyWith(gradualVolume: v))),
                      _sep(c),
                      _toggleRow(c, 'Vibrate when alarm sounds', 'A gentle buzz alongside the tone', b.vibrate,
                          (v) => set((bt) => bt.copyWith(vibrate: v))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'Your wake-up time still greets you with a gentle challenge to help you rise.',
                  style: AppText.muted(c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ringtoneName(String id) {
    const names = {
      'bloom': 'Bloom (default)', 'radar': 'Radar', 'chimes': 'Chimes',
      'reflection': 'Reflection', 'beacon': 'Beacon', 'birds': 'Morning Birds',
      'zen': 'Zen Bell', 'piano': 'Soft Piano',
    };
    return names[id] ?? 'Morning Birds';
  }

  Widget _sep(AppColors c) => Divider(height: 1, color: c.border, indent: 16, endIndent: 16);

  Widget _timeRow(BuildContext context, AppColors c, IconData icon, String label, FormattedTime t, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(radius: 18, backgroundColor: c.calmMist, child: Icon(icon, size: 16, color: c.primary)),
      title: Text(label, style: AppText.body(c, size: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${t.hr}:${t.min} ', style: AppText.body(c, size: 16)),
          Text(t.period, style: AppText.muted(c, size: 12)),
          Icon(Icons.chevron_right, size: 18, color: c.mutedForeground),
        ],
      ),
    );
  }

  Widget _navRow(AppColors c, String label, String value, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: AppText.body(c, size: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(value, overflow: TextOverflow.ellipsis, style: AppText.muted(c)),
          ),
          Icon(Icons.chevron_right, size: 18, color: c.mutedForeground),
        ],
      ),
    );
  }

  Widget _toggleRow(AppColors c, String title, String sub, bool checked, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: checked,
      onChanged: onChanged,
      activeColor: c.primary,
      title: Text(title, style: AppText.body(c, size: 15)),
      subtitle: Text(sub, style: AppText.muted(c)),
    );
  }
}

Future<void> showAppBottomSheetReminder(
    BuildContext context, AppColors c, int value, ValueChanged<int> onChanged) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: c.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(34))),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bedtime reminder', style: AppText.body(c, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._reminderOptions.map((m) => ListTile(
                    title: Text(_reminderLabel(m), style: AppText.body(c)),
                    trailing: value == m ? Icon(Icons.check, color: c.primary) : null,
                    onTap: () {
                      onChanged(m);
                      Navigator.of(ctx).pop();
                    },
                  )),
            ],
          ),
        ),
      );
    },
  );
}
