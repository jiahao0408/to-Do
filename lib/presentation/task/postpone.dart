// RF-14: posponer rápido.
import 'package:flutter/material.dart';

import '../../application/task_service.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';
import '../common/ph_icons.dart';

Future<void> showPostponeSheet(BuildContext context, Occurrence o) async {
  final ui = Ui.of(context);
  final l = ui.l;
  final f = Fmt.of(context);
  final now = ui.read(clockProvider).now();
  final mondayFirst = ui.read(settingsProvider).weekStartsMonday;
  final start = o.task.start;

  DateTime target(PostponeOption opt) =>
      postponeTarget(opt, start, now, weekStartsMonday: mondayFirst);

  final choice = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (opt, label, icon) in [
            (PostponeOption.plusHour, l.postponePlusHour, PhosphorIconsRegular.clock),
            (PostponeOption.thisAfternoon, l.postponeThisAfternoon, PhosphorIconsRegular.sunHorizon),
            (PostponeOption.tomorrow, l.postponeTomorrow, PhosphorIconsRegular.calendarDot),
            (PostponeOption.nextWeek, l.postponeNextWeek, PhosphorIconsRegular.calendarPlus),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: Text(f.dateTime(target(opt))),
              onTap: () => Navigator.pop(ctx, opt),
            ),
          ListTile(
            leading: const Icon(PhosphorIconsRegular.calendarBlank),
            title: Text(l.postponePickDate),
            onTap: () => Navigator.pop(ctx, 'pick'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  DateTime newStart;
  if (choice is PostponeOption) {
    newStart = target(choice);
  } else {
    final date = await showDatePicker(
      context: context,
      initialDate: start ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null) return;
    newStart = start == null ? DateTime(date.year, date.month, date.day, 9) : withTimeOf(date, start);
  }
  final point = await ui.service.move(o, newStart);
  ui.haptic(HapticKind.light);
  ui.undo(point, l.taskPostponed(f.dateTime(newStart)));
}
