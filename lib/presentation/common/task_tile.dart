import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../providers.dart';
import 'format.dart';
import 'ph_icons.dart';

Color categoryColorOf(WidgetRef ref, int? categoryId, BuildContext context) {
  final c = ref.watch(snapshotProvider).categoryById(categoryId);
  return c == null ? Theme.of(context).colorScheme.primary : Color(c.color);
}

/// Círculo de completar con animación (RF-04, RF-42).
class CompleteCheck extends StatelessWidget {
  const CompleteCheck({
    super.key,
    required this.completed,
    required this.color,
    required this.onTap,
    this.size = 24,
    this.animate = true,
  });
  final bool completed;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: completed,
      label: completed ? context.l10n.uncomplete : context.l10n.complete,
      child: InkResponse(
        onTap: onTap,
        radius: size,
        child: AnimatedContainer(
          duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
          curve: Curves.easeOutBack,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
          child: AnimatedSwitcher(
            duration: animate ? const Duration(milliseconds: 200) : Duration.zero,
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: completed
                ? Icon(PhosphorIconsRegular.check, key: const ValueKey(1), size: size * 0.7, color: Colors.white)
                : const SizedBox.shrink(key: ValueKey(0)),
          ),
        ),
      ),
    );
  }
}

/// Fila de tarea para agenda, bandeja y búsqueda.
class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.occurrence,
    required this.onTap,
    this.onToggle,
    this.onLongPress,
    this.selected = false,
    this.showDate = false,
  });

  final Occurrence occurrence;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final t = occurrence.task;
    final snap = ref.watch(snapshotProvider);
    final cat = snap.categoryById(t.categoryId);
    final color = categoryColorOf(ref, t.categoryId, context);
    final subs = snap.subtasksOf(occurrence.taskId);
    final animations = ref.watch(settingsProvider).animations;
    final now = ref.watch(clockProvider).now();
    final theme = Theme.of(context);

    final meta = <String>[];
    if (t.start != null) {
      if (showDate) meta.add(f.weekdayDayMonth(t.start!));
      meta.add(t.allDay
          ? l.allDayShort
          : '${f.time(t.start!)}–${f.time(t.end!)}');
    }
    if (cat != null) meta.add(cat.name);
    if (subs.isNotEmpty) meta.add('${subs.where((s) => s.done).length}/${subs.length}');
    if (t.countdown && t.start != null) {
      final days = daysBetween(now, t.start!);
      if (days >= 0) meta.add(l.daysLeft(days));
    }

    return ListTile(
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: occurrence.completed ? 0.35 : 1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        CompleteCheck(
          completed: occurrence.completed,
          color: color,
          animate: animations,
          onTap: onToggle ?? () {},
        ),
      ]),
      title: AnimatedDefaultTextStyle(
        duration: Duration(milliseconds: animations ? 250 : 0),
        style: theme.textTheme.bodyLarge!.copyWith(
          decoration: occurrence.completed ? TextDecoration.lineThrough : null,
          color: occurrence.completed
              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
              : theme.colorScheme.onSurface,
        ),
        child: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      subtitle: meta.isEmpty ? null : Text(meta.join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (t.pinned) const Icon(PhosphorIconsFill.pushPin, size: 16),
          if (occurrence.isSeries) const Icon(PhosphorIconsRegular.repeat, size: 16),
          if (snap.remindersOf(occurrence.taskId).isNotEmpty)
            const Icon(PhosphorIconsRegular.bell, size: 16),
          if (t.priority != Priority.low) ...[
            const SizedBox(width: 4),
            Icon(PhosphorIconsFill.flag, size: 18, color: priorityColor(t.priority)),
          ],
        ],
      ),
    );
  }
}
