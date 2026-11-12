// Aldea: cómo se dibuja cada edificio en sus 11 fases.
//   0      solar vacío con un cartel
//   1      cimientos
//   2–8    la obra sube de abajo arriba, con andamios
//   9      terminado
//   10     terminado y decorado (ventanas encendidas, bandera, árboles)

import 'dart:math';
import 'dart:ui';

import '../../domain/village/building.dart';
import 'iso.dart';

enum _Roof { flat, gable, pyramid }

enum _Ground { none, water, rails, field, lawn }

class _Block {
  const _Block(this.x, this.y, this.z, this.w, this.d, this.h, this.color,
      {this.roof = _Roof.flat, this.rh = 0, this.roofColor, this.windows = false});
  final double x, y, z, w, d, h;
  final Color color;
  final _Roof roof;
  final double rh;

  /// null = color del proyecto.
  final Color? roofColor;
  final bool windows;

  double get top => z + h + (roof == _Roof.flat ? 0 : rh);
}

class _Spec {
  const _Spec(this.blocks, {this.ground = _Ground.none, this.trees = const []});
  final List<_Block> blocks;
  final _Ground ground;

  /// Árboles propios del edificio (parque, granja): crecen con la obra.
  final List<(double, double, double)> trees;
}

const _stone = Color(0xFFBDB6A8);
const _brick = Color(0xFFB5654A);

