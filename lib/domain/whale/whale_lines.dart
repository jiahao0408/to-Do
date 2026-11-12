// 鲸鱼娘：台词种类、上下文和挑选（纯逻辑；文字在 ARB 里）。

import 'dart:math';

import 'whale_mood.dart';
import 'whale_state.dart';

enum WhaleLineKind { normal, celebrate, worried, hungry, sleep, pet, poked, eat }

class WhaleContext {
  const WhaleContext({
    required this.remainingToday,
    required this.overdue,
    required this.fullness,
    this.nextTitle,
    this.nextStart,
  });

  final int remainingToday;
  final String? nextTitle;
  final DateTime? nextStart;
  final int overdue;
  final double fullness;
}

/// Preocupada sin atrasadas pero con hambre → frases de hambre.
WhaleLineKind kindForMood(WhaleMood m, WhaleContext c) => switch (m) {
      WhaleMood.sleep => WhaleLineKind.sleep,
      WhaleMood.celebrate => WhaleLineKind.celebrate,
      WhaleMood.worried =>
        c.overdue == 0 && c.fullness < WhaleState.kHungry ? WhaleLineKind.hungry : WhaleLineKind.worried,
      WhaleMood.normal => WhaleLineKind.normal,
    };

/// Elige una frase al azar sin repetir [last] (si hay más de una).
String pickLine(List<String> candidates, Random rnd, {String? last}) {
  if (candidates.isEmpty) return '';
  final pool = candidates.length > 1 ? candidates.where((c) => c != last).toList() : candidates;
  return pool[rnd.nextInt(pool.length)];
}
