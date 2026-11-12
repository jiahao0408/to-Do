// RF-52 / RF-53: copia de seguridad exportable/importable.
//
// Formato: un .zip con `backup.json` (todas las tablas + versión del
// esquema) y la carpeta `attachments/` con los archivos adjuntos.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../domain/settings.dart';
import 'db/database.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupService {
  BackupService(this.db, {required this.attachmentsDir});
  final AppDatabase db;

  /// Carpeta donde viven los adjuntos (rutas guardadas relativas a ella).
  final Directory attachmentsDir;

  static const formatVersion = 1;

  Future<Map<String, Object?>> exportJson() async {
    List<Map<String, dynamic>> rows(List<DataClass> list) =>
        [for (final r in list) r.toJson(serializer: const _Iso())];
    return {
      'format': 'todo_calendar_backup',
      'formatVersion': formatVersion,
      'schemaVersion': db.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tables': {
        'tasks': rows(await db.select(db.tasks).get()),
        'subtasks': rows(await db.select(db.subtasks).get()),
        'categories': rows(await db.select(db.categories).get()),
        'reminders': rows(await db.select(db.reminders).get()),
        'attachments': rows(await db.select(db.attachments).get()),
        'seriesExceptions': rows(await db.select(db.seriesExceptions).get()),
        'occurrenceCompletions': rows(await db.select(db.occurrenceCompletions).get()),
        'timeEntries': rows(await db.select(db.timeEntries).get()),
        'templates': rows(await db.select(db.templates).get()),
        'settings': rows(await db.select(db.settings).get()),
        'projects': rows(await db.select(db.projects).get()),
        'dayNotes': rows(await db.select(db.dayNotes).get()),
      },
    };
  }

  /// Crea el .zip en [outDir] y devuelve el archivo.
  Future<File> exportZip(Directory outDir) async {
    final json = await exportJson();
    final archive = Archive();
    final bytes = utf8.encode(const JsonEncoder.withIndent(' ').convert(json));
    archive.addFile(ArchiveFile('backup.json', bytes.length, bytes));
    if (attachmentsDir.existsSync()) {
      for (final f in attachmentsDir.listSync(recursive: true).whereType<File>()) {
        final rel = p.relative(f.path, from: attachmentsDir.path).replaceAll('\\', '/');
        final data = await f.readAsBytes();
        archive.addFile(ArchiveFile('attachments/$rel', data.length, data));
      }
    }
    final stamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '-');
    final out = File(p.join(outDir.path, 'calendario-backup-$stamp.zip'));
    await out.writeAsBytes(ZipEncoder().encode(archive));
    return out;
  }

  /// Restaura desde un .zip (o un .json suelto). Reemplaza todos los datos.
  Future<void> importFile(File file) async {
    final bytes = await file.readAsBytes();
    Map<String, Object?> json;
    final attachments = <String, List<int>>{};
    if (file.path.toLowerCase().endsWith('.json')) {
      json = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, Object?>();
    } else {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entry = archive.findFile('backup.json');
      if (entry == null) throw BackupException('backup.json no encontrado');
      json = (jsonDecode(utf8.decode(entry.content as List<int>)) as Map).cast<String, Object?>();
      for (final f in archive.files) {
        if (f.isFile && f.name.startsWith('attachments/')) {
          attachments[f.name.substring('attachments/'.length)] = f.content as List<int>;
        }
      }
    }
    await importJson(json);
    // Archivos adjuntos.
    if (attachmentsDir.existsSync()) await attachmentsDir.delete(recursive: true);
    await attachmentsDir.create(recursive: true);
    for (final e in attachments.entries) {
      final safe = p.normalize(e.key);
      if (safe.startsWith('..') || p.isAbsolute(safe)) continue;
      final f = File(p.join(attachmentsDir.path, safe));
      await f.parent.create(recursive: true);
      await f.writeAsBytes(e.value);
    }
  }

  Future<void> importJson(Map<String, Object?> json) async {
    if (json['format'] != 'todo_calendar_backup') {
      throw BackupException('No es una copia de esta app');
    }
    final schema = json['schemaVersion'] as int? ?? 1;
    if (schema > db.schemaVersion) {
      throw BackupException('La copia es de una versión más nueva de la app');
    }
    final tables = (json['tables'] as Map).cast<String, Object?>();
    List<Map<String, dynamic>> rows(String name) => [
          for (final r in (tables[name] as List? ?? const [])) _migrateRow(name, (r as Map).cast<String, dynamic>(), schema),
        ];

    await db.transaction(() async {
      // Orden: hijos primero al borrar; padres primero al insertar.
      for (final t in db.allTables.toList().reversed) {
        await db.delete(t).go();
      }
      const ser = _Iso();
      Future<void> put<T extends Table, R>(TableInfo<T, R> table, String name, R Function(Map<String, dynamic>, {ValueSerializer? serializer}) fromJson) async {
        for (final r in rows(name)) {
          await db.into(table).insert(fromJson(r, serializer: ser) as Insertable<R>);
        }
      }

      await put(db.categories, 'categories', CategoryRow.fromJson);
      await put(db.projects, 'projects', ProjectRow.fromJson);
      await put(db.tasks, 'tasks', TaskRow.fromJson);
      await put(db.subtasks, 'subtasks', SubtaskRow.fromJson);
      await put(db.reminders, 'reminders', ReminderRow.fromJson);
      await put(db.attachments, 'attachments', AttachmentRow.fromJson);
      await put(db.seriesExceptions, 'seriesExceptions', SeriesExceptionRow.fromJson);
      await put(db.occurrenceCompletions, 'occurrenceCompletions', CompletionRow.fromJson);
      await put(db.timeEntries, 'timeEntries', TimeEntryRow.fromJson);
      await put(db.templates, 'templates', TemplateRow.fromJson);
      await put(db.settings, 'settings', SettingRow.fromJson);
      await put(db.dayNotes, 'dayNotes', DayNoteRow.fromJson);
      // La ballenita no debe «comerse» las tareas completadas de la copia.
      await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: AppSettings.kVillagerRebase, value: '1'));
    });
  }

  /// Adapta filas de esquemas antiguos al actual. Un bloque por versión.
  Map<String, dynamic> _migrateRow(String table, Map<String, dynamic> row, int fromSchema) {
    // if (fromSchema < 2 && table == 'tasks') row['nuevoCampo'] ??= valorPorDefecto;
    return row;
  }
}

/// Fechas como texto ISO 8601 en el JSON (legible y estable).
class _Iso extends ValueSerializer {
  const _Iso();

  @override
  T fromJson<T>(dynamic json) {
    if (json == null) return null as T;
    final typeList = <T>[];
    if (typeList is List<DateTime?>) {
      if (json is int) return DateTime.fromMillisecondsSinceEpoch(json) as T;
      return DateTime.parse(json as String).toLocal() as T;
    }
    if (typeList is List<double?> && json is int) return json.toDouble() as T;
    if (typeList is List<bool?> && json is int) return (json != 0) as T;
    return json as T;
  }

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return value;
  }
}
