// Guía de gestos y ejemplos de texto natural.
import 'package:flutter/material.dart';

import '../common/format.dart';
import '../common/ph_icons.dart';

class GestureGuideScreen extends StatelessWidget {
  const GestureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final gestures = <(IconData, String)>[
      (PhosphorIconsFill.handTap, l.gTapBlock),
      (PhosphorIconsRegular.arrowsOutCardinal, l.gLongPressMove),
      (PhosphorIconsRegular.listChecks, l.gLongPress),
      (PhosphorIconsRegular.arrowsVertical, l.gResize),
      (PhosphorIconsRegular.handGrabbing, l.gPinch),
      (PhosphorIconsRegular.handSwipeRight, l.gSwipePages),
      (PhosphorIconsRegular.handSwipeRight, l.gSwipeList),
      (PhosphorIconsRegular.plusSquare, l.gLongPressEmpty),
      (PhosphorIconsRegular.columns, l.gWeekTap),
      (PhosphorIconsRegular.tray, l.gInboxDrag),
      (PhosphorIconsRegular.calendar, l.gMonthDrag),
    ];
    // Ejemplos en los tres idiomas: el intérprete los entiende mezclados.
    const examples = [
      'gym mañana 18h cada lunes #Personal !alta',
      'entrega práctica viernes 23:59 #Uni',
      'café el lunes a las 5 de la tarde durante 30 min',
      'inglés los martes y jueves 19:00',
      'dentist next tuesday 10am for 1h',
      'run tomorrow at 7pm every day !low',
      '明天下午6点健身',
      '每周一上午9点开会',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.gestureGuide)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l.gestures, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary)),
          ),
          for (final (icon, text) in gestures) ListTile(leading: Icon(icon), title: Text(text)),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(l.naturalLanguage, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.nlTips)),
          const SizedBox(height: 8),
          for (final e in examples)
            ListTile(
              dense: true,
              leading: const Icon(PhosphorIconsRegular.keyboard),
              title: Text(e, style: const TextStyle(fontFamily: 'monospace')),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
