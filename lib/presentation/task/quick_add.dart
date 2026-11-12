// Creación rápida (RF-36) con texto natural (RF-48).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../domain/nlp/quick_parser.dart';
import '../../domain/recurrence/recurrence_rule.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';
import 'task_editor.dart';
import '../common/ph_icons.dart';

Future<void> showQuickAdd(BuildContext context, {DateTime? start, bool unscheduled = false}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: QuickAddSheet(start: start, unscheduled: unscheduled),
    ),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.start, this.unscheduled = false});
  final DateTime? start;
  final bool unscheduled;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _ctrl = TextEditingController();
  ParsedTask? _parsed;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DateTime get _defaultStart {
    if (widget.start != null) return widget.start!;
    final now = ref.read(clockProvider).now();
    final anchor = ref.read(calendarProvider).anchor;
    final t = now.add(const Duration(hours: 1));
    final base = isSameDay(anchor, now) ? t : DateTime(anchor.year, anchor.month, anchor.day, 9);
    return DateTime(base.year, base.month, base.day, base.hour);
  }

  void _onChanged(String text) {
    final snap = ref.read(snapshotProvider);
    final parser = QuickParser(
      now: ref.read(clockProvider).now(),
      categories: {for (final c in snap.categories) c.name: c.id!},
      weekStartsMonday: ref.read(settingsProvider).weekStartsMonday,
    );
    setState(() => _parsed = text.trim().isEmpty ? null : parser.parse(text));
  }

  Task _toTask() {
    final now = ref.read(clockProvider).now();
    final p = _parsed;
    final hasParsedDate = p?.date != null;
    DateTime? start;
    var allDay = false;
    if (hasParsedDate) {
      final d = p!.date!;
      if (p.time != null) {
        start = DateTime(d.year, d.month, d.day, p.time!.hour, p.time!.minute);
      } else if (widget.start != null) {
        start = withTimeOf(d, widget.start!);
      } else {
        start = dateOnly(d);
        allDay = true;
      }
    } else if (p?.time != null) {
      final base = widget.start ?? _defaultStart;
      start = DateTime(base.year, base.month, base.day, p!.time!.hour, p.time!.minute);
    } else if (!widget.unscheduled) {
      start = _defaultStart;
    }
    return Task(
      title: (p?.title.isNotEmpty ?? false) ? p!.title : _ctrl.text.trim(),
      start: start,
      allDay: allDay,
      durationMin: p?.durationMin ?? 60,
      categoryId: p?.categoryId,
      priority: p?.priority ?? Priority.medium,
      rrule: start == null ? null : p?.rule?.toRRule(),
      tz: ref.read(timeZoneProvider),
      createdAt: now,
      updatedAt: now,
    );
  }

  List<int> get _reminders {
    final d = ref.read(settingsProvider).defaultReminder;
    return d >= 0 ? [d] : [];
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    final ui = Ui.of(context);
    final task = _toTask();
    final reminders = task.start == null ? const <int>[] : _reminders;
    final msg = ui.overlap(task.start, task.end, allDay: task.allDay) ?? ui.l.taskSaved;
    Navigator.pop(context);
    final point = await ui.repo.withUndo(const [], () async => [
          await ui.service.create(task, reminders: reminders),
        ]);
    ui.undo(point, msg);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final p = _parsed;
    final task = _ctrl.text.trim().isEmpty ? null : _toTask();
    final theme = Theme.of(context);
    final snap = ref.watch(snapshotProvider);

    final chips = <Widget>[];
    if (task != null) {
      if (task.start != null) {
        chips.add(_chip(PhosphorIconsRegular.calendarBlank,
            task.allDay ? f.weekdayDayMonth(task.start!) : f.dateTime(task.start!), p?.date != null || p?.time != null));
      } else {
        chips.add(_chip(PhosphorIconsRegular.tray, l.unscheduled, false));
      }
      if (p?.durationMin != null) chips.add(_chip(PhosphorIconsRegular.timer, f.duration(p!.durationMin!), true));
      final rule = RecurrenceRule.tryParse(task.rrule);
      if (rule != null) {
        chips.add(_chip(PhosphorIconsRegular.repeat, describeRule(l, f, rule, task.start!), true));
      }
      if (p?.priority != null) {
        chips.add(_chip(PhosphorIconsFill.flag, priorityLabel(l, p!.priority!), true, color: priorityColor(p.priority!)));
      }
      final cat = snap.categoryById(p?.categoryId);
      if (cat != null) chips.add(_chip(PhosphorIconsRegular.tag, cat.name, true, color: Color(cat.color)));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l.quickAddHint,
                helperText: l.naturalLanguageHint,
                helperMaxLines: 2,
              ),
              onChanged: _onChanged,
              onSubmitted: (_) => _save(),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.quickAddPreview, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              // RF-48: vista previa con los campos detectados; tocar abre el
              // editor completo para cambiarlos.
              InkWell(
                onTap: _openEditor,
                child: Wrap(spacing: 6, runSpacing: 4, children: chips),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(PhosphorIconsRegular.slidersHorizontal),
                  label: Text(l.moreOptions),
                  onPressed: _openEditor,
                ),
                const Spacer(),
                FilledButton(onPressed: _save, child: Text(l.save)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool detected, {Color? color}) {
    final theme = Theme.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: detected ? theme.colorScheme.tertiaryContainer : null,
    );
  }

  void _openEditor() {
    final draft = _ctrl.text.trim().isEmpty
        ? Task(
            title: '',
            start: widget.unscheduled ? null : _defaultStart,
            tz: ref.read(timeZoneProvider),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        : _toTask();
    final nav = Navigator.of(context);
    final reminders = draft.start == null ? const <int>[] : _reminders;
    nav.pop();
    openTaskEditor(nav.context, draft: draft, draftReminders: reminders);
  }
}
