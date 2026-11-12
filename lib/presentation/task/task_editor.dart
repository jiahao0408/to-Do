// Crear y editar tareas (RF-01 y siguientes).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/task_service.dart';
import '../../domain/models/entities.dart';
import '../../domain/models/task.dart';
import '../../domain/recurrence/recurrence_rule.dart';
import '../../domain/snapshot.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';
import 'recurrence_editor.dart';
import '../common/ph_icons.dart';

/// Abre el editor. Con [occurrence] edita; si no, crea con los valores de
/// [draft] (p. ej. fecha/hora del hueco pulsado).
Future<void> openTaskEditor(BuildContext context, {Occurrence? occurrence, Task? draft,
    List<int>? draftReminders}) {
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => TaskEditor(occurrence: occurrence, draft: draft, draftReminders: draftReminders),
  ));
}

class TaskEditor extends ConsumerStatefulWidget {
  const TaskEditor({super.key, this.occurrence, this.draft, this.draftReminders});
  final Occurrence? occurrence;
  final Task? draft;
  final List<int>? draftReminders;

  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController titleCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController urlCtrl;
  late final TextEditingController estimateCtrl;
  final _subtaskCtrl = TextEditingController();

  bool hasDate = true;
  bool allDay = false;
  late DateTime start;
  int durationMin = 60;
  int? categoryId;
  int? projectId;
  Priority priority = Priority.medium;
  bool pinned = false;
  bool countdown = false;
  String? rrule;
  List<int> reminders = [];
  List<Subtask> subtasks = [];

  bool get editing => widget.occurrence != null;

  @override
  void initState() {
    super.initState();
    final snap = ref.read(snapshotProvider);
    final settings = ref.read(settingsProvider);
    final now = ref.read(clockProvider).now();
    final t = widget.occurrence?.task ?? widget.draft;
    titleCtrl = TextEditingController(text: t?.title ?? '');
    notesCtrl = TextEditingController(text: t?.notes ?? '');
    locationCtrl = TextEditingController(text: t?.location ?? '');
    urlCtrl = TextEditingController(text: t?.url ?? '');
    estimateCtrl = TextEditingController(text: t?.estimateMin?.toString() ?? '');
    if (t != null) {
      hasDate = t.start != null;
      allDay = t.allDay;
      start = t.start ?? _nextSlot(now);
      durationMin = t.durationMin ?? 60;
      categoryId = t.categoryId;
      projectId = t.projectId;
      priority = t.priority;
      pinned = t.pinned;
      countdown = t.countdown;
      rrule = widget.occurrence?.series.rrule ?? t.rrule;
    } else {
      start = _nextSlot(now);
    }
    if (widget.occurrence != null) {
      final id = widget.occurrence!.taskId;
      reminders = snap.remindersOf(id).map((r) => r.minutesBefore).toList()..sort();
      subtasks = [...snap.subtasksOf(id)];
    } else {
      reminders = widget.draftReminders ??
          (settings.defaultReminder >= 0 ? [settings.defaultReminder] : []);
    }
  }

  DateTime _nextSlot(DateTime now) {
    final t = now.add(const Duration(hours: 1));
    return DateTime(t.year, t.month, t.day, t.hour);
  }