_Spec _spec(BuildingType t) => switch (t) {
      BuildingType.house => const _Spec([
          _Block(0.25, 0.25, 0, 0.5, 0.5, 0.35, Color(0xFFF3E3C3), roof: _Roof.gable, rh: 0.25, windows: true),
        ]),
      BuildingType.cabin => const _Spec([
          _Block(0.28, 0.3, 0, 0.44, 0.4, 0.28, Color(0xFFB07A4A), roof: _Roof.gable, rh: 0.32, windows: true),
        ], trees: [(0.15, 0.8, 0.9)]),
      BuildingType.apartments => const _Spec([
          _Block(0.2, 0.2, 0, 0.6, 0.6, 1.0, Color(0xFFD9D4CC), windows: true),
          _Block(0.55, 0.3, 1.0, 0.14, 0.14, 0.12, Color(0xFF9EA7AD)),
        ]),
      BuildingType.school => const _Spec([
          _Block(0.42, 0.12, 0, 0.16, 0.16, 0.75, Color(0xFFE8B66A), roof: _Roof.pyramid, rh: 0.2),
          _Block(0.15, 0.3, 0, 0.7, 0.45, 0.4, Color(0xFFE8B66A), roof: _Roof.gable, rh: 0.2, windows: true),
        ]),
      BuildingType.library => const _Spec([
          _Block(0.18, 0.22, 0, 0.64, 0.5, 0.45, Color(0xFFD8C7A0), roof: _Roof.gable, rh: 0.15, windows: true),
          _Block(0.18, 0.72, 0, 0.64, 0.1, 0.05, _stone),
        ]),
      BuildingType.office => const _Spec([
          _Block(0.25, 0.25, 0, 0.5, 0.5, 1.3, Color(0xFF9DB8CF), windows: true),
          _Block(0.47, 0.47, 1.3, 0.04, 0.04, 0.25, Color(0xFF6B7780)),
        ]),
      BuildingType.workshop => const _Spec([
          _Block(0.62, 0.15, 0, 0.1, 0.1, 0.75, _brick),
          _Block(0.18, 0.28, 0, 0.6, 0.5, 0.35, Color(0xFFC9A27E), roof: _Roof.gable, rh: 0.18, windows: true),
        ]),
      BuildingType.bridge => const _Spec([
          _Block(0.26, 0.42, 0, 0.08, 0.16, 0.16, _stone),
          _Block(0.66, 0.42, 0, 0.08, 0.16, 0.16, _stone),
          _Block(0.05, 0.4, 0.16, 0.9, 0.2, 0.06, Color(0xFFA89F92)),
        ], ground: _Ground.water),
      BuildingType.waterTower => const _Spec([
          _Block(0.32, 0.32, 0, 0.05, 0.05, 0.6, Color(0xFF8C939A)),
          _Block(0.63, 0.32, 0, 0.05, 0.05, 0.6, Color(0xFF8C939A)),
          _Block(0.32, 0.63, 0, 0.05, 0.05, 0.6, Color(0xFF8C939A)),
          _Block(0.63, 0.63, 0, 0.05, 0.05, 0.6, Color(0xFF8C939A)),
          _Block(0.28, 0.28, 0.6, 0.44, 0.44, 0.32, Color(0xFFC0C6CC), roof: _Roof.pyramid, rh: 0.16),
        ]),
      BuildingType.powerPlant => const _Spec([
          _Block(0.7, 0.15, 0, 0.12, 0.12, 0.95, Color(0xFFDADADA)),
          _Block(0.7, 0.42, 0, 0.12, 0.12, 0.8, Color(0xFFDADADA)),
          _Block(0.12, 0.3, 0, 0.52, 0.5, 0.4, Color(0xFF9EA7AD), windows: true),
        ]),
      BuildingType.station => const _Spec([
          _Block(0.2, 0.15, 0, 0.6, 0.35, 0.3, Color(0xFFE0C9A6), roof: _Roof.gable, rh: 0.18, windows: true),
          _Block(0.08, 0.55, 0, 0.84, 0.12, 0.05, _stone),
        ], ground: _Ground.rails),
      BuildingType.park => const _Spec([
          _Block(0.4, 0.4, 0, 0.2, 0.2, 0.08, _stone),
          _Block(0.47, 0.47, 0.08, 0.06, 0.06, 0.12, Color(0xFF7FC4E8)),
        ], ground: _Ground.lawn, trees: [(0.2, 0.2, 1.1), (0.8, 0.22, 0.9), (0.22, 0.78, 0.9), (0.78, 0.8, 1.2)]),
      BuildingType.farm => const _Spec([
          _Block(0.66, 0.18, 0, 0.18, 0.18, 0.7, Color(0xFFC9CDD1),
              roof: _Roof.pyramid, rh: 0.14, roofColor: Color(0xFF8C939A)),
          _Block(0.14, 0.16, 0, 0.45, 0.4, 0.35, Color(0xFFC0533F), roof: _Roof.gable, rh: 0.22),
        ], ground: _Ground.field),
      BuildingType.lighthouse => const _Spec([
          _Block(0.32, 0.32, 0, 0.36, 0.36, 0.15, _stone),
          _Block(0.4, 0.4, 0.15, 0.2, 0.2, 0.9, Color(0xFFF5F5F0)),
          _Block(0.38, 0.38, 1.05, 0.24, 0.24, 0.12, Color(0xFFFFE08A), roof: _Roof.pyramid, rh: 0.14),
        ], ground: _Ground.water),
      BuildingType.castle => const _Spec([
          _Block(0.1, 0.1, 0, 0.18, 0.18, 0.6, _stone, roof: _Roof.pyramid, rh: 0.2),
          _Block(0.72, 0.1, 0, 0.18, 0.18, 0.6, _stone, roof: _Roof.pyramid, rh: 0.2),
          _Block(0.1, 0.72, 0, 0.18, 0.18, 0.6, _stone, roof: _Roof.pyramid, rh: 0.2),
          _Block(0.3, 0.3, 0, 0.4, 0.4, 0.85, _stone, roof: _Roof.pyramid, rh: 0.25, windows: true),
          _Block(0.72, 0.72, 0, 0.18, 0.18, 0.6, _stone, roof: _Roof.pyramid, rh: 0.2),
        ]),
    };

/// Altura total del edificio terminado (con tejados).
double buildingHeight(BuildingType t) => _spec(t).blocks.map((b) => b.top).reduce(max);

