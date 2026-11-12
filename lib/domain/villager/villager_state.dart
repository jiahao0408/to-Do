// Habitante：饱腹度。完成任务就是喂食；随时间慢慢饿，但永远不会死。

import '../snapshot.dart';

class VillagerState {
  const VillagerState({required this.fullness, required this.updatedAt, required this.baseline});

  /// 0–100.
  final double fullness;

  /// Último momento en que se aplicó la bajada con el tiempo.
  final DateTime updatedAt;

  /// «Completadas en total» vistas la última vez (ver [completedCount]).
  final int baseline;

  static const double kInitial = 70;
  static const double kDecayPerDay = 50;
  static const double kFeedPerTask = 15;
  static const double kHungry = 25;

  static const kFullness = 'whale.fullness';
  static const kUpdatedAt = 'whale.updatedAt';
  static const kBaseline = 'whale.completedBaseline';

  factory VillagerState.initial(DateTime now, int completedNow) =>
      VillagerState(fullness: kInitial, updatedAt: now, baseline: completedNow);

  static double _clamp(double v) => v.clamp(0, 100).toDouble();

  /// Bajada lineal: [kDecayPerDay] cada 24 h desde [updatedAt].
  VillagerState decayed(DateTime now) {
    if (!now.isAfter(updatedAt)) return this;
    final hours = now.difference(updatedAt).inMicroseconds / Duration.microsecondsPerHour;
    return VillagerState(fullness: _clamp(fullness - kDecayPerDay * hours / 24), updatedAt: now, baseline: baseline);
  }

  /// `fullness += (completedNow - baseline) * 15`, y `baseline = completedNow`.
  VillagerState applyCompletions(int completedNow) => VillagerState(
        fullness: _clamp(fullness + (completedNow - baseline) * kFeedPerTask),
        updatedAt: updatedAt,
        baseline: completedNow,
      );

  /// Solo cambia la línea base (tras importar o restaurar una copia).
  VillagerState rebased(int completedNow) =>
      VillagerState(fullness: fullness, updatedAt: updatedAt, baseline: completedNow);

  /// Mientras el interruptor general está apagado: no baja ni come.
  VillagerState frozenAt(DateTime now) => VillagerState(fullness: fullness, updatedAt: now, baseline: baseline);

  bool get hungry => fullness < kHungry;

  Map<String, String> toSettings() => {
        kFullness: fullness.toStringAsFixed(3),
        kUpdatedAt: updatedAt.toIso8601String(),
        kBaseline: '$baseline',
      };

  static VillagerState? fromSettings(Map<String, String> raw) {
    final f = double.tryParse(raw[kFullness] ?? '');
    final u = DateTime.tryParse(raw[kUpdatedAt] ?? '');
    final b = int.tryParse(raw[kBaseline] ?? '');
    if (f == null || u == null || b == null) return null;
    return VillagerState(fullness: _clamp(f), updatedAt: u, baseline: b);
  }
}

/// Tareas puntuales completadas + ocurrencias completadas de las series.
int completedCount(AppSnapshot s) =>
    s.tasks.where((t) => t.isCompleted && !t.isSeries).length + s.completions.length;
