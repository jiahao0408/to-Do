// Habitante：心情。优先级：睡觉 → 庆祝 → 着急 → 平常。
// 所有任务都参与判断（包括在日历里隐藏的类别），和提醒、小组件一样。

import '../snapshot.dart';
import 'villager_state.dart';

enum VillagerMood { normal, celebrate, worried, sleep }

/// Noche: de 22:00 a 6:59 (hora local).
bool isVillagerNight(DateTime now) => now.hour >= 22 || now.hour < 7;

VillagerMood moodFor({required AppSnapshot snap, required DateTime now, required double fullness}) {
  if (isVillagerNight(now)) return VillagerMood.sleep;
  final today = snap.occurrencesOnDay(now);
  if (today.isNotEmpty && today.every((o) => o.completed)) return VillagerMood.celebrate;
  if (snap.overdue(now).isNotEmpty || fullness < VillagerState.kHungry) return VillagerMood.worried;
  return VillagerMood.normal;
}

/// Reacciones puntuales a la interacción.
enum VillagerReaction { pet, poked, eat, easter }
