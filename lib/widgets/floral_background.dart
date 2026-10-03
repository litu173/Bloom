import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FloralBackground extends StatefulWidget {
  final bool petals;
  const FloralBackground({super.key, this.petals = false});

  @override
  State<FloralBackground> createState() => _FloralBackgroundState();
}

class _FloralBackgroundState extends State<FloralBackground>
    with TickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -1),
                    radius: 1.3,
                    colors: [
                      const Color(0xFFF2506E).withOpacity(0.16),
                      const Color(0xFFF2506E).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, 1),
                    radius: 1.3,
                    colors: [
                      const Color(0xFF8F3350).withOpacity(0.22),
                      const Color(0xFF8F3350).withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -32,
              child: _bloom(224, const Color(0xFFF2506E), 0.16),
            ),
            Positioned(
              bottom: -48,
              left: -40,
              child: _bloom(256, const Color(0xFF8F3350), 0.14),
            ),
            if (widget.petals) ..._petals(),
          ],
        ),
      ),
    );
  }

  Widget _bloom(double size, Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, child) => Transform.rotate(
          angle: _spin.value * 2 * math.pi,
          child: child,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _BloomPainter(color)),
        ),
      ),
    );
  }

  List<Widget> _petals() {
    return List.generate(6, (i) {
      final left = 8.0 + i * 15;
      final delay = i * 1.4;
      return Positioned(
        left: 0,
        right: 0,
        bottom: -24,
        child: FractionallySizedBox(
          widthFactor: 1,
          child: Align(
            alignment: Alignment(-1 + left / 50, 0),
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, child) {
                final t = ((_drift.value * 10 + delay) % (9 + i)) / (9 + i);
                return Opacity(
                  opacity: t < 0.1 || t > 0.9 ? 0 : 0.6,
                  child: Transform.translate(
                    offset: Offset(0, -t * 120),
                    child: Transform.rotate(angle: t * 40 * math.pi / 180, child: child),
                  ),
                );
              },
              child: Container(
                width: 10 + (i % 3) * 4,
                height: 14 + (i % 3) * 4,
                decoration: BoxDecoration(
                  color: i.isOdd ? const Color(0xFFF2506E) : const Color(0xFFC98AA0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _BloomPainter extends CustomPainter {
  final Color color;
  _BloomPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color;
    for (final deg in [0, 60, 120, 180, 240, 300]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(deg * math.pi / 180);
      final petal = Rect.fromCenter(
        center: Offset(0, -size.height * 0.22),
        width: size.width * 0.26,
        height: size.height * 0.44,
      );
      canvas.drawOval(petal, paint);
      canvas.restore();
    }
    canvas.drawCircle(center, size.width * 0.1, Paint()..color = const Color(0xFF191115));
  }

  @override
  bool shouldRepaint(covariant _BloomPainter oldDelegate) => oldDelegate.color != color;
}
