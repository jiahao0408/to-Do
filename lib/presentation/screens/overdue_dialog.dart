// RF-17: diálogo de tareas atrasadas al abrir la app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';

Future<void> showOverdueDialog(BuildContext context, List<Occurrence> items) {
  return showDialog(
    context: context,
    builder: (_) => OverdueDialog(initial: items),
  );
}

class OverdueDialog extends ConsumerStatefulWidget {
  const OverdueDialog({super.key, required this.initial});
  final List<Occurrence> initial;

  @override
  ConsumerState<OverdueDialog> createState() => _OverdueDialogState();
}

class _OverdueDialogState extends ConsumerState<OverdueDialog> {
  late List<Occurrence> items = [...widget.initial];
  final List<UndoPoint> _points = [];

  DateTime get _today => dateOnly(ref.read(clockProvider).now());

  DateTime _todayAt(Occurrence o) =>
      o.task.start == null || o.task.allDay ? _today : withTimeOf(_today, o.task.start!);

  Future<void> _moveToToday(Occurrence o) async {
    _points.add(await ref.read(taskServiceProvider).move(o, _todayAt(o)));
    setState(() => items.remove(o));
  }

  Future<void> _reschedule(Occurrence o) async {
    final d = await showDatePicker(
      context: context,
      initialDate: addDays(_today, 1),
      firstDate: _today,
      lastDate: DateTime(_today.year + 10),
    );
    if (d == null) return;
    final start = o.task.allDay ? dateOnly(d) : withTimeOf(d, o.task.start!);
    _points.add(await ref.read(taskServiceProvider).move(o, start));
    setState(() => items.remove(o));
  }

  Future<void> _discard(Occurrence o) async {
    _points.add(await ref.read(taskServiceProvider).discard(o));
    setState(() => items.remove(o));
  }

  void _closeIfEmpty() {
    if (items.isEmpty && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final now = ref.watch(clockProvider).now();
    return AlertDialog(
      title: Text(l.overdueTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.overdueBody(items.length)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(o.task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${f.weekdayDayMonth(o.task.start!)} · ${l.daysAgo(daysBetween(o.task.start!, now))}'),
                      trailing: PopupMenuButton<int>(
                        onSelected: (v) async {
                          if (v == 0) await _moveToToday(o);
                          if (v == 1) await _reschedule(o);
                          if (v == 2) await _discard(o);
                          _closeIfEmpty();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 0, child: Text(l.moveToToday)),
                          PopupMenuItem(value: 1, child: Text(l.reschedule)),
                          PopupMenuItem(value: 2, child: Text(l.discard)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.later)),
        TextButton(
          onPressed: () async {
            final ui = Ui.of(context);
            final all = [...items];
            Navigator.pop(context);
            final point = await ui.repo.withUndo(all.map((o) => o.taskId), () async {
              for (final o in all) {
                await ui.service.discard(o);
              }
              return const [];
            });
            ui.undo(point, l.discardAll);
          },
          child: Text(l.discardAll),
        ),
        FilledButton(
          onPressed: () async {
            final ui = Ui.of(context);
            final all = [...items];
            final today = _today;
            Navigator.pop(context);
            final point = await ui.repo.withUndo(all.map((o) => o.taskId), () async {
              for (final o in all) {
                await ui.service.move(o,
                    o.task.start == null || o.task.allDay ? today : withTimeOf(today, o.task.start!));
              }
              return const [];
            });
            ui.undo(point, l.tasksMoved(all.length));
          },
          child: Text(l.allToToday),
        ),
      ],
    );
  }
}
