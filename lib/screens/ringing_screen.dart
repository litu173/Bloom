import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/floral_background.dart';

class RingingScreen extends StatefulWidget {
  const RingingScreen({super.key});

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final alarm = state.ringingAlarm;
    if (alarm == null) return const SizedBox.shrink();
    final t = formatTime(alarm.time);

    return Stack(
      children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: c.background))),
        const Positioned.fill(child: FloralBackground()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text('${alarm.label.toUpperCase()} · SOFTLY',
                        style: AppText.muted(c, size: 13).copyWith(letterSpacing: 3)),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: AppText.serif(c, size: 56),
                        children: [
                          TextSpan(text: '${t.hr}:${t.min}'),
                          TextSpan(text: '  ${t.period}', style: AppText.muted(c, size: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final r in [0, 1, 2])
                        AnimatedBuilder(
                          animation: _breathe,
                          builder: (context, child) {
                            final scale = 1 + _breathe.value * 0.12;
                            return Opacity(
                              opacity: 0.4 + (1 - _breathe.value) * 0.3,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 180.0 + r * 46,
                                  height: 180.0 + r * 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: r.isOdd
                                        ? const Color(0xFFC98AA0).withOpacity(0.18)
                                        : const Color(0xFFF2506E).withOpacity(0.20),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      GestureDetector(
                        onTap: state.beginChallenge,
                        child: Container(
                          width: 160,
                          height: 160,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF2506E), Color(0xFF8F3350)],
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFF2506E).withOpacity(0.45), blurRadius: 60),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Begin', style: TextStyle(color: Colors.white, fontSize: 18)),
                              SizedBox(height: 2),
                              Text('breathe in', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: state.snoozesLeft > 0 ? state.snooze : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          state.snoozesLeft > 0 ? 'Rest a little more · ${state.snoozesLeft} left' : 'No more snoozes today',
                          style: AppText.muted(c),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("Each snooze trims tomorrow's streak, gently.",
                        style: AppText.muted(c, size: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
