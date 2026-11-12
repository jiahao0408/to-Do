// Logo de to Do: ladrillos en forma de check en pixel art 16 × 16.
// La misma cuadrícula está en tool/make_logo.py (que genera los iconos).

import 'package:flutter/material.dart';

const _bg = Color(0xFF5B7CFA);
const _edge = Color(0xFF3E5BD9);
const _brick = Color(0xFFFFFFFF);
const _brickShadow = Color(0xFFC9D3FF);
const _last = Color(0xFFFFC83D);
const _lastHi = Color(0xFFFFE08A);
const _lastShadow = Color(0xFFE0A91E);

const _bricks = [(2, 8), (4, 10), (6, 12), (8, 10), (10, 8), (12, 6)];

class PixelLogo extends StatelessWidget {
  const PixelLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'to Do',
        child: SizedBox.square(dimension: size, child: const CustomPaint(painter: _LogoPainter())),
      );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16;
    void px(int x, int y, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * s, y * s, s + 0.5, s + 0.5), Paint()..color = c);
    bool cut(int x, int y) {
      bool c(int a, int b) => a + b < 2;
      return c(x, y) || c(15 - x, y) || c(x, 15 - y) || c(15 - x, 15 - y);
    }

    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        if (cut(x, y)) continue;
        final border = x == 0 || y == 0 || x == 15 || y == 15 || ((x == 1 || x == 14) && (y == 1 || y == 14));
        px(x, y, border ? _edge : _bg);
      }
    }
    for (final (bx, by) in _bricks) {
      for (var i = 0; i < 3; i++) {
        px(bx + i, by, _brick);
        px(bx + i, by + 1, _brickShadow);
      }
    }
    for (var i = 0; i < 3; i++) {
      px(12 + i, 2, i == 0 ? _lastHi : _last);
      px(12 + i, 3, _lastShadow);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}
