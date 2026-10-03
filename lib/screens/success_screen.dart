import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/gamification.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/floral_background.dart';

const _affirmations = [
  "You're awake, and that's enough.",
  'The day will meet you gently.',
  'One soft step at a time.',
  'You showed up for yourself today.',
];

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final line = _affirmations[Random().nextInt(_affirmations.length)];

    return Stack(
      children: [
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: c.background))),
        const Positioned.fill(child: FloralBackground(petals: true)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bloomBadge(),
                const SizedBox(height: 32),
                Text('Good morning', style: AppText.serif(c, size: 28)),
                const SizedBox(height: 12),
                Text(line, textAlign: TextAlign.center, style: AppText.muted(c, size: 15)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.card.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌸 ${state.stats.streak} in bloom', style: AppText.body(c)),
                      Container(width: 1, height: 16, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Text('+${state.lastXp} XP', style: AppText.body(c, color: c.primary, weight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (state.lastPerfect) ...[
                  const SizedBox(height: 8),
                  Text('Clear-minded on the first try · ${levelName(state)}',
                      style: AppText.body(c, size: 13, color: c.calmGreen)),
                ],
                if (state.lastBadge != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.primary.withOpacity(0.1),
                      border: Border.all(color: c.primary.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events, size: 16, color: c.primary),
                        const SizedBox(width: 8),
                        Text('New achievement · ${state.lastBadge}', style: AppText.body(c, size: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: state.finishSuccess,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(30)),
                    child: Text('Start the day', style: AppText.body(c, color: c.primaryForeground)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String levelName(AppState state) => levelInfo(state.stats.xp).name;

  Widget _bloomBadge() {
    return SizedBox(
      width: 128,
      height: 128,
      child: CustomPaint(painter: _BadgePainter()),
    );
  }
}

class _BadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 8; i++) {
      final deg = i * 45;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(deg * pi / 180);
      final rect = Rect.fromCenter(center: Offset(0, -size.height * 0.24), width: size.width * 0.22, height: size.height * 0.4);
      canvas.drawOval(rect, Paint()..color = deg % 90 == 0 ? const Color(0xFFF2506E) : const Color(0xFFC98AA0));
      canvas.restore();
    }
    canvas.drawCircle(center, size.width * 0.12, Paint()..color = const Color(0xFFFF8AA3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
