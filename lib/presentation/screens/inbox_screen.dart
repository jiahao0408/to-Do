// Bandeja de tareas sin hora (RF-02). En la vista día/semana se muestra como
// panel inferior desde el que se arrastran las tareas a un hueco.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/snapshot.dart';
import '../calendar/agenda_view.dart';
import '../common/format.dart';
import '../common/task_tile.dart';
import '../providers.dart';
import '../task/quick_add.dart';

Occurrence _occ(Task t) =>
    Occurrence(task: t, series: t, occurrenceDate: null, completed: t.isCompleted);

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final inbox = ref.watch(snapshotProvider).inbox;
    return Scaffold(
      appBar: AppBar(title: Text(l.inbox)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAdd(context, unscheduled: true),
        child: const Icon(Icons.add),
      ),
      body: inbox.isEmpty
          ? Center(child: Text(l.inboxEmpty))
          : ListView(
              children: [for (final t in inbox) SwipeableTaskTile(occurrence: _occ(t))],
            ),
    );
  }
}

/// Panel inferior con las tareas de la bandeja, arrastrables al calendario.
class InboxPanel extends ConsumerWidget {
  const InboxPanel({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final inbox = ref.watch(snapshotProvider).inbox;
    final haptics = ref.watch(settingsProvider).haptics;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.inbox_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(inbox.isEmpty ? l.inboxEmpty : l.dragToCalendar,
                        style: theme.textTheme.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    for (final t in inbox)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: LongPressDraggable<Task>(
                          data: t,
                          hapticFeedbackOnStart: haptics,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: Material(
                            color: Colors.transparent,
                            child: _InboxChip(task: t, dragging: true),
                          ),
                          childWhenDragging: Opacity(opacity: 0.3, child: _InboxChip(task: t)),
                          child: _InboxChip(task: t),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxChip extends ConsumerWidget {
  const _InboxChip({required this.task, this.dragging = false});
  final Task task;
  final bool dragging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = categoryColorOf(ref, task.categoryId, context);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: dragging ? const [BoxShadow(blurRadius: 8, color: Colors.black26)] : null,
      ),
      child: Text(
        task.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