  @override
  void dispose() {
    for (final c in [titleCtrl, notesCtrl, locationCtrl, urlCtrl, estimateCtrl, _subtaskCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get end => start.add(Duration(minutes: durationMin));

  Task _buildTask() {
    final now = ref.read(clockProvider).now();
    final base = widget.occurrence?.task;
    final s = hasDate ? (allDay ? dateOnly(start) : start) : null;
    return Task(
      id: base?.id,
      title: titleCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
      start: s,
      durationMin: allDay ? null : durationMin,
      allDay: hasDate && allDay,
      categoryId: categoryId,
      priority: priority,
      location: locationCtrl.text.trim(),
      url: urlCtrl.text.trim(),
      pinned: pinned,
      countdown: countdown,
      estimateMin: int.tryParse(estimateCtrl.text.trim()),
      status: base?.status ?? TaskStatus.pending,
      completedAt: base?.completedAt,
      rrule: hasDate && rrule != null && rrule!.isNotEmpty ? rrule : null,
      tz: base?.tz ?? ref.read(timeZoneProvider),
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
      projectId: projectId,
      icsUid: base?.icsUid ?? widget.occurrence?.series.icsUid,
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ui = Ui.of(context);
    final l = ui.l;
    final service = ui.service;
    final task = _buildTask();
    final o = widget.occurrence;
    final overlap = ui.overlap(task.start, task.end, excludeKey: o?.key, allDay: task.allDay);

    if (o == null) {
      final subs = [...subtasks];
      final rems = [...reminders];
      Navigator.pop(context);
      final point = await ui.repo.withUndo(const [], () async => [
            await service.create(task, subtasks: subs, reminders: rems),
          ]);
      ui.undo(point, overlap ?? l.taskSaved);
      return;
    }

    SeriesScope scope = SeriesScope.all;
    List<DateTime> selected = const [];
    if (o.isSeries) {
      final s = await askScope(context, deleting: false);
      if (s == null || !mounted) return;
      scope = s;
      if (s == SeriesScope.selected) {
        final picked = await pickOccurrences(context, o);
        if (picked == null || picked.isEmpty || !mounted) return;
        selected = picked;
      }
    }
    final perOccurrence = scope == SeriesScope.thisOne || scope == SeriesScope.selected;
    final subs = [...subtasks];
    final rems = [...reminders];
    Navigator.pop(context);
    final point = await service.edit(
      o,
      task,
      scope: scope,
      selectedDates: selected,
      subtasks: perOccurrence ? null : subs,
      reminders: perOccurrence ? null : rems,
    );
    ui.undo(point, overlap ?? l.taskSaved);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(start.year - 10),
      lastDate: DateTime(start.year + 20),
    );
    if (d != null) setState(() => start = withTimeOf(d, start));
  }

  Future<void> _pickStartTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
    if (t != null) {
      setState(() => start = DateTime(start.year, start.month, start.day, t.hour, t.minute));
    }
  }

  Future<void> _pickEndTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
    if (t == null) return;
    var e = DateTime(start.year, start.month, start.day, t.hour, t.minute);
    if (!e.isAfter(start)) e = e.add(const Duration(days: 1));
    setState(() => durationMin = e.difference(start).inMinutes.clamp(5, 24 * 60));
  }

  Future<void> _addCustomReminder() async {
    final l = context.l10n;
    final ctrl = TextEditingController();
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.customReminder),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.minutesBeforeLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
              child: Text(l.ok)),
        ],
      ),
    );
    if (v != null && v >= 0 && !reminders.contains(v)) {
      setState(() => reminders = [...reminders, v]..sort());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final snap = ref.watch(snapshotProvider);
    final rule = RecurrenceRule.tryParse(rrule);
    const presets = [0, 5, 15, 30, 60, 1440];

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l.editTask : l.newTask),
        actions: [
          TextButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: titleCtrl,
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: InputDecoration(labelText: l.title),
              validator: (v) => (v == null || v.trim().isEmpty) ? l.titleRequired : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.noDate),
              secondary: const Icon(PhosphorIconsRegular.tray),
              value: !hasDate,
              onChanged: (v) => setState(() => hasDate = !v),
            ),
            if (hasDate) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.allDay),
                secondary: const Icon(PhosphorIconsRegular.sun),
                value: allDay,
                onChanged: (v) => setState(() => allDay = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(PhosphorIconsRegular.calendarBlank),
                title: Text(f.fullDate(start)),
                onTap: _pickDate,
              ),
              if (!allDay)
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(PhosphorIconsRegular.clock),
                        title: Text('${l.startTime} ${f.time(start)}'),
                        onTap: _pickStartTime,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${l.endTime} ${f.time(end)}'),
                        subtitle: Text(f.duration(durationMin)),
                        onTap: _pickEndTime,
                      ),
                    ),
                  ],
                ),
              if (!allDay)
                Wrap(
                  spacing: 6,
                  children: [
                    for (final m in [15, 30, 45, 60, 90, 120])
                      ChoiceChip(
                        label: Text(f.duration(m)),
                        selected: durationMin == m,
                        onSelected: (_) => setState(() => durationMin = m),
                      ),
                  ],
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(PhosphorIconsRegular.repeat),
                title: Text(rule == null ? l.noRepeat : describeRule(l, f, rule, start)),
                onTap: () async {
                  final r = await showRecurrenceEditor(context, rule, start);
                  if (r != null) setState(() => rrule = r.isEmpty ? null : r);
                },
              ),
              const Divider(),
              Text(l.reminders, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final m in {...presets, ...reminders}.toList()..sort())
                    FilterChip(
                      label: Text(reminderLabel(l, m)),
                      selected: reminders.contains(m),
                      onSelected: (v) => setState(() {
                        reminders = v ? ([...reminders, m]..sort()) : (reminders..remove(m));
                      }),
                    ),
                  ActionChip(label: Text(l.customReminder), onPressed: _addCustomReminder),
                ],
              ),
            ],
            const Divider(height: 24),
            DropdownButtonFormField<int?>(
              initialValue: snap.categoryById(categoryId) == null ? null : categoryId,
              decoration: InputDecoration(labelText: l.category),
              items: [
                DropdownMenuItem(value: null, child: Text(l.noCategory)),
                for (final c in snap.categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(children: [
                      CircleAvatar(radius: 7, backgroundColor: Color(c.color)),
                      const SizedBox(width: 8),
                      Text(c.name),
                    ]),
                  ),
              ],
              onChanged: (v) => setState(() => categoryId = v),
            ),
            if (snap.projects.isNotEmpty || projectId != null) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: snap.projectById(projectId) == null ? null : projectId,
                decoration: InputDecoration(labelText: l.project),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.noProject)),
                  for (final p in snap.projects.where((p) => !p.archived))
                    DropdownMenuItem(
                      value: p.id,
                      child: Row(children: [
                        Icon(PhosphorIconsFill.folder, size: 18, color: Color(p.color)),
                        const SizedBox(width: 8),
                        Text(p.name),
                      ]),
                    ),
                ],
                onChanged: (v) => setState(() => projectId = v),
              ),
            ],
            const SizedBox(height: 16),
            Text(l.priority, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            SegmentedButton<Priority>(
              segments: [
                for (final p in Priority.values)
                  ButtonSegment(
                    value: p,
                    label: Text(priorityLabel(l, p)),
                    icon: Icon(PhosphorIconsFill.flag, color: priorityColor(p)),
                  ),
              ],
              selected: {priority},
              onSelectionChanged: (v) => setState(() => priority = v.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesCtrl,
              maxLines: null,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.notes, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Text(l.subtasks, style: Theme.of(context).textTheme.titleSmall),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: true,
              onReorderItem: (a, b) => setState(() {
                final s = subtasks.removeAt(a);
                subtasks.insert(b, s);
              }),
              children: [
                for (var i = 0; i < subtasks.length; i++)
                  CheckboxListTile(
                    key: ValueKey('sub-$i-${subtasks[i].title}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: subtasks[i].done,
                    title: Text(subtasks[i].title),
                    secondary: IconButton(
                      icon: const Icon(PhosphorIconsRegular.x),
                      onPressed: () => setState(() => subtasks.removeAt(i)),
                    ),
                    onChanged: (v) =>
                        setState(() => subtasks[i] = subtasks[i].copyWith(done: v ?? false)),
                  ),
              ],
            ),
            TextField(
              controller: _subtaskCtrl,
              decoration: InputDecoration(
                hintText: l.addSubtask,
                prefixIcon: const Icon(PhosphorIconsRegular.plus),
              ),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                setState(() {
                  subtasks.add(Subtask(taskId: 0, title: v.trim(), order: subtasks.length));
                  _subtaskCtrl.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: locationCtrl,
              decoration: InputDecoration(labelText: l.location, prefixIcon: const Icon(PhosphorIconsRegular.mapPin)),
            ),
            TextFormField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l.link, prefixIcon: const Icon(PhosphorIconsRegular.link)),
            ),
            TextFormField(
              controller: estimateCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.estimate, prefixIcon: const Icon(PhosphorIconsRegular.timer)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(PhosphorIconsRegular.pushPin),
              title: Text(l.pinned),
              value: pinned,
              onChanged: (v) => setState(() => pinned = v),
            ),
            if (hasDate)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(PhosphorIconsRegular.hourglassMedium),
                title: Text(l.countdownLabel),
                value: countdown,
                onChanged: (v) => setState(() => countdown = v),
              ),
          ],
        ),
      ),
    );
  }
}
