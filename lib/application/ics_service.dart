// Aplica a la base de datos los eventos leídos de un .ics (importar) y
// genera el .ics de exportación.

import '../data/repository.dart';
import '../domain/ics/ics.dart';
import '../domain/models/entities.dart';
import '../domain/snapshot.dart';
import '../domain/time.dart';

/// Categoría destino al importar.
sealed class IcsCategoryChoice {
  const IcsCategoryChoice();
}

/// Usa CATEGORIES del archivo si coincide (sin mayúsculas) con una existente.
class FromFile extends IcsCategoryChoice {
  const FromFile();
}

/// Todas a una categoría concreta (null = sin categoría).
class FixedCategory extends IcsCategoryChoice {
  const FixedCategory(this.categoryId);
  final int? categoryId;
}

final _subtaskLine = RegExp(r'^- \[( |x|X)\] (.+)$');

/// Separa las subtareas («- [x] texto») del final de las notas, como las
/// escribe la exportación.
(String notes, List<Subtask> subtasks) splitSubtasks(String notes) {
  final lines = notes.split('\n');
  var i = lines.length;
  while (i > 0 && _subtaskLine.hasMatch(lines[i - 1].trim())) {
    i--;
  }
  if (i == lines.length) return (notes, const []);
  final subs = <Subtask>[];
  for (var k = i; k < lines.length; k++) {
    final m = _subtaskLine.firstMatch(lines[k].trim())!;
    subs.add(Subtask(taskId: 0, title: m.group(2)!, done: m.group(1) != ' ', order: subs.length));
  }
  return (lines.sublist(0, i).join('\n').trim(), subs);
}

class IcsService {
  IcsService(this.repo);
  final Repository repo;

  /// Importa [items]. Si un UID ya existía, la tarea anterior se sustituye.
  Future<UndoPoint> import(
    List<IcsItem> items, {
    required AppSnapshot snap,
    required String tz,
    IcsCategoryChoice category = const FromFile(),
  }) async {
    final existing = await repo.taskIdsByIcsUid();
    final byName = {for (final c in snap.categories) c.name.toLowerCase(): c.id};
    final now = repo.now;
    final replaced = [for (final i in items) ?existing[i.uid]];
    return repo.withUndo(replaced, () async {
      final created = <int>[];
      for (final it in items) {
        final old = existing[it.uid];
        if (old != null) await repo.deleteTask(old);
        final catId = switch (category) {
          FromFile() => it.categoryName == null ? null : byName[it.categoryName!.toLowerCase()],
          FixedCategory(:final categoryId) => categoryId,
        };
        final (notes, subs) = splitSubtasks(it.notes);
        it.notes = notes;
        final task = it.toTask(tz: tz, now: now, categoryId: catId);
        final id = await repo.insertTask(task,
            subtasks: subs, reminders: task.start == null ? const [] : it.reminders);
        created.add(id);
        if (task.isSeries) {
          for (final d in it.exdates) {
            await repo.upsertException(
                SeriesException(seriesId: id, originalDate: d, type: ExceptionType.skipped));
          }
          for (final e in it.overrides.entries) {
            final original = parseDateKey(e.key);
            final base = task.copyWith(start: () => withTimeOf(original, task.start!));
            final o = e.value;
            final edited = base.copyWith(
              title: o.title.isEmpty ? null : o.title,
              notes: o.notes,
              start: () => o.start ?? base.start,
              durationMin: () => o.durationMin ?? base.durationMin,
              allDay: o.allDay,
              location: o.location,
            );
            final diff = base.diffOverridable(edited);
            if (diff.isNotEmpty) {
              await repo.upsertException(SeriesException(
                  seriesId: id, originalDate: original, type: ExceptionType.modified, overrides: diff));
            }
          }
        }
      }
      return created;
    });
  }
}
