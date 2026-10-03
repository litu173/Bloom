import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/types.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = AppColors.of(state.isDark);
    final type = state.ringingAlarm?.challenge ?? ChallengeType.math;
    final level = state.difficulty;

    String title;
    switch (type) {
      case ChallengeType.math:
        title = 'Three soft sums';
        break;
      case ChallengeType.tap:
        title = 'Follow the blooms';
        break;
      case ChallengeType.puzzle:
        title = 'Which comes next?';
        break;
      case ChallengeType.memory:
        title = 'Remember the number';
        break;
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
          child: Column(
            children: [
              Text('A GENTLE MOMENT', style: AppText.muted(c, size: 13).copyWith(letterSpacing: 3)),
              const SizedBox(height: 8),
              Text(title, style: AppText.serif(c, size: 24)),
              Expanded(
                child: Center(
                  child: switch (type) {
                    ChallengeType.math => _MathGame(level: level, colors: c, onComplete: state.completeChallenge),
                    ChallengeType.tap => _TapGame(level: level, colors: c, onComplete: state.completeChallenge),
                    ChallengeType.puzzle => _PuzzleGame(level: level, colors: c, onComplete: state.completeChallenge),
                    ChallengeType.memory => _MemoryGame(level: level, colors: c, onComplete: state.completeChallenge),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Math ----------------
class _MathGame extends StatefulWidget {
  final int level;
  final AppColors colors;
  final void Function(bool perfect) onComplete;
  const _MathGame({required this.level, required this.colors, required this.onComplete});

  @override
  State<_MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<_MathGame> {
  static const total = 3;
  int round = 0;
  bool firstTry = true;
  int? wrong;
  final rnd = Random();
  late Map<String, dynamic> problem = _make();

  Map<String, dynamic> _make() {
    final cap = [6, 12, 20][widget.level - 1];
    final a = 1 + rnd.nextInt(cap);
    final b = 1 + rnd.nextInt(cap);
    final answer = a + b;
    final options = <int>{answer};
    while (options.length < 4) {
      options.add(max(2, answer + (rnd.nextInt(7) - 3)));
    }
    final list = options.toList()..shuffle();
    return {'a': a, 'b': b, 'answer': answer, 'options': list};
  }

  void choose(int o) {
    if (o == problem['answer']) {
      setState(() => wrong = null);
      if (round + 1 >= total) {
        widget.onComplete(firstTry);
      } else {
        setState(() {
          round++;
          problem = _make();
        });
      }
    } else {
      setState(() {
        wrong = o;
        firstTry = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == round ? 24 : 8,
              height: 6,
              decoration: BoxDecoration(
                color: i < round ? c.calmRose : (i == round ? c.calmPink : c.border),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text('${problem['a']} + ${problem['b']}', style: AppText.serif(c, size: 48)),
        const SizedBox(height: 32),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: (problem['options'] as List<int>).map((o) {
            return GestureDetector(
              onTap: () => choose(o),
              child: Container(
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: wrong == o ? c.destructive : c.border),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text('$o', style: AppText.body(c, size: 26)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text("Take your time. There's no rush.", style: AppText.muted(c)),
      ],
    );
  }
}

// ---------------- Memory ----------------
class _MemoryGame extends StatefulWidget {
  final int level;
  final AppColors colors;
  final void Function(bool perfect) onComplete;
  const _MemoryGame({required this.level, required this.colors, required this.onComplete});

  @override
  State<_MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<_MemoryGame> {
  late final digits = widget.level >= 3 ? 5 : 4;
  late final target = List.generate(digits, (_) => Random().nextInt(10)).join();
  bool showing = true;
  int count = 3;
  String entry = '';
  bool shake = false;
  bool firstTry = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    timer = Timer(const Duration(seconds: 1), () {
      if (count <= 0) {
        setState(() => showing = false);
        return;
      }
      setState(() => count--);
      _tick();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void press(String d) {
    if (entry.length >= digits) return;
    final next = entry + d;
    setState(() => entry = next);
    if (next.length == digits) {
      if (next == target) {
        Future.delayed(const Duration(milliseconds: 250), () => widget.onComplete(firstTry));
      } else {
        firstTry = false;
        setState(() => shake = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            shake = false;
            entry = '';
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    if (showing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Hold this in mind…', style: AppText.muted(c)),
          const SizedBox(height: 20),
          Text(target, style: AppText.serif(c, size: 48)),
          const SizedBox(height: 24),
          CircleAvatar(radius: 20, backgroundColor: c.accent, child: Text('$count', style: AppText.body(c, color: c.primary))),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Type what you remember', style: AppText.muted(c)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(digits, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 44,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: i == entry.length ? c.calmRose : c.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(i < entry.length ? entry[i] : '', style: AppText.body(c, size: 26)),
            );
          }),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 280,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              for (final n in ['1','2','3','4','5','6','7','8','9'])
                _key(c, n, () => press(n)),
              const SizedBox.shrink(),
              _key(c, '0', () => press('0')),
              _key(c, '⌫', () => setState(() => entry = entry.isEmpty ? entry : entry.substring(0, entry.length - 1)), muted: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _key(AppColors c, String label, VoidCallback onTap, {bool muted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(label, style: AppText.body(c, size: 22, color: muted ? c.mutedForeground : c.foreground)),
      ),
    );
  }
}

// ---------------- Tap ----------------
class _TapGame extends StatefulWidget {
  final int level;
  final AppColors colors;
  final void Function(bool perfect) onComplete;
  const _TapGame({required this.level, required this.colors, required this.onComplete});

  @override
  State<_TapGame> createState() => _TapGameState();
}

class _TapGameState extends State<_TapGame> {
  late final count = [3, 4, 5][widget.level - 1];
  late final seq = List.generate(count, (_) => Random().nextInt(4));
  String phase = 'show';
  int active = -1;
  int pos = 0;
  bool firstTry = true;

  static const colors = [Color(0xFFF2506E), Color(0xFFC98AA0), Color(0xFFFF8AA3), Color(0xFF8F3350)];

  @override
  void initState() {
    super.initState();
    _playSequence();
  }

  Future<void> _playSequence() async {
    for (final i in seq) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() => active = i);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => active = -1);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => phase = 'input');
  }

  void tap(int i) {
    if (phase != 'input') return;
    setState(() => active = i);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => active = -1);
    });
    if (seq[pos] == i) {
      final np = pos + 1;
      setState(() => pos = np);
      if (np >= seq.length) {
        setState(() => phase = 'done');
        Future.delayed(const Duration(milliseconds: 400), () => widget.onComplete(firstTry));
      }
    } else {
      firstTry = false;
      setState(() => pos = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(phase == 'show' ? 'Watch the blooms glow…' : 'Now, tap them in order', style: AppText.muted(c)),
        const SizedBox(height: 28),
        SizedBox(
          width: 260,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: List.generate(4, (i) {
              return GestureDetector(
                onTap: () => tap(i),
                child: AnimatedOpacity(
                  opacity: active == i ? 1 : 0.55,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i],
                      boxShadow: active == i
                          ? [BoxShadow(color: colors[i], blurRadius: 24)]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(seq.length, (i) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < pos ? c.calmRose : c.border,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ---------------- Puzzle ----------------
class _PuzzleGame extends StatefulWidget {
  final int level;
  final AppColors colors;
  final void Function(bool perfect) onComplete;
  const _PuzzleGame({required this.level, required this.colors, required this.onComplete});

  @override
  State<_PuzzleGame> createState() => _PuzzleGameState();
}

class _PuzzleGameState extends State<_PuzzleGame> {
  static const palette = [Color(0xFFF2506E), Color(0xFFFF8AA3), Color(0xFFC98AA0)];
  late final patternLen = [2, 3, 3][widget.level - 1];
  late List<int> pattern;
  late List<int> shown;
  late int answer;
  late List<int> options;
  int? wrong;
  bool firstTry = true;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    pattern = List.generate(patternLen, (_) => rnd.nextInt(palette.length));
    shown = [...pattern, ...pattern, pattern[0]];
    answer = pattern[1 % pattern.length];
    final opts = <int>{answer};
    while (opts.length < min(3, palette.length)) {
      opts.add(rnd.nextInt(palette.length));
    }
    options = opts.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final p in shown)
              Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: palette[p])),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: c.border, width: 2, style: BorderStyle.solid),
              ),
              child: Text('?', style: AppText.muted(c)),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Choose the bloom that continues the pattern', style: AppText.muted(c)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: options.map((o) {
            return GestureDetector(
              onTap: () {
                if (o == answer) {
                  widget.onComplete(firstTry);
                } else {
                  setState(() {
                    wrong = o;
                    firstTry = false;
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette[o],
                  border: wrong == o ? Border.all(color: c.destructive, width: 2) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
