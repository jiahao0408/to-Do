// Habitante：台词种类、上下文和挑选（纯逻辑；文字在 ARB 里）。

import 'dart:math';

import 'villager_mood.dart';
import 'villager_state.dart';

enum VillagerLineKind { normal, celebrate, worried, hungry, sleep, pet, poked, eat }

class VillagerContext {
  const VillagerContext({
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
VillagerLineKind kindForMood(VillagerMood m, VillagerContext c) => switch (m) {
      VillagerMood.sleep => VillagerLineKind.sleep,
      VillagerMood.celebrate => VillagerLineKind.celebrate,
      VillagerMood.worried =>
        c.overdue == 0 && c.fullness < VillagerState.kHungry ? VillagerLineKind.hungry : VillagerLineKind.worried,
      VillagerMood.normal => VillagerLineKind.normal,
    };

/// Elige una frase al azar sin repetir [last] (si hay más de una).
String pickLine(List<String> candidates, Random rnd, {String? last}) {
  if (candidates.isEmpty) return '';
  final pool = candidates.length > 1 ? candidates.where((c) => c != last).toList() : candidates;
  return pool[rnd.nextInt(pool.length)];
}
