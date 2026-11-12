// C：página de la pecera: acuario dibujado, la ballenita grande, saciedad,
// tareas de hoy, botones y atribución.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/format.dart';
import '../providers.dart';
import 'whale_controller.dart';
import 'whale_sprite.dart';

class WhaleTankScreen extends ConsumerStatefulWidget {
  const WhaleTankScreen({super.key});

  @override
  ConsumerState<WhaleTankScreen> createState() => _WhaleTankScreenState();
}

class _WhaleTankScreenState extends ConsumerState<WhaleTankScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = ref.watch(whaleProvider);
    final animate = ref.watch(settingsProvider).animations && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_t.isAnimating) _t.repeat();
    if (!animate && _t.isAnimating) _t.stop();
    final snap = ref.watch(snapshotProvider);
    final today = snap.occurrencesOnDay(ref.watch(clockProvider).now());
    final done = today.where((o) => o.completed).length;
    final ctrl = ref.read(whaleProvider.notifier);
    const ink = Color(0xFF1B2559);

    return Scaffold(
      appBar: AppBar(title: Text(l.whaleTitle)),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, _) => CustomPaint(painter: TankPainter(_t.value)),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
              children: [
                const Center(child: WhaleSprite(size: 200)),
                const SizedBox(height: 32),
                Card(
                  color: Colors.white.withValues(alpha: 0.92),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.whaleFullness(v.state.fullness.round()),
                            style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: v.state.fullness / 100,
                            minHeight: 8,
                            color: kWhaleBlue,
                            backgroundColor: const Color(0xFFDDEBFF),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(l.whaleTodayDone(done, today.length), style: const TextStyle(color: ink)),
                        const SizedBox(height: 4),
                        Text(whaleMoodLabel(context, v.mood), style: const TextStyle(color: ink)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.favorite_border),
                            label: Text(l.whalePetButton),
                            onPressed: ctrl.pet,
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.touch_app_outlined),
                            label: Text(l.whalePokeButton),
                            onPressed: ctrl.poke,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.whaleCredits,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Acuario: agua, arena, tres plantas y burbujas que suben ([t] de 0 a 1).
class TankPainter extends CustomPainter {
  TankPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFBFE3FF));
    final sandTop = h * 0.86;
    final sand = Path()
      ..moveTo(0, sandTop)
      ..quadraticBezierTo(w * 0.25, sandTop - 16, w * 0.5, sandTop)
      ..quadraticBezierTo(w * 0.75, sandTop + 16, w, sandTop - 6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(sand, Paint()..color = const Color(0xFFE9D8A6));
    final plant = Paint()..color = const Color(0xFF5FB37C);
    for (final (x, hgt, phase) in [(0.1, 0.22, 0.0), (0.85, 0.3, 0.4), (0.92, 0.18, 0.8)]) {
      final sway = sin((t + phase) * 2 * pi) * 8;
      final px = w * x;
      canvas.drawPath(
        Path()
          ..moveTo(px - 8, sandTop)
          ..quadraticBezierTo(px + sway, sandTop - h * hgt * 0.6, px + sway * 1.5, sandTop - h * hgt)
          ..quadraticBezierTo(px + 4 + sway, sandTop - h * hgt * 0.5, px + 8, sandTop)
          ..close(),
        plant,
      );
    }
    final bubble = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 8; i++) {
      final p = (t + i / 8) % 1.0;
      final x = w * (0.15 + 0.7 * ((i * 37) % 100) / 100) + sin((p + i) * 2 * pi) * 6;
      final y = sandTop - p * sandTop;
      canvas.drawCircle(Offset(x, y), 3 + (i % 3) * 2.0, bubble);
    }
  }

  @override
  bool shouldRepaint(TankPainter old) => old.t != t;
}
