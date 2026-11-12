// Colores de un evento en el calendario (v2): fondo tintado suave del color
// de la categoría, texto en un tono del mismo color y barra de acento.

import 'package:flutter/material.dart';

class EventColors {
  const EventColors(this.background, this.foreground, this.accent);
  final Color background;
  final Color foreground;
  final Color accent;

  factory EventColors.of(BuildContext context, Color color, {bool completed = false}) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(color);
    final bg = Color.alphaBlend(color.withValues(alpha: dark ? 0.32 : 0.2), scheme.surface);
    var fg = hsl.withLightness(dark ? 0.86 : 0.26).withSaturation((hsl.saturation * 0.9).clamp(0, 1)).toColor();
    var accent = color;
    if (completed) {
      fg = fg.withValues(alpha: 0.55);
      accent = color.withValues(alpha: 0.45);
      return EventColors(Color.alphaBlend(color.withValues(alpha: dark ? 0.14 : 0.09), scheme.surface), fg, accent);
    }
    return EventColors(bg, fg, accent);
  }
}
