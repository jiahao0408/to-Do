// Habitante：控制器。Lee la foto de datos y los ajustes, calcula el estado y lo
// guarda en la tabla settings (con un retardo para no escribir a cada paso).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../domain/settings.dart';
import '../../domain/snapshot.dart';
import '../../domain/villager/villager_lines.dart';
import '../../domain/villager/villager_mood.dart';
import '../../domain/villager/villager_state.dart';
import '../providers.dart';

class VillagerView {
  const VillagerView({
    required this.state,
    required this.mood,
    required this.context,
    required this.enabled,
    this.reaction,
    this.reactionTick = 0,
  });

  final VillagerState state;
  final VillagerMood mood;
  final VillagerContext context;
  final bool enabled;

  /// Reacción puntual en curso (null = ninguna).
  final VillagerReaction? reaction;

  /// Sube con cada interacción o comida: la imagen y la frase se renuevan.
  final int reactionTick;

  VillagerView copyWith({VillagerReaction? Function()? reaction, int? reactionTick}) => VillagerView(
        state: state,
        mood: mood,
        context: context,
        enabled: enabled,
        reaction: reaction != null ? reaction() : this.reaction,
        reactionTick: reactionTick ?? this.reactionTick,
      );
}

final villagerProvider = NotifierProvider<VillagerController, VillagerView>(VillagerController.new);

class VillagerController extends Notifier<VillagerView> {
  VillagerState? _state;

  /// Lo último que se escribió en settings (o se leyó al arrancar).
  VillagerState? _saved;
  AppSnapshot? _snap;
  bool _wasEnabled = true;
  Timer? _minute;
  Timer? _save;
  late Repository _repo;

  @override
  VillagerView build() {
    _repo = ref.read(repositoryProvider);
    _minute = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
    ref.onDispose(() {
      _minute?.cancel();
      _flush();
    });
    ref.listen(snapshotStreamProvider, (_, next) {
      if (next case AsyncData(:final value)) _onSnapshot(value);
    });
    final now = ref.read(clockProvider).now();
    final initial = switch (ref.read(snapshotStreamProvider)) {
      AsyncData(:final value) => _compute(value, now, fromSnapshot: true),
      _ => null,
    };
    return initial ??
        VillagerView(
          state: VillagerState.initial(now, 0),
          mood: VillagerMood.normal,
          context: const VillagerContext(remainingToday: 0, overdue: 0, fullness: VillagerState.kInitial),
          enabled: true,
        );
  }

  /// Recalcula con la hora actual (lo llama un temporizador cada minuto).
  void refresh() {
    final snap = _snap;
    if (snap == null) return;
    final v = _compute(snap, ref.read(clockProvider).now(), fromSnapshot: false);
    if (v != null) state = v;
  }

  void _onSnapshot(AppSnapshot snap) {
    final v = _compute(snap, ref.read(clockProvider).now(), fromSnapshot: true);
    if (v != null) state = v;
  }

  VillagerView? _compute(AppSnapshot snap, DateTime now, {required bool fromSnapshot}) {
    _snap = snap;
    final settings = AppSettings(snap.settings);
    final count = completedCount(snap);
    if (_state == null) _saved = VillagerState.fromSettings(snap.settings);
    var st = _state ?? _saved ?? VillagerState.initial(now, count);
    VillagerReaction? reaction = _stateOrNull?.reaction;
    var tick = _stateOrNull?.reactionTick ?? 0;

    if (snap.settings[AppSettings.kVillagerRebase] == '1') {
      st = st.rebased(count);
      _repo.setSetting(AppSettings.kVillagerRebase, '0');
    }
    final enabled = settings.villagerEnabled;
    if (!enabled) {
      st = st.frozenAt(now).rebased(count);
    } else {
      if (!_wasEnabled) st = st.frozenAt(now);
      final before = st.baseline;
      st = st.decayed(now).applyCompletions(count);
      if (fromSnapshot && count > before) {
        reaction = VillagerReaction.eat;
        tick++;
      }
    }
    // Solo se guarda cuando cambia la «recta» de la bajada: la base (comer,
    // desmarcar, importar) o el interruptor. Guardar emite una foto nueva y
    // volvería a entrar aquí: guardar siempre sería un bucle cada 2 s.
    final saved = _saved;
    if (saved == null || saved.baseline != st.baseline || enabled != _wasEnabled) _scheduleSave();
    _wasEnabled = enabled;
    _state = st;

    final today = snap.occurrencesOnDay(now);
    final pending = today.where((o) => !o.completed).toList();
    final next = pending.where((o) => !o.task.allDay && o.start != null && !o.start!.isBefore(now)).firstOrNull;
    return VillagerView(
      state: st,
      mood: moodFor(snap: snap, now: now, fullness: st.fullness),
      context: VillagerContext(
        remainingToday: pending.length,
        overdue: snap.overdue(now).length,
        fullness: st.fullness,
        nextTitle: next?.task.title,
        nextStart: next?.start,
      ),
      enabled: enabled,
      reaction: reaction,
      reactionTick: tick,
    );
  }

  VillagerView? get _stateOrNull {
    try {
      return state;
    } catch (_) {
      return null; // todavía en build()
    }
  }

  void _scheduleSave() {
    _save?.cancel();
    _save = Timer(const Duration(seconds: 2), _flush);
  }

  void _flush() {
    _save?.cancel();
    _save = null;
    final st = _state;
    if (st == null) return;
    _saved = st;
    for (final e in st.toSettings().entries) {
      _repo.setSetting(e.key, e.value);
    }
  }

  void pet() => state = state.copyWith(reaction: () => VillagerReaction.pet, reactionTick: state.reactionTick + 1);

  /// Dormida: se despierta un momento. Despierta: solo cambia imagen y frase.
  void poke() => state = state.copyWith(
        reaction: () => state.mood == VillagerMood.sleep ? VillagerReaction.poked : null,
        reactionTick: state.reactionTick + 1,
      );

  void easter() =>
      state = state.copyWith(reaction: () => VillagerReaction.easter, reactionTick: state.reactionTick + 1);

  void clearReaction() => state = state.copyWith(reaction: () => null);
}
