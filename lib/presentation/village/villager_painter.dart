// El habitante de la aldea: un constructor con casco, dibujado en código.
// Su cara y su postura siguen el ánimo (calma, fiesta, prisa, sueño) y las
// reacciones (saludo, toque, ladrillo nuevo, sorpresa).

import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/villager/villager_mood.dart';

const kVillagerBlue = Color(0xFF5B7CFA);
const _skin = Color(0xFFF2C9A0);
const _helmet = Color(0xFFFFC83D);
const _helmetBrim = Color(0xFFE0A91E);
const _ink = Color(0xFF2B2B3A);

/// Dibuja al habitante con los pies en [feet] y [h] píxeles de alto.
/// [t] (0–1, en bucle) anima pasos, saludo y confeti. [walking] mueve las piernas.
void paintVillager(Canvas c, Offset feet, double h, VillagerMood mood,
    {VillagerReaction? reaction, double t = 0, bool walking = false}) {
  final wave = sin(t * 2 * pi);
  final cheer = reaction == VillagerReaction.eat ||
      reaction == VillagerReaction.easter ||
      (reaction == null && mood == VillagerMood.celebrate);
  final sleeping = mood == VillagerMood.sleep && reaction != VillagerReaction.poked;
  final hop = cheer ? (wave.abs() * 0.06 * h) : 0.0;
  final f = feet - Offset(0, hop);

  // Sombra.
  c.drawOval(Rect.fromCenter(center: feet, width: h * 0.5, height: h * 0.12),
      Paint()..color = Colors.black.withValues(alpha: 0.15));

  // Piernas.
  final step = walking ? wave * 0.05 * h : 0.0;
  final leg = Paint()..color = const Color(0xFF3D4B8F);
  for (final (dx, s) in [(-0.09, 1.0), (0.09, -1.0)]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(f.dx + dx * h - 0.05 * h + step * s, f.dy - 0.24 * h, 0.1 * h, 0.24 * h),
        Radius.circular(0.04 * h),
      ),
      leg,
    );
  }

  // Cuerpo (peto).
  final bodyTop = f.dy - 0.56 * h;
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(f.dx - 0.21 * h, bodyTop, 0.42 * h, 0.34 * h),
    Radius.circular(0.1 * h),
  );
  c.drawRRect(body, Paint()..color = kVillagerBlue);
  c.drawRect(Rect.fromLTWH(f.dx - 0.08 * h, bodyTop + 0.1 * h, 0.16 * h, 0.1 * h),
      Paint()..color = const Color(0xFF4A68E0));

  // Brazos.
  final arm = Paint()
    ..color = kVillagerBlue
    ..strokeWidth = 0.09 * h
    ..strokeCap = StrokeCap.round;
  final hand = Paint()..color = _skin;
  final shoulderL = Offset(f.dx - 0.2 * h, bodyTop + 0.07 * h), shoulderR = Offset(f.dx + 0.2 * h, bodyTop + 0.07 * h);
  Offset handL, handR;
  if (cheer) {
    handL = shoulderL + Offset(-0.12 * h, -0.28 * h + wave * 0.03 * h);
    handR = shoulderR + Offset(0.12 * h, -0.28 * h - wave * 0.03 * h);
  } else if (reaction == VillagerReaction.pet) {
    handL = shoulderL + Offset(-0.06 * h, 0.22 * h);
    handR = shoulderR + Offset(0.14 * h + wave * 0.05 * h, -0.26 * h);
  } else if (mood == VillagerMood.worried && reaction == null) {
    handL = shoulderL + Offset(0.02 * h, -0.2 * h);
    handR = shoulderR + Offset(-0.02 * h, -0.2 * h);
  } else {
    handL = shoulderL + Offset(-0.06 * h, 0.22 * h);
    handR = shoulderR + Offset(0.06 * h, 0.22 * h);
  }
  for (final (s, e) in [(shoulderL, handL), (shoulderR, handR)]) {
    c.drawLine(s, e, arm);
    c.drawCircle(e, 0.05 * h, hand);
  }
  if (reaction == VillagerReaction.eat) {
    // Ladrillo nuevo en alto.
    c.drawRect(Rect.fromCenter(center: (handL + handR) / 2 - Offset(0, 0.06 * h), width: 0.22 * h, height: 0.1 * h),
        Paint()..color = const Color(0xFFB5654A));
  }

  // Cabeza.
  final head = Offset(f.dx, bodyTop - 0.16 * h);
  final r = 0.2 * h;
  c.drawCircle(head, r, Paint()..color = _skin);
  // Casco.
  c.drawArc(Rect.fromCircle(center: head - Offset(0, 0.02 * h), radius: r * 1.02), pi, pi, true, Paint()..color = _helmet);
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: head - Offset(0, 0.02 * h), width: r * 2.5, height: 0.05 * h),
      Radius.circular(0.02 * h),
    ),
    Paint()..color = _helmetBrim,
  );

  // Cara.
  final ink = Paint()
    ..color = _ink
    ..strokeWidth = max(1, 0.025 * h)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final eyeY = head.dy + 0.04 * h;
  for (final dx in [-0.07 * h, 0.07 * h]) {
    final e = Offset(head.dx + dx, eyeY);
    if (sleeping) {
      c.drawArc(Rect.fromCenter(center: e, width: 0.07 * h, height: 0.04 * h), 0, pi, false, ink);
    } else if (reaction == VillagerReaction.poked || reaction == VillagerReaction.easter) {
      c.drawCircle(e, 0.035 * h, ink);
    } else {
      c.drawCircle(e, 0.025 * h, Paint()..color = _ink);
    }
  }
  // Mejillas.
  for (final dx in [-0.12 * h, 0.12 * h]) {
    c.drawCircle(Offset(head.dx + dx, eyeY + 0.05 * h), 0.03 * h,
        Paint()..color = const Color(0xFFF28AAE).withValues(alpha: 0.6));
  }
  final mouth = Offset(head.dx, eyeY + 0.08 * h);
  if (sleeping) {
    c.drawCircle(mouth, 0.015 * h, ink);
  } else if (cheer || reaction == VillagerReaction.pet) {
    c.drawArc(Rect.fromCenter(center: mouth - Offset(0, 0.02 * h), width: 0.12 * h, height: 0.1 * h), 0, pi, true,
        Paint()..color = const Color(0xFFB0413E));
  } else if (mood == VillagerMood.worried && reaction == null) {
    c.drawArc(Rect.fromCenter(center: mouth + Offset(0, 0.02 * h), width: 0.1 * h, height: 0.06 * h), pi, pi, false, ink);
    // Gota de sudor.
    final d = Offset(head.dx + r * 0.95, head.dy - r * 0.1);
    c.drawPath(
      Path()
        ..moveTo(d.dx, d.dy - 0.06 * h)
        ..quadraticBezierTo(d.dx + 0.04 * h, d.dy, d.dx, d.dy + 0.02 * h)
        ..quadraticBezierTo(d.dx - 0.04 * h, d.dy, d.dx, d.dy - 0.06 * h),
      Paint()..color = const Color(0xFF7FC4E8),
    );
  } else if (reaction == VillagerReaction.poked) {
    c.drawCircle(mouth, 0.025 * h, ink);
  } else {
    c.drawArc(Rect.fromCenter(center: mouth - Offset(0, 0.01 * h), width: 0.1 * h, height: 0.06 * h), 0, pi, false, ink);
  }

  // Extras.
  if (sleeping) {
    final tp = TextPainter(
      text: TextSpan(text: 'z Z', style: TextStyle(color: _ink.withValues(alpha: 0.7), fontSize: 0.16 * h)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, head + Offset(r * 0.8, -r * 1.6 - wave * 0.02 * h));
  }
  if (cheer || reaction == VillagerReaction.easter) {
    const colors = [Color(0xFFF28AAE), Color(0xFFFFD166), Color(0xFF7FC4E8), Color(0xFF8CCB78)];
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * pi + t * 2 * pi;
      final dist = r * (1.6 + 0.3 * sin(t * 4 * pi + i));
      c.drawCircle(head + Offset(cos(a) * dist, sin(a) * dist * 0.7), 0.02 * h + 1, Paint()..color = colors[i % 4]);
    }
  }
}

