// Ballenita：控制器。Lee la foto de datos y los ajustes, calcula el estado y lo
// guarda en la tabla settings (con un retardo para no escribir a cada paso).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../domain/settings.dart';
import '../../domain/snapshot.dart';
import '../../domain/whale/whale_lines.dart';
import '../../domain/whale/whale_mood.dart';
import '../../domain/whale/whale_state.dart';
import '../providers.dart';

class WhaleView {
  const WhaleView({
    required this.state,
    required this.mood,
    required this.context,
    required this.enabled,
    this.reaction,
    this.reactionTick = 0,
  });

  final WhaleState state;
  final WhaleMood mood;
  final WhaleContext context;
  final bool enabled;

  /// Reacción puntual en curso (null = ninguna).
  final WhaleReaction? reaction;

  /// Sube con cada interacción o comida: la imagen y la frase se renuevan.
  final int reactionTick;

  WhaleView copyWith({WhaleReaction? Function()? reaction, int? reactionTick}) => WhaleView(
        state: state,
        mood: mood,
        context: context,
        enabled: enabled,
        reaction: reaction != null ? reaction() : this.reaction,
        reactionTick: reactionTick ?? this.reactionTick,
      );
}

final whaleProvider = NotifierProvider<WhaleController, WhaleView>(WhaleController.new);

class WhaleController extends Notifier<WhaleView> {
  WhaleState? _state;

  /// Lo último que se escribió en settings (o se leyó al arrancar).
  WhaleState? _saved;
  AppSnapshot? _snap;
  bool _wasEnabled = true;
  Timer? _minute;
  Timer? _save;
  late Repository _repo;

  @override
  WhaleView build() {
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
        WhaleView(
          state: WhaleState.initial(now, 0),
          mood: WhaleMood.normal,
          context: const WhaleContext(remainingToday: 0, overdue: 0, fullness: WhaleState.kInitial),
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

  WhaleView? _compute(AppSnapshot snap, DateTime now, {required bool fromSnapshot}) {
    _snap = snap;
    final settings = AppSettings(snap.settings);
    final count = completedCount(snap);
    if (_state == null) _saved = WhaleState.fromSettings(snap.settings);
    var st = _state ?? _saved ?? WhaleState.initial(now, count);
    WhaleReaction? reaction = _stateOrNull?.reaction;
    var tick = _stateOrNull?.reactionTick ?? 0;

    if (snap.settings[AppSettings.kWhaleRebase] == '1') {
      st = st.rebased(count);
      _repo.setSetting(AppSettings.kWhaleRebase, '0');
    }
    final enabled = settings.whaleEnabled;
    if (!enabled) {
      st = st.frozenAt(now).rebased(count);
    } else {
      if (!_wasEnabled) st = st.frozenAt(now);
      final before = st.baseline;
      st = st.decayed(now).applyCompletions(count);
      if (fromSnapshot && count > before) {
        reaction = WhaleReaction.eat;
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
    return WhaleView(
      state: st,
      mood: moodFor(snap: snap, now: now, fullness: st.fullness),
      context: WhaleContext(
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

  WhaleView? get _stateOrNull {
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

  void pet() => state = state.copyWith(reaction: () => WhaleReaction.pet, reactionTick: state.reactionTick + 1);

  /// Dormida: se despierta un momento. Despierta: solo cambia imagen y frase.
  void poke() => state = state.copyWith(
        reaction: () => state.mood == WhaleMood.sleep ? WhaleReaction.poked : null,
        reactionTick: state.reactionTick + 1,
      );

  void easter() =>
      state = state.copyWith(reaction: () => WhaleReaction.easter, reactionTick: state.reactionTick + 1);

  void clearReaction() => state = state.copyWith(reaction: () => null);
}
