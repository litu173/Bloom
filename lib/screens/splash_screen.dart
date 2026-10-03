import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bloom's animated launch experience — shown once after the Flutter engine
/// starts (the *native* OS launch screen before this should stay minimal
/// per Apple HIG; see SPLASH_SCREEN.md for the split between the native
/// launch screen and this in-app splash).
///
/// Sequence: soft glow breathes in → five notched cherry-blossom petals
/// bloom outward in a staggered sequence → gold heart settles into the
/// center → the "Bl🌸🌸m" wordmark fades/rises in, with its two "o"s replaced
/// by the same flower mark, spinning continuously and smoothly → brief hold
/// → calls [onFinished] so the caller can transition to the real app.
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  // Continuous, independent, never-stopping rotation for the wordmark's
  // flower glyphs — deliberately its own controller so it keeps spinning
  // smoothly regardless of the intro timeline above.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  late final Animation<double> _glow = CurvedAnimation(
    parent: _c, curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
  );
  late final Animation<double> _petals = CurvedAnimation(
    parent: _c, curve: const Interval(0.08, 0.60, curve: Curves.elasticOut),
  );
  late final Animation<double> _heart = CurvedAnimation(
    parent: _c, curve: const Interval(0.50, 0.72, curve: Curves.easeOutBack),
  );
  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _c, curve: const Interval(0.58, 0.86, curve: Curves.easeOut),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _c, curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), widget.onFinished);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191115),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.1,
            colors: [Color(0xFF4A2E2E), Color(0xFF191115)],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _spin]),
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: _BlossomPainter(
                      glow: _glow.value,
                      petals: _petals.value.clamp(0, 1),
                      heart: _heart.value.clamp(0, 1),
                      spin: _spin.value,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Opacity(
                  opacity: _wordmark.value.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - _wordmark.value.clamp(0, 1))),
                    child: _Wordmark(spinTurns: _spin.value),
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: _tagline.value.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - _tagline.value.clamp(0, 1))),
                    child: Text(
                      'gentle mornings, one bloom at a time',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBD97A2),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Bl🌸🌸m" — the wordmark with both letterforms of "o" replaced by the
/// flower mark, each spinning smoothly and continuously in place.
class _Wordmark extends StatelessWidget {
  final double spinTurns; // 0..1 repeating, from the parent's spin controller
  const _Wordmark({required this.spinTurns});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.fraunces(
      fontSize: 44,
      fontWeight: FontWeight.w500,
      color: const Color(0xFFF4E9EC),
      height: 1.0,
    );
    // Sized to roughly match the "o" it replaces at this font size.
    const glyphSize = 34.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Bl', style: style),
        Transform.rotate(
          angle: spinTurns * 2 * math.pi,
          child: SizedBox(
            width: glyphSize,
            height: glyphSize,
            child: CustomPaint(painter: _BlossomPainter(glow: 0, petals: 1, heart: 1, spin: 0)),
          ),
        ),
        const SizedBox(width: 2),
        Transform.rotate(
          angle: spinTurns * 2 * math.pi,
          child: SizedBox(
            width: glyphSize,
            height: glyphSize,
            child: CustomPaint(painter: _BlossomPainter(glow: 0, petals: 1, heart: 1, spin: 0)),
          ),
        ),
        const SizedBox(width: 2),
        Text('m', style: style),
      ],
    );
  }
}

/// The cherry-blossom mark itself: 5 notched petals (each a rounded lobe
/// with a small cleft at its outer tip, like a sakura petal) around a warm
/// gold heart. Same geometry as assets/splash/flower.svg, kept in sync by
/// hand — see that file if you ever need to edit the petal shape.
class _BlossomPainter extends CustomPainter {
  final double glow;   // 0..1 ambient glow fade-in (splash intro only)
  final double petals; // 0..1 bloom-in progress
  final double heart;  // 0..1 center settle-in progress
  final double spin;   // 0..1 repeating — unused here (rotation applied by parent), kept for API symmetry

  _BlossomPainter({required this.glow, required this.petals, required this.heart, required this.spin});

  static const petalA1 = Color(0xFFFDEDF1);
  static const petalA2 = Color(0xFFFF9AB3);
  static const petalB1 = Color(0xFFFF9AB3);
  static const petalB2 = Color(0xFFE8637F);
  static const strokeColor = Color(0x47D9536F);
  static const goldIn = Color(0xFFFFE9C2);
  static const goldOut = Color(0xFFFFC773);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.min(size.width, size.height);

    if (glow > 0) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFF8AA3).withOpacity(0.28 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxDim * 0.14);
      canvas.drawCircle(center, maxDim * 0.5 * glow, glowPaint);
    }

    for (var i = 0; i < 5; i++) {
      final deg = i * 72.0;
      final delay = (i * 0.09).clamp(0.0, 0.5);
      final t = ((petals - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final isA = i.isEven;
      _drawPetal(
        canvas, center, maxDim,
        angleDeg: deg,
        gradStart: isA ? petalA1 : petalB1,
        gradEnd: isA ? petalA2 : petalB2,
        scale: t,
      );
    }

    if (heart > 0) {
      final r = maxDim * 0.155 * heart;
      final shader = const RadialGradient(colors: [goldIn, goldOut]).createShader(
        Rect.fromCircle(center: center, radius: r),
      );
      canvas.drawCircle(center, r, Paint()..shader = shader);
    }
  }

  /// Petal outline via 4 cubic bezier segments forming a rounded lobe with a
  /// notch (cleft) at its outer tip — matches flower.svg's `#petal` path,
  /// normalized so the farthest point sits at distance 1.0 from the base.
  void _drawPetal(
    Canvas canvas,
    Offset center,
    double maxDim, {
    required double angleDeg,
    required Color gradStart,
    required Color gradEnd,
    required double scale,
  }) {
    final r = maxDim * 0.5 * scale;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleDeg * math.pi / 180);

    Offset p(double x, double y) => Offset(x * r, y * r);

    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(p(-0.176, -0.235).dx, p(-0.176, -0.235).dy, p(-0.4, -0.529).dx, p(-0.4, -0.529).dy, p(-0.318, -1.0).dx, p(-0.318, -1.0).dy)
      ..cubicTo(p(-0.235, -1.118).dx, p(-0.235, -1.118).dy, p(-0.118, -1.0).dx, p(-0.118, -1.0).dy, p(0, -0.824).dx, p(0, -0.824).dy)
      ..cubicTo(p(0.118, -1.0).dx, p(0.118, -1.0).dy, p(0.235, -1.118).dx, p(0.235, -1.118).dy, p(0.318, -1.0).dx, p(0.318, -1.0).dy)
      ..cubicTo(p(0.4, -0.529).dx, p(0.4, -0.529).dy, p(0.176, -0.235).dx, p(0.176, -0.235).dy, 0.0, 0.0)
      ..close();

    final bounds = path.getBounds();
    final shader = RadialGradient(
      center: const Alignment(0, 0.85),
      radius: 0.85,
      colors: [gradStart, gradEnd],
    ).createShader(bounds);

    canvas.drawPath(path, Paint()..shader = shader);
    canvas.drawPath(path, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = maxDim * 0.006);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlossomPainter old) =>
      old.glow != glow || old.petals != petals || old.heart != heart || old.spin != spin;
}
