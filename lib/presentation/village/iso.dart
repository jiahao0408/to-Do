// Aldea: proyección isométrica 2:1 y piezas básicas (prismas y tejados).
// Coordenadas del mundo en «baldosas»: x hacia la derecha-abajo, y hacia la
// izquierda-abajo, z hacia arriba. El espectador mira desde +x +y.

import 'dart:ui';

class Iso {
  const Iso(this.origin, this.u);

  /// Punto de pantalla de (0, 0, 0).
  final Offset origin;

  /// Medio ancho de una baldosa en píxeles.
  final double u;

  Offset p(double x, double y, [double z = 0]) => origin + Offset((x - y) * u, (x + y) * u * 0.5 - z * u);

  /// Rombo del suelo de un rectángulo.
  Path floor(double x, double y, double w, double d, [double z = 0]) => Path()
    ..addPolygon([p(x, y, z), p(x + w, y, z), p(x + w, y + d, z), p(x, y + d, z)], true);
}

Color shade(Color c, double amount) {
  final f = 1 + amount;
  int ch(double v) => (v * 255 * f).round().clamp(0, 255);
  return Color.fromARGB((c.a * 255).round(), ch(c.r), ch(c.g), ch(c.b));
}

void _poly(Canvas c, List<Offset> pts, Color fill, {bool outline = true}) {
  final path = Path()..addPolygon(pts, true);
  c.drawPath(path, Paint()..color = fill);
  if (outline) {
    c.drawPath(
      path,
      Paint()
        ..color = shade(fill, -0.35).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }
}

/// Caja: caras +y (izquierda), +x (derecha) y la de arriba.
void drawPrism(Canvas c, Iso iso, double x, double y, double z, double w, double d, double h, Color color) {
  if (h <= 0) return;
  _poly(c, [iso.p(x, y + d, z), iso.p(x + w, y + d, z), iso.p(x + w, y + d, z + h), iso.p(x, y + d, z + h)], color);
  _poly(c, [iso.p(x + w, y, z), iso.p(x + w, y + d, z), iso.p(x + w, y + d, z + h), iso.p(x + w, y, z + h)],
      shade(color, -0.18));
  _poly(c, [iso.p(x, y, z + h), iso.p(x + w, y, z + h), iso.p(x + w, y + d, z + h), iso.p(x, y + d, z + h)],
      shade(color, 0.12));
}

/// Tejado a dos aguas con la cumbrera paralela a x.
void drawGable(Canvas c, Iso iso, double x, double y, double z, double w, double d, double rh, Color color) {
  final ridgeA = iso.p(x, y + d / 2, z + rh), ridgeB = iso.p(x + w, y + d / 2, z + rh);
  _poly(c, [iso.p(x, y, z), iso.p(x + w, y, z), ridgeB, ridgeA], shade(color, 0.15));
  _poly(c, [iso.p(x, y + d, z), iso.p(x + w, y + d, z), ridgeB, ridgeA], color);
  _poly(c, [iso.p(x + w, y, z), iso.p(x + w, y + d, z), ridgeB], shade(color, -0.25));
}

/// Tejado a cuatro aguas en punta.
void drawPyramid(Canvas c, Iso iso, double x, double y, double z, double w, double d, double rh, Color color) {
  final apex = iso.p(x + w / 2, y + d / 2, z + rh);
  _poly(c, [iso.p(x, y + d, z), iso.p(x + w, y + d, z), apex], color);
  _poly(c, [iso.p(x + w, y, z), iso.p(x + w, y + d, z), apex], shade(color, -0.22));
}

/// Ventanas en las dos caras visibles de una caja.
void drawWindows(Canvas c, Iso iso, double x, double y, double z, double w, double d, double h, Color glass,
    {double floorH = 0.22}) {
  final floors = (h / floorH).floor().clamp(1, 12);
  final paint = Paint()..color = glass;
  for (var f = 0; f < floors; f++) {
    final z0 = z + f * floorH + floorH * 0.35, z1 = z0 + floorH * 0.4;
    if (z1 > z + h - 0.03) break;
    final nx = (w / 0.18).floor().clamp(1, 8), ny = (d / 0.18).floor().clamp(1, 8);
    for (var i = 0; i < nx; i++) {
      final a = x + (i + 0.3) * w / nx, b = a + w / nx * 0.4;
      c.drawPath(Path()..addPolygon([iso.p(a, y + d, z0), iso.p(b, y + d, z0), iso.p(b, y + d, z1), iso.p(a, y + d, z1)], true),
          paint);
    }
    for (var i = 0; i < ny; i++) {
      final a = y + (i + 0.3) * d / ny, b = a + d / ny * 0.4;
      c.drawPath(Path()..addPolygon([iso.p(x + w, a, z0), iso.p(x + w, b, z0), iso.p(x + w, b, z1), iso.p(x + w, a, z1)], true),
          Paint()..color = shade(glass, -0.15));
    }
  }
}

/// Árbol bajo poli: tronco y copa en punta.
void drawTree(Canvas c, Iso iso, double x, double y, double s, {Color leaves = const Color(0xFF4E9F5D)}) {
  drawPrism(c, iso, x - 0.02 * s, y - 0.02 * s, 0, 0.04 * s, 0.04 * s, 0.08 * s, const Color(0xFF8A5A3B));
  drawPyramid(c, iso, x - 0.09 * s, y - 0.09 * s, 0.08 * s, 0.18 * s, 0.18 * s, 0.3 * s, leaves);
}
