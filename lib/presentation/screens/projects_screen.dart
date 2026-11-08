// Proyectos: aparte de la categoría, con color, fecha límite opcional y
// avance (tareas puntuales completadas / totales).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entities.dart';
import '../../domain/models/task.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../calendar/agenda_view.dart';
import '../common/format.dart';
import '../providers.dart';
import '../task/task_editor.dart';
import 'categories_screen.dart';

/// Crea o edita un proyecto. Devuelve el id guardado.
Future<int?> editProject(BuildContext context, WidgetRef ref, [Project? project]) async {
  final l = context.l10n;
  final f = Fmt.of(context);
  final ctrl = TextEditingController(text: project?.name ?? '');
  var color = project?.color ?? kPalette[(ref.read(snapshotProvider).projects.length * 3 + 2) % kPalette.length];
  DateTime? due = project?.dueDate;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(project == null ? l.newProject : l.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final c = await pickColor(ctx, color);
                  if (c != null) setState(() => color = c);
                },
                child: CircleAvatar(backgroundColor: Color(color), radius: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l.projectName),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined),
              title: Text(due == null ? l.noDueDate : '${l.projectDue}: ${f.fullDate(due!)}'),
              trailing: due == null
                  ? null
                  : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => due = null)),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: due ?? addDays(dateOnly(now), 30),
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 20),
                );
                if (d != null) setState(() => due = d);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
        ],
      ),
    ),
  );
  final name = ctrl.text.trim();
  if (ok != true || name.isEmpty) return null;
  final p = project == null
      ? Project(name: name, color: color, dueDate: due)
      : project.copyWith(name: name, color: color, dueDate: () => due);
  return ref.read(repositoryProvider).saveProject(p);
}

/// Barra de avance de un proyecto.
class ProjectProgress extends ConsumerWidget {
  const ProjectProgress({super.key, required this.project, this.dense = false});
  final Project project;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(snapshotProvider);
    final (done, total) = snap.projectProgress(project.id!);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: dense ? 4 : 8,
              color: Color(project.color),
              backgroundColor: Color(project.color).withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$done/$total', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key, required this.projectId});
  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);
    final project = snap.projectById(projectId);
    if (project == null) return const Scaffold();
    final now = ref.watch(clockProvider).now();
    final tasks = snap.tasksOfProject(projectId);

    Occurrence occ(Task t) {
      if (t.isSeries) {
        // Próxima ocurrencia de la serie (o la primera).
        final next = snap.occurrencesBetween(dateOnly(now), addDays(dateOnly(now), 400)).where((o) => o.taskId == t.id);
        if (next.isNotEmpty) return next.first;
      }
      return Occurrence(task: t, series: t, occurrenceDate: null, completed: t.isCompleted);
    }

    final pending = tasks.where((t) => !t.isCompleted).map(occ).toList()
      ..sort((a, b) {
        final sa = a.task.start, sb = b.task.start;
        if (sa == null && sb == null) return compareTasks(a.task, b.task);
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });
    final done = tasks.where((t) => t.isCompleted).map(occ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: l.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => editProject(context, ref, project),
          ),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: Text(l.deleteProjectConfirm(project.name)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              Navigator.pop(context);
              await ref.read(repositoryProvider).deleteProject(projectId);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.newTask,
        onPressed: () => openTaskEditor(context,
            draft: Task(
              title: '',
              projectId: projectId,
              tz: ref.read(timeZoneProvider),
              createdAt: now,
              updatedAt: now,
            ),
            draftReminders: const []),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ProjectProgress(project: project),
          ),
          if (project.dueDate != null)
            ListTile(
              leading: Icon(Icons.flag, color: Color(project.color)),
              title: Text('${l.projectDue}: ${f.fullDate(project.dueDate!)}'),
              subtitle: daysBetween(now, project.dueDate!) >= 0
                  ? Text(l.daysLeft(daysBetween(now, project.dueDate!)))
                  : Text(l.daysAgo(-daysBetween(now, project.dueDate!))),
            ),
          if (tasks.any((t) => t.isSeries))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l.projectSeriesNote, style: theme.textTheme.bodySmall),
            ),
          if (tasks.isEmpty)
            Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(l.projectEmpty))),
          for (final o in pending) SwipeableTaskTile(occurrence: o, showDate: true),
          if (done.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(l.statusCompleted, style: theme.textTheme.titleSmall),
            ),
            for (final o in done) SwipeableTaskTile(occurrence: o, showDate: true),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
