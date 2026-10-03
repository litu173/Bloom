import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

const _messages = [
  'Let the day settle. You did enough.',
  'Slow your breath. In for four, out for four.',
  'Dim the lights and let your eyes rest.',
  'Tomorrow can wait. This moment is for rest.',
  'Soften your shoulders. Unclench your jaw.',
];

const _tips = [
  [Icons.notifications_off_outlined, 'Silence your phone or turn on Do Not Disturb'],
  [Icons.wifi_off, 'Set the internet aside — nothing more to check tonight'],
  [Icons.dark_mode_outlined, 'Lower your screen brightness to the softest glow'],
];

class WindDownScreen extends StatefulWidget {
  const WindDownScreen({super.key});

  @override
  State<WindDownScreen> createState() => _WindDownScreenState();
}

class _WindDownScreenState extends State<WindDownScreen> with SingleTickerProviderStateMixin {
  int msg = 0;
  Timer? timer;
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      setState(() => msg = (msg + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final w = formatTime(state.bedtime.wake);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _breathe,
                      builder: (context, child) => Transform.scale(
                        scale: 1 + _breathe.value * 0.08,
                        child: child,
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: c.calmMist,
                        child: Icon(Icons.nights_stay_outlined, size: 48, color: c.primary),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('Time to wind down', style: AppText.serif(c, size: 28)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _messages[msg],
                          key: ValueKey(msg),
                          textAlign: TextAlign.center,
                          style: AppText.muted(c),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: _tips
                      .map((t) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: c.card.withOpacity(0.6),
                              border: Border.all(color: c.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 16, backgroundColor: c.calmMist, child: Icon(t[0] as IconData, size: 15, color: c.primary)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(t[1] as String, style: AppText.muted(c))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wb_twilight, size: 16, color: c.primary),
                        const SizedBox(width: 6),
                        Text('Wake-up set for ${w.hr}:${w.min} ${w.period}', style: AppText.muted(c)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => state.setView(AppView.home),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('Good night', style: AppText.body(c, color: c.primaryForeground, size: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
