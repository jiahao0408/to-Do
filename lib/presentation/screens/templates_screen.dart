// RF-16: plantillas / rutinas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entities.dart';
import '../../domain/models/task.dart';
import '../../domain/time.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final templates = ref.watch(snapshotProvider).templates;
    return Scaffold(
      appBar: AppBar(title: Text(l.templates)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.newTemplate,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TemplateEditor())),
        child: const Icon(Icons.add),
      ),
      body: templates.isEmpty
          ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(l.noTemplates, textAlign: TextAlign.center)))
          : ListView(
              children: [
                for (final t in templates)
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: Text(t.name),
                    subtitle: Text(t.items
                        .map((i) => i.startMinute == null
                            ? i.title
                            : '${f.time(DateTime(2000, 1, 1, 0, i.startMinute!))} ${i.title}')
                        .join(' · '),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => TemplateEditor(template: t))),
                    trailing: IconButton(
                      tooltip: l.applyTemplate,
                      icon: const Icon(Icons.playlist_add),
                      onPressed: () => applyTemplateFlow(context, ref, t),
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<void> applyTemplateFlow(BuildContext context, WidgetRef ref, TaskTemplate t) async {
  final ui = Ui.of(context);
  final anchor = ref.read(calendarProvider).anchor;
  final d = await showDatePicker(
    context: context,
    initialDate: anchor,
    firstDate: DateTime(anchor.year - 5),
    lastDate: DateTime(anchor.year + 10),
  );
  if (d == null) return;
  final point = await ui.service.applyTemplate(t, d, ui.read(timeZoneProvider));
  ui.undo(point, ui.l.templateApplied);
}

/// Guarda las tareas con hora de [day] como plantilla.
Future<void> saveDayAsTemplate(BuildContext context, WidgetRef ref, DateTime day) async {
  final l = context.l10n;
  final ui = Ui.of(context);
  final items = ref.read(snapshotProvider).occurrencesOnDay(day);
  if (items.isEmpty) return;
  final ctrl = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.saveAsTemplate),
      content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(labelText: l.templateName)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(l.save)),
      ],
    ),
  );
  if (name == null || name.isEmpty) return;
  await ui.repo.saveTemplate(TaskTemplate(name: name, items: [
    for (final o in items)
      TemplateItem(
        title: o.task.title,
        startMinute: o.task.allDay ? null : minutesOfDay(o.task.start!),
        durationMin: o.task.allDay ? null : o.task.durationMin,
        categoryId: o.task.categoryId,
        priority: o.task.priority,
      ),
  ]));
  ui.message(l.taskSaved);
}

class TemplateEditor extends ConsumerStatefulWidget {
  const TemplateEditor({super.key, this.template});
  final TaskTemplate? template;

  @override
  ConsumerState<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<TemplateEditor> {
  late final _name = TextEditingController(text: widget.template?.name ?? '');
  late List<TemplateItem> items = [...?widget.template?.items];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _editItem([int? index]) async {
    final l = context.l10n;
    final f = Fmt.of(context);
    final current = index == null ? null : items[index];
    final title = TextEditingController(text: current?.title ?? '');
    int? start = current?.startMinute ?? 9 * 60;
    int duration = current?.durationMin ?? 60;
    final result = await showDialog<TemplateItem>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.addItem),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, autofocus: true, decoration: InputDecoration(labelText: l.title)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.allDay),
                value: start == null,
                onChanged: (v) => setState(() => start = v ? null : 9 * 60),
              ),
              if (start != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(f.time(DateTime(2000, 1, 1, 0, start!))),
                  trailing: DropdownButton<int>(
                    value: duration,
                    items: [
                      for (final m in {15, 30, 45, 60, 90, 120, duration})
                        DropdownMenuItem(value: m, child: Text(f.duration(m))),
                    ],
                    onChanged: (v) => setState(() => duration = v ?? 60),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: ctx, initialTime: TimeOfDay(hour: start! ~/ 60, minute: start! % 60));
                    if (t != null) setState(() => start = t.hour * 60 + t.minute);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            FilledButton(
              onPressed: () => title.text.trim().isEmpty
                  ? null
                  : Navigator.pop(
                      ctx,
                      TemplateItem(
                        title: title.text.trim(),
                        startMinute: start,
                        durationMin: start == null ? null : duration,
                        categoryId: current?.categoryId,
                        priority: current?.priority ?? Priority.medium,
                      )),
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        items.add(result);
      } else {
        items[index] = result;
      }
      items.sort((a, b) => (a.startMinute ?? -1).compareTo(b.startMinute ?? -1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? l.newTemplate : l.edit),
        actions: [
          if (widget.template != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
              onPressed: () async {
                await repo.deleteTemplate(widget.template!.id!);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          TextButton(
            onPressed: () async {
              if (_name.text.trim().isEmpty) return;
              await repo.saveTemplate(TaskTemplate(id: widget.template?.id, name: _name.text.trim(), items: items));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editItem(),
        icon: const Icon(Icons.add),
        label: Text(l.addItem),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: InputDecoration(labelText: l.templateName)),
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(items[i].startMinute == null
                  ? l.allDayShort
                  : f.time(DateTime(2000, 1, 1, 0, items[i].startMinute!))),
              title: Text(items[i].title),
              subtitle: items[i].durationMin == null ? null : Text(f.duration(items[i].durationMin!)),
              onTap: () => _editItem(i),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => items.removeAt(i)),
              ),
            ),
        ],
      ),
    );
  }
}
