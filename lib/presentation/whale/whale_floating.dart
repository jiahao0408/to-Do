// A：la ballenita flotando en una esquina del calendario. Se puede arrastrar;
// al soltar se pega al borde izquierdo o derecho y recuerda la posición.
// Va dentro de un Stack que cubre la zona del calendario.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../providers.dart';
import 'whale_sprite.dart';

class WhaleFloating extends ConsumerStatefulWidget {
  const WhaleFloating({super.key, required this.hidden});

  /// Selección múltiple, panel de bandeja abierto…
  final bool hidden;

  static const double size = 72;
  static const double margin = 12;

  @override
  ConsumerState<WhaleFloating> createState() => _WhaleFloatingState();
}

class _WhaleFloatingState extends ConsumerState<WhaleFloating> {
  Offset? _drag;

  /// Posición recién soltada, hasta que llegue a los ajustes.
  (bool right, double frac)? _local;

  (bool right, double frac) _parse(String? raw) {
    final parts = (raw ?? '').split(':');
    final right = parts.isNotEmpty && parts[0] == 'right';
    final frac = parts.length > 1 ? double.tryParse(parts[1]) : null;
    return (right, (frac ?? 1.0).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    if (widget.hidden ||
        !s.whaleEnabled ||
        !s.whaleFloating ||
        MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    const size = WhaleFloating.size, m = WhaleFloating.margin;
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final maxX = (w - size - m).clamp(m, double.infinity);
        final maxY = (h - size - m).clamp(m, double.infinity);
        final (right, frac) = _local ?? _parse(s.whalePos);
        var x = right ? maxX : m;
        var y = (m + frac * (maxY - m)).clamp(m, maxY);
        if (_drag != null) {
          x = _drag!.dx.clamp(m, maxX);
          y = _drag!.dy.clamp(m, maxY);
        }
        return Stack(children: [
          Positioned(
            left: x,
            top: y,
            child: GestureDetector(
              onPanStart: (_) => setState(() => _drag = Offset(x, y)),
              onPanUpdate: (d) => setState(() => _drag = _drag! + d.delta),
              onPanEnd: (_) {
                final d = _drag!;
                final toRight = d.dx + size / 2 > w / 2;
                final f = maxY <= m ? 1.0 : ((d.dy.clamp(m, maxY) - m) / (maxY - m));
                setState(() {
                  _drag = null;
                  _local = (toRight, f);
                });
                ref
                    .read(repositoryProvider)
                    .setSetting(AppSettings.kWhalePos, '${toRight ? 'right' : 'left'}:${f.toStringAsFixed(3)}');
              },
              child: WhaleSprite(
                size: size,
                bubbleAlignment: right ? Alignment.topRight : Alignment.topLeft,
              ),
            ),
          ),
        ]);
      }),
    );
  }
}
