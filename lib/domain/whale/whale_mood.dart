// 鲸鱼娘：心情。优先级：睡觉 → 庆祝 → 着急 → 平常。
// 所有任务都参与判断（包括在日历里隐藏的类别），和提醒、小组件一样。

import '../snapshot.dart';
import 'whale_state.dart';

enum WhaleMood { normal, celebrate, worried, sleep }

/// Noche: de 22:00 a 6:59 (hora local).
bool isWhaleNight(DateTime now) => now.hour >= 22 || now.hour < 7;

WhaleMood moodFor({required AppSnapshot snap, required DateTime now, required double fullness}) {
  if (isWhaleNight(now)) return WhaleMood.sleep;
  final today = snap.occurrencesOnDay(now);
  if (today.isNotEmpty && today.every((o) => o.completed)) return WhaleMood.celebrate;
  if (snap.overdue(now).isNotEmpty || fullness < WhaleState.kHungry) return WhaleMood.worried;
  return WhaleMood.normal;
}

/// Reacciones puntuales a la interacción.
enum WhaleReaction { pet, poked, eat, easter }
