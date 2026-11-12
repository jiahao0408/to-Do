// Procesar bandeja: recorre las tareas sin fecha una a una para ponerles
// día, hueco libre o categoría, o descartarlas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/overlap.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';
import '../common/ph_icons.dart';

class ProcessInboxScreen extends ConsumerStatefulWidget {
  const ProcessInboxScreen({super.key});

  @override
  ConsumerState<ProcessInboxScreen> createState() => _ProcessInboxScreenState();
}

class _ProcessInboxScreenState extends ConsumerState<ProcessInboxScreen> {
  /// Ids saltados en esta sesión (siguen en la bandeja).
  final Set<int> _skipped = {};
  late final int _total = ref.read(snapshotProvider).inbox.length;

  Occurrence _occ(Task t) => Occurrence(task: t, series: t, occurrenceDate: null, completed: false);

  Future<void> _schedule(Task t, DateTime start, {bool allDay = false}) async {
    final ui = Ui.of(context);
    final f = Fmt.of(context);
    final o = _occ(t.copyWith(allDay: allDay));
    final point = await ui.service.move(o, start, durationMin: allDay ? null : (t.durationMin ?? 60));
    ui.undo(point, ui.l.placedAt(allDay ? f.weekdayDayMonth(start) : f.dateTime(start)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);
    final now = ref.watch(clockProvider).now();
    final queue = snap.inbox.where((t) => !_skipped.contains(t.id)).toList();

    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l.processInbox)),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(PhosphorIconsFill.tray, size: 64),
            const SizedBox(height: 12),
            Text(l.inboxDone, style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.finish)),
          ]),
        ),
      );
    }

    final t = queue.first;
    final index = (_total - queue.length + 1).clamp(1, _total < 1 ? 1 : _total);
    final today = dateOnly(now);
    final slot = findFreeSlot(snap.occurrencesOnDay, now, t.durationMin ?? 60);
    final cat = snap.categoryById(t.categoryId);

    Widget action(IconData icon, String label, VoidCallback onTap) => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: Icon(icon),
            label: Text(label),
            onPressed: onTap,
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.processInbox),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _total == 0 ? 1 : (index - 1) / _total),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.processInboxProgress(index, _total < index ? index : _total), style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: theme.textTheme.headlineSmall),
                  if (t.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(t.notes, maxLines: 4, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, children: [
                    Chip(
                      avatar: Icon(PhosphorIconsFill.flag, size: 16, color: priorityColor(t.priority)),
                      label: Text(priorityLabel(l, t.priority)),
                    ),
                    if (cat != null)
                      Chip(
                        avatar: CircleAvatar(radius: 6, backgroundColor: Color(cat.color)),
                        label: Text(cat.name),
                      ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          action(PhosphorIconsRegular.calendarDot, '${l.today} · ${f.weekdayDayMonth(today)}', () => _schedule(t, today, allDay: true)),
          const SizedBox(height: 8),
          action(PhosphorIconsRegular.sun, '${l.postponeTomorrow} · ${f.weekdayDayMonth(addDays(today, 1))}',
              () => _schedule(t, addDays(today, 1), allDay: true)),
          const SizedBox(height: 8),
          if (slot != null) ...[
            action(PhosphorIconsFill.sparkle, '${l.placeInFreeSlot} · ${f.dateTime(slot)}', () => _schedule(t, slot)),
            const SizedBox(height: 8),
          ],
          action(PhosphorIconsRegular.calendarBlank, l.postponePickDate, () async {
            final d = await showDatePicker(
              context: context,
              initialDate: today,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 10),
            );
            if (d == null || !context.mounted) return;
            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
            if (time == null) {
              await _schedule(t, dateOnly(d), allDay: true);
            } else {
              await _schedule(t, DateTime(d.year, d.month, d.day, time.hour, time.minute));
            }
          }),
          const SizedBox(height: 8),
          action(PhosphorIconsRegular.tag, l.changeCategory, () async {
            final cats = snap.categories;
            final picked = await showDialog<int>(
              context: context,
              builder: (ctx) => SimpleDialog(
                title: Text(l.changeCategory),
                children: [
                  SimpleDialogOption(onPressed: () => Navigator.pop(ctx, -1), child: Text(l.noCategory)),
                  for (final c in cats)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, c.id),
                      child: Row(children: [
                        CircleAvatar(radius: 7, backgroundColor: Color(c.color)),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ]),
                    ),
                ],
              ),
            );
            if (picked == null) return;
            await ref.read(repositoryProvider).updateTask(t.copyWith(categoryId: () => picked == -1 ? null : picked));
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton.icon(
                icon: Icon(PhosphorIconsRegular.prohibit, color: theme.colorScheme.error),
                label: Text(l.discard, style: TextStyle(color: theme.colorScheme.error)),
                onPressed: () async {
                  final ui = Ui.of(context);
                  final point = await ui.service.discard(_occ(t));
                  ui.undo(point, l.discard);
                },
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(PhosphorIconsRegular.skipForward),
                label: Text(l.skip),
                onPressed: () => setState(() => _skipped.add(t.id!)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
