// Detalle de una tarea en hoja inferior.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../common/task_tile.dart';
import '../providers.dart';
import 'attachments_section.dart';
import 'postpone.dart';
import 'task_editor.dart';
import 'timer_section.dart';

Future<void> showTaskDetail(BuildContext context, Occurrence o) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => TaskDetailSheet(occurrence: o),
  );
}

class TaskDetailSheet extends ConsumerWidget {
  const TaskDetailSheet({super.key, required this.occurrence});
  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final snap = ref.watch(snapshotProvider);
    // Versión actualizada de la ocurrencia tras cambios.
    final o = snap.occurrenceOf(occurrence.taskId, occurrence.occurrenceDate) ??
        occurrence;
    final t = o.task;
    final theme = Theme.of(context);
    final cat = snap.categoryById(t.categoryId);
    final color = categoryColorOf(ref, t.categoryId, context);
    final subs = snap.subtasksOf(o.taskId);
    final reminders = snap.remindersOf(o.taskId);
    final now = ref.watch(clockProvider).now();

    Future<void> openUrl(String url) async {
      final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: CompleteCheck(
                  completed: o.completed,
                  color: color,
                  size: 28,
                  onTap: () => toggleComplete(context, o),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.title,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    decoration: o.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Icon(Icons.flag, color: priorityColor(t.priority)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (t.start != null)
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(t.allDay
                      ? '${f.fullDate(t.start!)} · ${l.allDayShort}'
                      : '${f.weekdayDayMonth(t.start!)} ${f.time(t.start!)}–${f.time(t.end!)}'),
                )
              else
                Chip(avatar: const Icon(Icons.inbox, size: 18), label: Text(l.unscheduled)),
              if (cat != null)
                Chip(
                  avatar: CircleAvatar(backgroundColor: Color(cat.color), radius: 6),
                  label: Text(cat.name),
                ),
              if (snap.projectById(o.series.projectId) case final pr?)
                Chip(
                  avatar: Icon(Icons.folder, size: 18, color: Color(pr.color)),
                  label: Text(pr.name),
                ),
              Chip(label: Text('${l.priority}: ${priorityLabel(l, t.priority)}')),
              if (o.isSeries)
                Chip(
                  avatar: const Icon(Icons.repeat, size: 18),
                  label: Text(describeRule(l, f, o.series.rule!, o.series.start!)),
                ),
              if (t.countdown && t.start != null && daysBetween(now, t.start!) >= 0)
                Chip(
                  avatar: const Icon(Icons.hourglass_bottom, size: 18),
                  label: Text(l.daysLeft(daysBetween(now, t.start!))),
                ),
              if (t.pinned) Chip(avatar: const Icon(Icons.push_pin, size: 18), label: Text(l.pinned)),
              for (final r in reminders)
                Chip(
                  avatar: const Icon(Icons.notifications_none, size: 18),
                  label: Text(reminderLabel(l, r.minutesBefore)),
                ),
            ],
          ),
          if (t.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(t.notes),
          ],
          if (t.location.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(t.location),
              trailing: const Icon(Icons.map_outlined),
              onTap: () => openUrl(
                  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(t.location)}'),
            ),
          if (t.url.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: Text(t.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => openUrl(t.url),
            ),
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${l.subtasks} · ${subs.where((s) => s.done).length}/${subs.length}',
                style: theme.textTheme.titleSmall),
            LinearProgressIndicator(
              value: subs.where((s) => s.done).length / subs.length,
            ),
            for (final s in subs)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: s.done,
                title: Text(s.title,
                    style: s.done
                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                        : null),
                onChanged: (v) async {
                  await ref.read(repositoryProvider).toggleSubtask(s.id!, v ?? false);
                  // RF-05: completar todas sugiere completar la tarea.
                  final allDone = subs.every((x) => x.id == s.id ? (v ?? false) : x.done);
                  if (allDone && !o.completed && context.mounted) {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: Text(l.suggestCompleteTask),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l.later)),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l.complete)),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) toggleComplete(context, o);
                  }
                },
              ),
          ],
          TimerSection(occurrence: o),
          AttachmentsSection(taskId: o.taskId),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(l.edit),
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  openTaskEditor(nav.context, occurrence: o);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.snooze),
                label: Text(l.postpone),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  nav.pop();
                  await showPostponeSheet(nav.context, o);
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(l.duplicate),
                onPressed: () => duplicateOccurrence(context, o),
              ),
              if (o.isSeries)
                OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next),
                  label: Text(l.skipOccurrence),
                  onPressed: () async {
                    final ui = Ui.of(context);
                    Navigator.pop(context);
                    final point = await ui.repo.withUndo([o.taskId], () async {
                      await ui.service.skip(o.taskId, o.occurrenceDate!);
                      return const [];
                    });
                    ui.undo(point, l.taskSkipped);
                  },
                ),
              OutlinedButton.icon(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                label: Text(l.delete, style: TextStyle(color: theme.colorScheme.error)),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final done = await deleteOccurrence(context, o);
                  if (done) nav.pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// RF-13: duplicar a otro día u hora.
Future<void> duplicateOccurrence(BuildContext context, Occurrence o) async {
  final ui = Ui.of(context);
  final now = ui.read(clockProvider).now();
  final base = o.task.start ?? now;
  final date = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 10),
  );
  if (date == null || !context.mounted) return;
  DateTime start = withTimeOf(date, base);
  if (!o.task.allDay && o.task.start != null) {
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(base));
    if (time == null || !context.mounted) return;
    start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
  } else if (o.task.allDay) {
    start = dateOnly(date);
  }
  final point =
      await ui.repo.withUndo(const [], () async => [await ui.service.duplicate(o, start)]);
  ui.undo(point, ui.l.taskDuplicated);
}
