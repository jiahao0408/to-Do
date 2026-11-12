// Importar un proyecto pegando texto (p. ej. la respuesta de una IA) o
// abriendo un .md/.txt. Vista previa en vivo antes de crear nada.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/project_importer.dart';
import '../../domain/nlp/quick_parser.dart';
import '../../domain/project_import.dart';
import '../../domain/village/building.dart';
import '../common/format.dart';
import '../common/ph_icons.dart';
import '../providers.dart';
import '../village/building_widgets.dart';
import 'categories_screen.dart';
import 'projects_screen.dart';

class ProjectImportScreen extends ConsumerStatefulWidget {
  const ProjectImportScreen({super.key, this.initialText});
  final String? initialText;

  @override
  ConsumerState<ProjectImportScreen> createState() => _ProjectImportScreenState();
}

class _ProjectImportScreenState extends ConsumerState<ProjectImportScreen> {
  final _text = TextEditingController();
  final _title = TextEditingController();
  bool _titleEdited = false;
  ImportedProject? _parsed;
  late int _color = kPalette[(ref.read(snapshotProvider).projects.length * 3 + 2) % kPalette.length];
  String _building = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _text.text = widget.initialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reparse());
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _title.dispose();
    super.dispose();
  }

  void _reparse() {
    final snap = ref.read(snapshotProvider);
    final p = parseProjectMarkdown(
      _text.text,
      dates: QuickParser(
        now: ref.read(clockProvider).now(),
        categories: {for (final c in snap.categories) c.name: c.id!},
        weekStartsMonday: ref.read(settingsProvider).weekStartsMonday,
      ),
    );
    setState(() {
      _parsed = p;
      if (!_titleEdited) _title.text = p.title;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    _text.text = data!.text!;
    _reparse();
  }

  Future<void> _openFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['md', 'txt', 'markdown']);
    final path = files.isEmpty ? null : files.first.path;
    if (path == null) return;
    try {
      _text.text = await File(path).readAsString();
      _reparse();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.importReadError)));
    }
  }

  Future<void> _copyPrompt() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: l.importPrompt));
    messenger.showSnackBar(SnackBar(content: Text(l.importPromptCopied)));
  }

  Future<void> _create() async {
    final p = _parsed;
    if (p == null || p.modules.isEmpty || _saving) return;
    final l = context.l10n;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final title = _title.text.trim().isEmpty ? l.importDefaultTitle : _title.text.trim();
    final id = await ProjectImporter(ref.read(repositoryProvider)).save(
      p,
      title: title,
      color: _color,
      building: _building.isEmpty ? null : _building,
      tz: ref.read(timeZoneProvider),
    );
    messenger.showSnackBar(SnackBar(content: Text(l.importDone)));
    nav.pushReplacement(MaterialPageRoute(builder: (_) => ProjectScreen(projectId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = Fmt.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = _parsed;
    final ready = p != null && p.modules.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.importProject)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            icon: const Icon(PhosphorIconsRegular.check),
            label: Text(l.importCreate),
            onPressed: ready && !_saving ? _create : null,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(l.importProjectHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              icon: const Icon(PhosphorIconsRegular.sparkle),
              label: Text(l.importCopyPrompt),
              onPressed: _copyPrompt,
            ),
            OutlinedButton.icon(
              icon: const Icon(PhosphorIconsRegular.clipboardText),
              label: Text(l.importPaste),
              onPressed: _paste,
            ),
            OutlinedButton.icon(
              icon: const Icon(PhosphorIconsRegular.fileText),
              label: Text(l.importFile),
              onPressed: _openFile,
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('import-text'),
            controller: _text,
            minLines: 6,
            maxLines: 14,
            style: theme.textTheme.bodyMedium!.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['monospace']),
            decoration: InputDecoration(labelText: l.importText, alignLabelWithHint: true),
            onChanged: (_) => _reparse(),
          ),
          const SizedBox(height: 20),
          Text(l.importPreview, style: theme.textTheme.titleSmall!.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          if (!ready)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l.importNothing, style: theme.textTheme.bodyMedium!.copyWith(color: scheme.onSurfaceVariant)),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final b = await pickBuilding(context, color: Color(_color), current: _building);
                    if (b != null) setState(() => _building = b);
                  },
                  child: BuildingThumb(
                    type: _building.isEmpty ? BuildingType.house : BuildingType.parse(_building),
                    color: Color(_color),
                    size: 56,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('import-title'),
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: l.projectName, hintText: l.importDefaultTitle),
                    onChanged: (_) => _titleEdited = true,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final c = await pickColor(context, _color);
                    if (c != null) setState(() => _color = c);
                  },
                  child: CircleAvatar(backgroundColor: Color(_color), radius: 16),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text(l.importSummary(p.modules.length, p.subtaskCount), style: theme.textTheme.labelLarge),
            for (final m in p.modules)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: Color(_color), width: 4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(m.done ? PhosphorIconsRegular.checkSquare : PhosphorIconsRegular.square,
                        size: 18, color: Color(_color)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.title, style: theme.textTheme.titleSmall)),
                  ]),
                  if (m.start != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 2),
                      child: Text(
                        m.allDay ? f.fullDate(m.start!) : '${f.weekdayDayMonth(m.start!)} ${f.time(m.start!)}',
                        style: theme.textTheme.labelMedium!.copyWith(color: scheme.primary),
                      ),
                    ),
                  for (final s in m.subtasks)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 4),
                      child: Text('${s.done ? '✓' : '•'}  ${s.title}', style: theme.textTheme.bodySmall),
                    ),
                ]),
              ),
          ],
        ],
      ),
    );
  }
}