/// Dibuja el solar (1 × 1 baldosas en [x], [y]) y el edificio en la fase [stage].
/// [t] (0–1) anima humo, luz y bandera en la fase 10.
void paintBuilding(Canvas c, Iso iso, double x, double y, BuildingType type, int stage, Color accent,
    {double t = 0}) {
  final spec = _spec(type);
  stage = stage.clamp(0, 10);

  // Solar.
  final ground = stage >= 9 ? const Color(0xFFA8D68B) : const Color(0xFFCDB58E);
  c.drawPath(iso.floor(x + 0.03, y + 0.03, 0.94, 0.94), Paint()..color = ground);
  _paintGround(c, iso, x, y, spec.ground, stage);

  if (stage == 0) {
    // Estaca con cartel.
    drawPrism(c, iso, x + 0.48, y + 0.48, 0, 0.03, 0.03, 0.3, const Color(0xFF8A5A3B));
    drawPrism(c, iso, x + 0.4, y + 0.5, 0.22, 0.2, 0.01, 0.1, accent);
    return;
  }

  // Cimientos bajo cada bloque que toca el suelo.
  if (stage <= 8) {
    for (final b in spec.blocks.where((b) => b.z == 0)) {
      drawPrism(c, iso, x + b.x - 0.02, y + b.y - 0.02, 0, b.w + 0.04, b.d + 0.04, 0.03, const Color(0xFF9A9A9A));
    }
  }

  final full = stage >= 9;
  final reveal = full ? double.infinity : buildingHeight(type) * (stage - 1) / 8;

  for (final b in spec.blocks) {
    if (reveal <= b.z) continue;
    final h = min(b.h, reveal - b.z);
    drawPrism(c, iso, x + b.x, y + b.y, b.z, b.w, b.d, h, b.color);
    if (b.windows && full) {
      drawWindows(c, iso, x + b.x, y + b.y, b.z, b.w, b.d, b.h,
          stage == 10 ? const Color(0xFFFFE08A) : const Color(0xFF5D6F80));
    }
    if (reveal >= b.top || full) {
      final rc = b.roofColor ?? accent;
      switch (b.roof) {
        case _Roof.gable:
          drawGable(c, iso, x + b.x - 0.03, y + b.y - 0.03, b.z + b.h, b.w + 0.06, b.d + 0.06, b.rh, rc);
        case _Roof.pyramid:
          drawPyramid(c, iso, x + b.x - 0.02, y + b.y - 0.02, b.z + b.h, b.w + 0.04, b.d + 0.04, b.rh, rc);
        case _Roof.flat:
          break;
      }
    }
  }

  // Árboles propios: aparecen poco a poco.
  for (var i = 0; i < spec.trees.length; i++) {
    final (tx, ty, s) = spec.trees[i];
    if (stage >= 2 + i * 2) drawTree(c, iso, x + tx, y + ty, s * (full ? 1 : 0.7));
  }

  if (!full) {
    _paintScaffold(c, iso, x, y, spec, reveal);
    return;
  }

  if (stage == 10) _paintDecor(c, iso, x, y, type, spec, accent, t);
}

void _paintGround(Canvas c, Iso iso, double x, double y, _Ground g, int stage) {
  switch (g) {
    case _Ground.none:
      break;
    case _Ground.water:
      c.drawPath(iso.floor(x + 0.03, y + 0.36, 0.94, 0.28), Paint()..color = const Color(0xFF7FC4E8));
    case _Ground.rails:
      final p = Paint()
        ..color = const Color(0xFF6B5B4B)
        ..strokeWidth = 1.2;
      for (final yy in [0.76, 0.86]) {
        c.drawLine(iso.p(x + 0.03, y + yy), iso.p(x + 0.97, y + yy), p);
      }
    case _Ground.field:
      if (stage < 1) break;
      final rows = (stage / 2).ceil().clamp(1, 5);
      for (var i = 0; i < rows; i++) {
        c.drawPath(iso.floor(x + 0.12, y + 0.62 + i * 0.07, 0.76, 0.04),
            Paint()..color = stage >= 9 ? const Color(0xFFE2C35A) : const Color(0xFF7FAE5A));
      }
    case _Ground.lawn:
      if (stage >= 1) {
        c.drawPath(iso.floor(x + 0.08, y + 0.08, 0.84, 0.84), Paint()..color = const Color(0xFF8CCB78));
      }
  }
}

