// Pantalla vacía (v2): el habitante en un círculo suave con un icono del tema
// (bandeja, lupa, diario…) y el texto debajo. Todo dibujado en código.

import 'package:flutter/material.dart';

import '../../domain/villager/villager_mood.dart';
import '../village/villager_painter.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.mood = VillagerMood.normal,
    this.action,
    this.size = 132,
  });

  final IconData icon;
  final String text;
  final VillagerMood mood;
  final Widget? action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox.square(
            dimension: size,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.6), shape: BoxShape.circle),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _VillagerArt(mood)),
              ),
              Positioned(
                right: 0,
                top: size * 0.06,
                child: Container(
                  padding: EdgeInsets.all(size * 0.07),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 6)],
                  ),
                  child: Icon(icon, size: size * 0.2, color: scheme.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]),
      ),
    );
  }
}

class _VillagerArt extends CustomPainter {
  _VillagerArt(this.mood);
  final VillagerMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Offset.zero & size));
    paintVillager(canvas, Offset(size.width / 2, size.height * 0.88), size.height * 0.68, mood);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VillagerArt old) => old.mood != mood;
}
