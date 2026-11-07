// Acciones comunes de UI: deshacer (RF-37), vibración (RF-41), avisos de
// solapamiento (RF-15) y diálogos de alcance (RF-23 a RF-25).
//
// [Ui] captura de forma síncrona lo que hace falta del BuildContext
// (contenedor de providers, ScaffoldMessenger, textos), para poder usarlo
// después de un `await` aunque el widget que lo pidió ya no exista.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../../application/task_service.dart';
import '../../data/repository.dart';
import '../../domain/overlap.dart';
import '../../domain/recurrence/recurrence_engine.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../../l10n/app_localizations.dart';
import '../providers.dart';
import 'format.dart';

enum HapticKind { light, medium, selection }

class Ui {
  Ui.of(BuildContext context)
      : container = ProviderScope.containerOf(context, listen: false),
        messenger = ScaffoldMessenger.maybeOf(context),
        l = AppLocalizations.of(context);

  final ProviderContainer container;
  final ScaffoldMessengerState? messenger;
  final AppLocalizations l;

  T read<T>(ProviderListenable<T> p) => container.read(p);
  TaskService get service => read(taskServiceProvider);
  Repository get repo => read(repositoryProvider);

  void haptic(HapticKind kind) {
    if (!read(settingsProvider).haptics) return;
    switch (kind) {
      case HapticKind.light:
        HapticFeedback.lightImpact();
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
      case HapticKind.selection:
        HapticFeedback.selectionClick();
    }
  }

  /// Aviso con «Deshacer» durante ~5 s.
  void undo(UndoPoint point, String message) {
    final m = messenger;
    if (m == null) return;
    final repo = this.repo;
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      // Con acción, Flutter lo deja fijo por defecto; RF-37 pide ~5 s.
      persist: false,
      action: SnackBarAction(label: l.undo, onPressed: () => repo.undo(point)),
    ));
  }

  void message(String text) {
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(text)));
  }

  /// Texto de aviso si [start]–[end] choca con otra tarea (RF-15).
  String? overlap(DateTime? start, DateTime? end, {String? excludeKey, bool allDay = false}) {
    if (start == null || end == null || allDay) return null;
    final snap = read(snapshotProvider);
    final conflicts =
        findConflicts(snap.occurrencesOnDay(start), start, end, excludeKey: excludeKey);
    if (conflicts.isEmpty) return null;
    return l.overlapWarning(conflicts.first.task.title);
  }
}

/// Completa o desmarca con vibración y opción de deshacer (RF-04, RF-42).
Future<void> toggleComplete(BuildContext context, Occurrence o) async {
  final ui = Ui.of(context);
  final done = !o.completed;
  ui.haptic(HapticKind.light);
  final point = await ui.service.setCompleted(o, done);
  ui.undo(point, done ? ui.l.taskCompleted : ui.l.taskUncompleted);
  if (done) _maybeCelebrate(ui, o);
}

/// Notificador para la celebración al completar todas las tareas del día.
final celebrationTick = ValueNotifier<int>(0);

void _maybeCelebrate(Ui ui, Occurrence o) {
  if (!ui.read(settingsProvider).animations) return;
  final day = o.task.start;
  if (day == null) return;
  final now = ui.read(clockProvider).now();
  if (!isSameDay(day, now)) return;
  // La foto se recarga en unos ms; se comprueba un poco después.
  Future.delayed(const Duration(milliseconds: 250), () {
    final today = ui.read(snapshotProvider).occurrencesOnDay(now);
    if (today.isNotEmpty && today.every((x) => x.completed)) {
      celebrationTick.value++;
    }
  });
}

/// Pregunta el alcance al editar/borrar una ocurrencia de serie.
Future<SeriesScope?> askScope(BuildContext context, {required bool deleting}) {
  final l = context.l10n;
  return showDialog<SeriesScope>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(deleting ? l.scopeDeleteTitle : l.scopeEditTitle),
      children: [
        for (final (scope, label) in [
          (SeriesScope.thisOne, l.scopeThisOne),
          (SeriesScope.thisAndFollowing, l.scopeThisAndFollowing),
          (SeriesScope.all, l.scopeAll),
          (SeriesScope.selected, l.scopeSelected),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, scope),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label),
            ),
          ),
      ],
    ),
  );
}

/// RF-25: lista de ocurrencias de la serie para marcar cuáles se tocan.
Future<List<DateTime>?> pickOccurrences(BuildContext context, Occurrence o) async {
  final l = context.l10n;
  final f = Fmt.of(context);
  final series = o.series;
  final from = addDays(dateOnly(DateTime.now()), -30);
  final dates = RecurrenceEngine.occurrences(series.rule!, series.start!,
          horizon: addDays(from, 400), limit: 1000)
      .where((d) => !d.isBefore(from))
      .toList();
  final selected = <String>{
    if (o.occurrenceDate != null) formatDateKey(o.occurrenceDate!),
  };
  return showDialog<List<DateTime>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.selectOccurrences),
        content: SizedBox(
          width: double.maxFinite,
          height: 420,
          child: ListView.builder(
            itemCount: dates.length,
            itemBuilder: (_, i) {
              final d = dates[i];
              final k = formatDateKey(d);
              return CheckboxListTile(
                dense: true,
                value: selected.contains(k),
                title: Text(f.fullDate(d)),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    selected.add(k);
                  } else {
                    selected.remove(k);
                  }
                }),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, [
              for (final d in dates)
                if (selected.contains(formatDateKey(d))) dateOnly(d),
            ]),
            child: Text(l.ok),
          ),
        ],
      ),
    ),
  );
}

/// Borra con alcance (si es serie) y opción de deshacer (RF-18, RF-24).
Future<bool> deleteOccurrence(BuildContext context, Occurrence o) async {
  final ui = Ui.of(context);
  SeriesScope scope = SeriesScope.all;
  List<DateTime> selected = const [];
  if (o.isSeries) {
    final s = await askScope(context, deleting: true);
    if (s == null || !context.mounted) return false;
    scope = s;
    if (s == SeriesScope.selected) {
      final picked = await pickOccurrences(context, o);
      if (picked == null || picked.isEmpty) return false;
      selected = picked;
    }
  }
  final point = await ui.service.delete(o, scope: scope, selectedDates: selected);
  ui.haptic(HapticKind.medium);
  ui.undo(point, ui.l.taskDeleted);
  return true;
}

/// Vibración desde un widget (síncrona, sin riesgo tras `await`).
void haptic(WidgetRef ref, HapticKind kind) {
  if (!ref.read(settingsProvider).haptics) return;
  switch (kind) {
    case HapticKind.light:
      HapticFeedback.lightImpact();
    case HapticKind.medium:
      HapticFeedback.mediumImpact();
    case HapticKind.selection:
      HapticFeedback.selectionClick();
  }
}
