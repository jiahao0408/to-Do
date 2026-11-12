// Importar un proyecto desde texto Markdown (por ejemplo, la respuesta de una
// IA). Proyecto = título; módulo = tarea del proyecto; lo de debajo = subtarea.
//
// Reglas:
// - Si el nivel de encabezado más alto aparece una sola vez, es el título y el
//   siguiente nivel son los módulos. Si aparece varias veces, son módulos.
// - Encabezados más profundos que los módulos y los puntos de lista dentro de
//   un módulo son subtareas (las anidadas se aplanan, en orden).
// - Sin encabezados de módulo, los puntos de primer nivel son los módulos.
// - El texto suelto dentro de un módulo pasa a su nota; fuera, se ignora
//   (salvo la primera línea, que sirve de título si no hay encabezado).
// - Con [dates], las fechas, horas y prioridades de un módulo se leen con el
//   analizador de texto natural y se quitan del título.

import 'models/task.dart';
import 'nlp/quick_parser.dart';
import 'time.dart';

class ImportedSubtask {
  const ImportedSubtask(this.title, {this.done = false});
  final String title;
  final bool done;
}

class ImportedModule {
  ImportedModule(this.title, {this.done = false});
  String title;
  bool done;
  String notes = '';
  final List<ImportedSubtask> subtasks = [];
  DateTime? start;
  bool allDay = false;
  int? durationMin;
  Priority? priority;
}

class ImportedProject {
  ImportedProject(this.title, this.modules);
  final String title;
  final List<ImportedModule> modules;

  int get subtaskCount => modules.fold(0, (n, m) => n + m.subtasks.length);
}

sealed class _Line {}

class _Heading extends _Line {
  _Heading(this.level, this.text);
  final int level;
  final String text;
}

class _Item extends _Line {
  _Item(this.indent, this.text, this.done);
  final int indent;
  final String text;
  final bool done;
}

class _Text extends _Line {
  _Text(this.text);
  final String text;
}

final _heading = RegExp(r'^(#{1,6})\s+(.*?)\s*#*\s*$');
final _item = RegExp(r'^(\s*)(?:[-*+•]|\d+[.)])\s+(?:\[([ xX])\]\s+)?(.*)$');
final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');

/// Quita el Markdown en línea: negritas, cursivas, código, enlaces y la
/// numeración inicial («1.», «1)»).
String cleanInline(String s) {
  var t = s.trim();
  t = t.replaceAllMapped(RegExp(r'!?\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1)!);
  t = t.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m.group(1)!);
  t = t.replaceAllMapped(RegExp(r'(\*\*|__)(.+?)\1'), (m) => m.group(2)!);
  t = t.replaceAllMapped(RegExp(r'(?<![\w*])([*_])(?!\s)(.+?)(?<!\s)\1(?![\w*])'), (m) => m.group(2)!);
  t = t.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<_Line> _lines(String text) {
  final out = <_Line>[];
  var fenced = false;
  for (final raw in text.replaceAll('\r\n', '\n').replaceAll('\t', '    ').split('\n')) {
    if (raw.trimLeft().startsWith('```') || raw.trimLeft().startsWith('~~~')) {
      fenced = !fenced;
      continue;
    }
    if (fenced || raw.trim().isEmpty || _rule.hasMatch(raw)) continue;
    final h = _heading.firstMatch(raw.trim());
    if (h != null) {
      final t = cleanInline(h.group(2)!);
      if (t.isNotEmpty) out.add(_Heading(h.group(1)!.length, t));
      continue;
    }
    final i = _item.firstMatch(raw);
    if (i != null) {
      final t = cleanInline(i.group(3)!);
      if (t.isNotEmpty) out.add(_Item(i.group(1)!.length, t, (i.group(2) ?? ' ').toLowerCase() == 'x'));
      continue;
    }
    final t = cleanInline(raw);
    if (t.isNotEmpty) out.add(_Text(t));
  }
  return out;
}

ImportedProject parseProjectMarkdown(String text, {QuickParser? dates}) {
  final lines = _lines(text);
  final headings = lines.whereType<_Heading>().toList();
  var title = '';
  int? titleLevel;
  int? moduleLevel;
  if (headings.isNotEmpty) {
    final top = headings.map((h) => h.level).reduce((a, b) => a < b ? a : b);
    if (headings.where((h) => h.level == top).length == 1) {
      titleLevel = top;
      final below = headings.where((h) => h.level > top).map((h) => h.level);
      moduleLevel = below.isEmpty ? null : below.reduce((a, b) => a < b ? a : b);
    } else {
      moduleLevel = top;
    }
  }

  final modules = <ImportedModule>[];
  ImportedModule? current;
  int? baseIndent; // sangría de los módulos cuando son puntos de lista

  for (final l in lines) {
    switch (l) {
      case _Heading(:final level, text: final t):
        if (level == titleLevel && title.isEmpty) {
          title = t;
          current = null;
        } else if (moduleLevel != null && level == moduleLevel) {
          current = ImportedModule(t);
          modules.add(current);
        } else if (moduleLevel != null && level > moduleLevel && current != null) {
          current.subtasks.add(ImportedSubtask(t));
        }
      case _Item(:final indent, text: final t, :final done):
        if (moduleLevel != null) {
          current?.subtasks.add(ImportedSubtask(t, done: done));
        } else {
          baseIndent ??= indent;
          if (indent <= baseIndent) {
            current = ImportedModule(t, done: done);
            modules.add(current);
          } else {
            current?.subtasks.add(ImportedSubtask(t, done: done));
          }
        }
      case _Text(text: final t):
        if (current != null) {
          current.notes = current.notes.isEmpty ? t : '${current.notes}\n$t';
        } else if (title.isEmpty && headings.isEmpty && modules.isEmpty) {
          title = t;
        }
    }
  }

  // Sin módulos y solo texto: la primera línea no era un título útil.
  if (modules.isEmpty && headings.isEmpty) title = '';

  if (dates != null) {
    for (final m in modules) {
      final p = dates.parse(m.title);
      if (p.date == null && p.priority == null) continue;
      if (p.title.isNotEmpty) m.title = p.title;
      m.priority = p.priority;
      if (p.date != null) {
        final d = p.date!;
        if (p.time != null) {
          m.start = DateTime(d.year, d.month, d.day, p.time!.hour, p.time!.minute);
        } else {
          m.start = dateOnly(d);
          m.allDay = true;
        }
        m.durationMin = p.durationMin;
      }
    }
  }
  return ImportedProject(title, modules);
}
