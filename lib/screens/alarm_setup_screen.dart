import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/picker_sheets.dart';
import '../widgets/wheel_picker.dart';

class AlarmSetupScreen extends StatefulWidget {
  final Alarm? initial;
  const AlarmSetupScreen({super.key, this.initial});

  @override
  State<AlarmSetupScreen> createState() => _AlarmSetupScreenState();
}

class _AlarmSetupScreenState extends State<AlarmSetupScreen> {
  late Alarm draft = widget.initial ??
      Alarm(time: '07:00', label: defaultLabelForDays([1, 2, 3, 4, 5]), days: const [1, 2, 3, 4, 5]);
  late final labelController = TextEditingController(text: draft.label);

  static const hours = ['01','02','03','04','05','06','07','08','09','10','11','12'];
  static final minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));
  static const periods = ['AM', 'PM'];

  void _setPart(String part, String v) {
    final parts = draft.time.split(':').map(int.parse).toList();
    var h = parts[0];
    var m = parts[1];
    final hour12 = (((h + 11) % 12) + 1).toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    if (part == 'm') m = int.parse(v);
    if (part == 'h' || part == 'p') {
      final hr12 = part == 'h' ? int.parse(v) : int.parse(hour12);
      final per = part == 'p' ? v : period;
      h = (hr12 % 12) + (per == 'PM' ? 12 : 0);
    }
    setState(() => draft = draft.copyWith(time: '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final c = AppColors.of(context.watch<AppState>().isDark);
    final parts = draft.time.split(':').map(int.parse).toList();
    final hour12 = (((parts[0] + 11) % 12) + 1).toString().padLeft(2, '0');
    final period = parts[0] >= 12 ? 'PM' : 'AM';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AppText.body(c, color: c.primary)),
        ),
        title: Text(widget.initial != null ? 'Edit Alarm' : 'Add Alarm', style: AppText.body(c, weight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              state.saveAlarm(draft.copyWith(label: labelController.text));
              Navigator.of(context).pop();
            },
            child: Text('Save', style: AppText.body(c, color: c.primary, weight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    WheelPicker(items: hours, value: hour12, colors: c, onChanged: (v) => _setPart('h', v)),
                    Text(':', style: AppText.serif(c, size: 26, color: c.mutedForeground)),
                    WheelPicker(
                      items: minutes,
                      value: parts[1].toString().padLeft(2, '0'),
                      colors: c,
                      onChanged: (v) => _setPart('m', v),
                    ),
                    WheelPicker(items: periods, value: period, colors: c, onChanged: (v) => _setPart('p', v)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: c.inputBackground.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text('Label', style: AppText.muted(c)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: labelController,
                        textAlign: TextAlign.right,
                        maxLength: 30,
                        style: AppText.body(c),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: defaultLabelForDays(draft.days),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: c.inputBackground.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _navRow(c, 'Repeat', repeatLabel(draft.days), () async {
                      await showRepeatSheet(
                        context: context,
                        colors: c,
                        days: draft.days,
                        onChanged: (days) {
                          final wasAuto = kAutoLabels.contains(labelController.text.trim()) ||
                              labelController.text.trim().isEmpty;
                          setState(() {
                            draft = draft.copyWith(days: days);
                            if (wasAuto) labelController.text = defaultLabelForDays(days);
                          });
                        },
                      );
                    }),
                    _divider(c),
                    _navRow(c, 'Sound', getRingtoneName(draft.ringtone), () async {
                      await showSoundSheet(
                        context: context,
                        colors: c,
                        player: state.ringtones,
                        value: draft.ringtone,
                        onChanged: (id) => setState(() => draft = draft.copyWith(ringtone: id)),
                      );
                    }),
                    _divider(c),
                    _navRow(c, 'Wake-up challenge', kChallengeMeta[draft.challenge]!.label, () async {
                      await showChallengeSheet(
                        context: context,
                        colors: c,
                        value: draft.challenge,
                        onChanged: (ch) => setState(() => draft = draft.copyWith(challenge: ch)),
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
                    _toggleRow(c, 'Soft pre-alarm', 'A whisper of sound 5 min early', draft.preAlarm,
                        (v) => setState(() => draft = draft.copyWith(preAlarm: v))),
                    _divider(c),
                    _toggleRow(c, 'Gradual volume', 'Rises slowly like dawn light', draft.gradualVolume,
                        (v) => setState(() => draft = draft.copyWith(gradualVolume: v))),
                    _divider(c),
                    _toggleRow(c, 'Vibrate when alarm sounds', 'A gentle buzz alongside the tone', draft.vibrate,
                        (v) => setState(() => draft = draft.copyWith(vibrate: v))),
                    _divider(c),
                    _toggleRow(c, 'Delete after alarm goes off', 'Remove this alarm once it rings', draft.deleteAfter,
                        (v) => setState(() => draft = draft.copyWith(deleteAfter: v))),
                  ],
                ),
              ),
              if (widget.initial != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: c.inputBackground.withOpacity(0.6),
                      foregroundColor: c.destructive,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      state.deleteAlarm(widget.initial!.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete Alarm'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String getRingtoneName(String id) {
    // Avoids importing ringtones.dart's full model here to keep this screen slim.
    const names = {
      'bloom': 'Bloom (default)',
      'radar': 'Radar',
      'chimes': 'Chimes',
      'reflection': 'Reflection',
      'beacon': 'Beacon',
      'birds': 'Morning Birds',
      'zen': 'Zen Bell',
      'piano': 'Soft Piano',
    };
    return names[id] ?? 'Bloom (default)';
  }

  Widget _divider(AppColors c) => Divider(height: 1, color: c.border);

  Widget _navRow(AppColors c, String label, String value, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: AppText.body(c)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(value,
                overflow: TextOverflow.ellipsis, style: AppText.muted(c), textAlign: TextAlign.right),
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
