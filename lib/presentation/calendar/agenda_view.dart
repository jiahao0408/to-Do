// Vista agenda (RF-31) y deslizar en listas (RF-38).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../common/task_tile.dart';
import '../providers.dart';
import '../task/postpone.dart';
import '../task/task_detail.dart';
import '../common/ph_icons.dart';

class AgendaView extends ConsumerStatefulWidget {
  const AgendaView({super.key});

  @override
  ConsumerState<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends ConsumerState<AgendaView> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);
    final anchor = ref.watch(calendarProvider).anchor;
    final now = ref.watch(clockProvider).now();
    final from = dateOnly(anchor);
    final to = addDays(from, _days);
    final occ = snap.calendarOccurrencesBetween(from, to);

    // Fijadas y cuentas atrás arriba (RF-11, RF-12).
    final pinned = <Occurrence>[
      for (final t in snap.tasks.where((t) => t.pinned && !t.isCompleted))
        if (!t.isSeries)
          Occurrence(task: t, series: t, occurrenceDate: null, completed: false),
    ];
    final countdowns = snap
        .calendarOccurrencesBetween(dateOnly(now), addDays(dateOnly(now), 400))
        .where((o) => o.task.countdown && !o.completed)
        .take(5)
        .toList();

    final groups = <DateTime, List<Occurrence>>{};
    for (final o in occ) {
      (groups[dateOnly(o.task.start!)] ??= []).add(o);
    }

    final children = <Widget>[];
    void section(String title) => children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary)),
        ));
    if (pinned.isNotEmpty) {
      section(l.pinnedSection);
      children.addAll(pinned.map((o) => SwipeableTaskTile(occurrence: o, showDate: true)));
    }
    if (countdowns.isNotEmpty) {
      section(l.countdownSection);
      for (final o in countdowns) {
        children.add(ListTile(
          leading: const Icon(PhosphorIconsRegular.hourglassMedium),
          title: Text(o.task.title),
          subtitle: Text(f.fullDate(o.task.start!)),
          trailing: Text(l.daysLeft(daysBetween(now, o.task.start!)),
              style: theme.textTheme.titleSmall),
          onTap: () => showTaskDetail(context, o),
        ));
      }
    }
    for (final entry in groups.entries) {
      final isToday = isSameDay(entry.key, now);
      children.add(InkWell(
        onTap: () => ref.read(calendarProvider.notifier).openDay(entry.key),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            isToday ? '${l.today} · ${f.weekdayDayMonth(entry.key)}' : f.fullDate(entry.key),
            style: theme.textTheme.titleSmall!.copyWith(
              color: isToday ? theme.colorScheme.primary : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));
      children.addAll(entry.value.map((o) => SwipeableTaskTile(occurrence: o)));
    }
    if (groups.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(l.noTasks, style: theme.textTheme.bodyLarge)),
      ));
    }
    children.add(Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: OutlinedButton(
          onPressed: () => setState(() => _days += 30),
          child: Text(l.loadMore),
        ),
      ),
    ));
    children.add(const SizedBox(height: 80));

    return ListView(children: children);
  }
}

/// Fila con gestos: derecha completa, izquierda borra o pospone (RF-38).
class SwipeableTaskTile extends ConsumerWidget {
  const SwipeableTaskTile({super.key, required this.occurrence, this.showDate = false});
  final Occurrence occurrence;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final leftPostpones = settings.swipeLeft == SwipeLeftAction.postpone;
    final selection = ref.watch(selectionProvider);
    return Dismissible(
      key: ValueKey('swipe-${o.key}-${o.completed}'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(PhosphorIconsRegular.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: leftPostpones ? Colors.orange : theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(leftPostpones ? PhosphorIconsRegular.alarm : PhosphorIconsRegular.trash, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await toggleComplete(context, o);
          return false; // La fila se actualiza sola (tachada).
        }
        if (leftPostpones) {
          await showPostponeSheet(context, o);
          return false;
        }
        return deleteOccurrence(context, o);
      },
      child: TaskTile(
        occurrence: o,
        showDate: showDate,
        selected: selection.contains(o),
        onToggle: () => toggleComplete(context, o),
        onTap: () {
          if (selection.isNotEmpty) {
            ref.read(selectionProvider.notifier).toggle(o);
          } else {
            showTaskDetail(context, o);
          }
        },
        onLongPress: () {
          haptic(ref, HapticKind.medium);
          ref.read(selectionProvider.notifier).toggle(o);
        },
      ),
    );
  }
}