/// Andamios: el contorno de lo que falta por construir.
void _paintScaffold(Canvas c, Iso iso, double x, double y, _Spec spec, double reveal) {
  final p = Paint()
    ..color = const Color(0xFF9C6B3C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  for (final b in spec.blocks) {
    if (b.z + b.h <= reveal) continue;
    final bx = x + b.x - 0.02, by = y + b.y - 0.02, w = b.w + 0.04, d = b.d + 0.04;
    final z0 = max(b.z, reveal), z1 = b.z + b.h;
    for (final (px, py) in [(bx, by + d), (bx + w, by + d), (bx + w, by)]) {
      c.drawLine(iso.p(px, py, b.z), iso.p(px, py, z1), p);
    }
    for (var z = z0; z <= z1 + 0.001; z += 0.15) {
      c.drawLine(iso.p(bx, by + d, z), iso.p(bx + w, by + d, z), p);
      c.drawLine(iso.p(bx + w, by + d, z), iso.p(bx + w, by, z), p);
    }
  }
}

void _paintDecor(Canvas c, Iso iso, double x, double y, BuildingType type, _Spec spec, Color accent, double t) {
  // Bandera en lo más alto.
  final top = spec.blocks.reduce((a, b) => a.top >= b.top ? a : b);
  final fx = x + top.x + top.w / 2, fy = y + top.y + top.d / 2;
  final base = iso.p(fx, fy, top.top), tip = iso.p(fx, fy, top.top + 0.3);
  c.drawLine(base, tip, Paint()
    ..color = const Color(0xFF555555)
    ..strokeWidth = 1.2);
  final wave = sin(t * 2 * pi) * 2;
  c.drawPath(
    Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + 12, tip.dy + 4 + wave)
      ..lineTo(tip.dx, tip.dy + 8)
      ..close(),
    Paint()..color = accent,
  );

  // Flores en el borde del solar.
  const colors = [Color(0xFFF28AAE), Color(0xFFFFD166), Color(0xFFFFFFFF)];
  for (var i = 0; i < 6; i++) {
    c.drawCircle(iso.p(x + 0.1 + i * 0.15, y + 0.93), 1.8, Paint()..color = colors[i % 3]);
  }

  // Extras por tipo.
  if (type == BuildingType.powerPlant || type == BuildingType.workshop) {
    final chimney = spec.blocks.first;
    final o = iso.p(x + chimney.x + chimney.w / 2, y + chimney.y + chimney.d / 2, chimney.top);
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1;
      c.drawCircle(o + Offset(k * 6, -k * 22), 3 + k * 4,
          Paint()..color = const Color(0xFFEEEEEE).withValues(alpha: 0.8 * (1 - k)));
    }
  }
  if (type == BuildingType.lighthouse) {
    final lamp = spec.blocks.last;
    final o = iso.p(x + lamp.x + lamp.w / 2, y + lamp.y + lamp.d / 2, lamp.z + lamp.h / 2);
    final a = t * 2 * pi;
    c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + cos(a) * 60, o.dy + sin(a) * 18 - 6)
        ..lineTo(o.dx + cos(a) * 60, o.dy + sin(a) * 18 + 6)
        ..close(),
      Paint()..color = const Color(0xFFFFE08A).withValues(alpha: 0.45),
    );
  }
  if (spec.trees.isEmpty) {
    drawTree(c, iso, x + 0.1, y + 0.88, 0.8);
    drawTree(c, iso, x + 0.88, y + 0.12, 0.7);
  }
}
