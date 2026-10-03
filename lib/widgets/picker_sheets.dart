import 'package:flutter/material.dart';
import '../models/types.dart';
import '../services/ringtones.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_bottom_sheet.dart';
import 'wheel_picker.dart';

Future<void> showRepeatSheet({
  required BuildContext context,
  required AppColors colors,
  required List<int> days,
  required ValueChanged<List<int>> onChanged,
}) {
  return showAppBottomSheet(
    context: context,
    colors: colors,
    title: 'Repeat',
    builder: (ctx) => _RepeatSheetBody(colors: colors, days: days, onChanged: onChanged),
  );
}

class _RepeatSheetBody extends StatefulWidget {
  final AppColors colors;
  final List<int> days;
  final ValueChanged<List<int>> onChanged;
  const _RepeatSheetBody({required this.colors, required this.days, required this.onChanged});

  @override
  State<_RepeatSheetBody> createState() => _RepeatSheetBodyState();
}

class _RepeatSheetBodyState extends State<_RepeatSheetBody> {
  late List<int> days = [...widget.days];

  static const presets = [
    ['Once', <int>[]],
    ['Daily', [0, 1, 2, 3, 4, 5, 6]],
    ['Monday to Friday', [1, 2, 3, 4, 5]],
  ];

  bool _matches(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  void _set(List<int> d) {
    setState(() => days = d);
    widget.onChanged(d);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.inputBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < presets.length; i++) ...[
                if (i > 0) Divider(height: 1, color: c.border, indent: 16, endIndent: 16),
                ListTile(
                  onTap: () => _set(presets[i][1] as List<int>),
                  title: Text(presets[i][0] as String, style: AppText.body(c)),
                  trailing: _matches(days, presets[i][1] as List<int>)
                      ? Icon(Icons.check, color: c.primary, size: 20)
                      : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Customize week', style: AppText.muted(c)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (d) {
            final on = days.contains(d);
            return GestureDetector(
              onTap: () => _set(on ? days.where((x) => x != d).toList() : [...days, d]),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? c.calmPink : c.inputBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  kDayLabelsLong[d].substring(0, 1),
                  style: AppText.body(c, color: on ? Colors.white : c.mutedForeground),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

Future<void> showSoundSheet({
  required BuildContext context,
  required AppColors colors,
  required RingtoneService player,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return showAppBottomSheet(
    context: context,
    colors: colors,
    title: 'Sound',
    builder: (ctx) => _SoundSheetBody(colors: colors, player: player, value: value, onChanged: onChanged),
  );
}

class _SoundSheetBody extends StatefulWidget {
  final AppColors colors;
  final RingtoneService player;
  final String value;
  final ValueChanged<String> onChanged;
  const _SoundSheetBody({
    required this.colors,
    required this.player,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SoundSheetBody> createState() => _SoundSheetBodyState();
}

class _SoundSheetBodyState extends State<_SoundSheetBody> {
  late String value = widget.value;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in [RingtoneGroup.system, RingtoneGroup.device]) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              group == RingtoneGroup.system ? 'SYSTEM' : 'DEVICE',
              style: AppText.muted(c, size: 11),
            ),
          ),
          ...kRingtones.where((r) => r.group == group).map((r) {
            final on = value == r.id;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: on ? c.calmMist : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: GestureDetector(
                  onTap: () => widget.player.preview(r.id),
                  child: CircleAvatar(
                    backgroundColor: c.accent,
                    child: Icon(Icons.play_arrow, size: 18, color: c.primary),
                  ),
                ),
                title: Text(r.name, style: AppText.body(c)),
                trailing: on ? Icon(Icons.check, color: c.primary, size: 18) : null,
                onTap: () {
                  setState(() => value = r.id);
                  widget.onChanged(r.id);
                  widget.player.preview(r.id);
                },
              ),
            );
          }),
        ],
      ],
    );
  }
}

Future<void> showChallengeSheet({
  required BuildContext context,
  required AppColors colors,
  required ChallengeType value,
  required ValueChanged<ChallengeType> onChanged,
}) {
  return showAppBottomSheet(
    context: context,
    colors: colors,
    title: 'Wake-up challenge',
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Column(
          children: ChallengeType.values.map((ch) {
            final on = value == ch;
            final meta = kChallengeMeta[ch]!;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: on ? colors.calmMist : Colors.transparent,
                border: Border.all(color: on ? colors.calmRose : colors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {});
                  onChanged(ch);
                },
                title: Text(meta.label, style: AppText.body(colors)),
                subtitle: Text(meta.blurb, style: AppText.muted(colors)),
                trailing: on
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: colors.calmRose,
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      });
    },
  );
}

Future<void> showTimeSheet({
  required BuildContext context,
  required AppColors colors,
  required String title,
  required String value,
  required ValueChanged<String> onSave,
}) {
  return showAppBottomSheet(
    context: context,
    colors: colors,
    title: title,
    rightAction: null,
    builder: (ctx) => _TimeSheetBody(colors: colors, value: value, onSave: (t) {
      onSave(t);
      Navigator.of(ctx).pop();
    }),
  );
}

class _TimeSheetBody extends StatefulWidget {
  final AppColors colors;
  final String value;
  final ValueChanged<String> onSave;
  const _TimeSheetBody({required this.colors, required this.value, required this.onSave});

  @override
  State<_TimeSheetBody> createState() => _TimeSheetBodyState();
}

class _TimeSheetBodyState extends State<_TimeSheetBody> {
  late String time = widget.value;

  static const hours = [
    '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'
  ];
  static final minutes = List.generate(60, (i) => i.toString().padLeft(2, '0'));
  static const periods = ['AM', 'PM'];

  void _setPart(String part, String v) {
    final parts = time.split(':').map(int.parse).toList();
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
    setState(() => time = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final parts = time.split(':').map(int.parse).toList();
    final hour12 = (((parts[0] + 11) % 12) + 1).toString().padLeft(2, '0');
    final period = parts[0] >= 12 ? 'PM' : 'AM';
    return Column(
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => widget.onSave(time),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
