// RF-42: celebración breve al completar todas las tareas del día.
import 'dart:math';

import 'package:flutter/material.dart';

import 'actions.dart';
import 'format.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.child});
  final Widget child;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  final _rand = Random();
  List<_Piece> _pieces = const [];

  @override
  void initState() {
    super.initState();
    celebrationTick.addListener(_play);
  }

  @override
  void dispose() {
    celebrationTick.removeListener(_play);
    _c.dispose();
    super.dispose();
  }

  void _play() {
    const colors = [Colors.red, Colors.amber, Colors.green, Colors.blue, Colors.purple, Colors.pink];
    setState(() {
      _pieces = List.generate(
        80,
        (_) => _Piece(
          x: _rand.nextDouble(),
          speed: 0.6 + _rand.nextDouble() * 0.8,
          drift: (_rand.nextDouble() - 0.5) * 0.3,
          size: 5 + _rand.nextDouble() * 6,
          color: colors[_rand.nextInt(colors.length)],
          spin: _rand.nextDouble() * 6,
        ),
      );
    });
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              if (!_c.isAnimating) return const SizedBox.shrink();
              final t = _c.value;
              return Stack(
                children: [
                  CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, t)),
                  Center(
                    child: Opacity(
                      opacity: (t < 0.15 ? t / 0.15 : (t > 0.8 ? (1 - t) / 0.2 : 1.0)).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.8 + 0.2 * Curves.elasticOut.transform(t.clamp(0, 1)),
                        child: Material(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                          elevation: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.celebration, size: 32),
                                const SizedBox(width: 12),
                                Text(context.l10n.allDoneCelebration,
                                    style: Theme.of(context).textTheme.titleLarge),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Piece {
  const _Piece({required this.x, required this.speed, required this.drift, required this.size, required this.color, required this.spin});
  final double x, speed, drift, size, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final y = -20 + (size.height + 40) * (t * p.speed);
      final x = size.width * (p.x + p.drift * t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t * 6);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          Paint()..color = p.color.withValues(alpha: 1 - t * 0.5));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
