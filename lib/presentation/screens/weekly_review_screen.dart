// RF-50: revisión semanal en tres pasos.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/overlap.dart';
import '../../domain/settings.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../calendar/agenda_view.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';
import '../task/postpone.dart';
import '../common/ph_icons.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);
    final now = ref.watch(clockProvider).now();
    final today = dateOnly(now);

    final pending = snap.overdue(now, seriesLookbackDays: 7)
        .where((o) => !dateOnly(o.task.start!).isBefore(addDays(today, -14)) || !o.isSeries)
        .toList();
    final nextWeek = snap.occurrencesBetween(today, addDays(today, 8)).where((o) => !o.completed).toList();
    final inbox = snap.inbox;

    Widget empty() => Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(l.reviewNothing, style: theme.textTheme.bodyLarge)),
        );

    final steps = [
      (l.reviewStep1, l.reviewStep1Body),
      (l.reviewStep2, l.reviewStep2Body),
      (l.reviewStep3, l.reviewStep3Body),
    ];

    Widget content;
    switch (step) {
      case 0:
        content = pending.isEmpty
            ? empty()
            : ListView(children: [
                for (final o in pending)
                  ListTile(
                    title: Text(o.task.title),
                    subtitle: Text(f.weekdayDayMonth(o.task.start!)),
                    trailing: Wrap(children: [
                      IconButton(
                        tooltip: l.moveToToday,
                        icon: const Icon(PhosphorIconsRegular.calendarDot),
                        onPressed: () async {
                          final ui = Ui.of(context);
                          final s = o.task.allDay ? today : withTimeOf(today, o.task.start!);
                          ui.undo(await ui.service.move(o, s), l.taskMoved);
                        },
                      ),
                      IconButton(
                        tooltip: l.reschedule,
                        icon: const Icon(PhosphorIconsRegular.alarm),
                        onPressed: () => showPostponeSheet(context, o),
                      ),
                      IconButton(
                        tooltip: l.discard,
                        icon: const Icon(PhosphorIconsRegular.prohibit),
                        onPressed: () async {
                          final ui = Ui.of(context);
                          ui.undo(await ui.service.discard(o), l.discard);
                        },
                      ),
                    ]),
                  ),
              ]);
      case 1:
        final groups = <DateTime, List<Occurrence>>{};
        for (final o in nextWeek) {
          (groups[dateOnly(o.task.start!)] ??= []).add(o);
        }
        content = nextWeek.isEmpty
            ? empty()
            : ListView(children: [
                for (final e in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(f.fullDate(e.key), style: theme.textTheme.titleSmall),
                  ),
                  for (final o in e.value) SwipeableTaskTile(occurrence: o),
                ],
              ]);
      default:
        content = inbox.isEmpty
            ? empty()
            : ListView(children: [
                for (final t in inbox)
                  ListTile(
                    title: Text(t.title),
                    trailing: FilledButton.tonalIcon(
                      icon: const Icon(PhosphorIconsFill.sparkle),
                      label: Text(l.placeInFreeSlot),
                      onPressed: () => _place(t),
                    ),
                  ),
              ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.weeklyReview)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= step ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    child: Text('${i + 1}',
                        style: TextStyle(color: i <= step ? theme.colorScheme.onPrimary : null, fontSize: 12)),
                  ),
                  if (i < 2) Expanded(child: Divider(indent: 4, endIndent: 4, color: theme.colorScheme.outline)),
                ],
              ],
            ),
          ),
          ListTile(
            title: Text(steps[step].$1, style: theme.textTheme.titleLarge),
            subtitle: Text(steps[step].$2),
          ),
          const Divider(),
          Expanded(child: content),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (step > 0) TextButton(onPressed: () => setState(() => step--), child: Text(l.back)),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (step < 2) {
                        setState(() => step++);
                        return;
                      }
                      final ui = Ui.of(context);
                      await ui.repo.setSetting(AppSettings.kLastReviewDate, formatDateKey(now));
                      if (context.mounted) Navigator.pop(context);
                      ui.message(l.reviewDone);
                    },
                    child: Text(step < 2 ? l.next : l.finish),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _place(Task t) async {
    final ui = Ui.of(context);
    final f = Fmt.of(context);
    final snap = ui.read(snapshotProvider);
    final now = ui.read(clockProvider).now();
    // Desde mañana si hoy ya es tarde; si no, desde ahora.
    final slot = findFreeSlot(snap.occurrencesOnDay, now, t.durationMin ?? 60);
    if (slot == null) {
      ui.message(ui.l.reviewNothing);
      return;
    }
    final o = Occurrence(task: t, series: t, occurrenceDate: null, completed: false);
    final point = await ui.service.move(o, slot, durationMin: t.durationMin ?? 60);
    ui.undo(point, ui.l.placedAt(f.dateTime(slot)));
  }
}
