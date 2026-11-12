import '../time.dart';
import 'task.dart';

class Subtask {
  const Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.done = false,
    this.order = 0,
  });
  final int? id;
  final int taskId;
  final String title;
  final bool done;
  final int order;

  Subtask copyWith({int? id, int? taskId, String? title, bool? done, int? order}) =>
      Subtask(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        title: title ?? this.title,
        done: done ?? this.done,
        order: order ?? this.order,
      );
}

class Category {
  const Category({this.id, required this.name, required this.color});
  final int? id;
  final String name;

  /// Color ARGB.
  final int color;

  Category copyWith({String? name, int? color}) =>
      Category(id: id, name: name ?? this.name, color: color ?? this.color);
}

class Reminder {
  const Reminder({this.id, required this.taskId, required this.minutesBefore});
  final int? id;
  final int taskId;

  /// 0 = a la hora; 5, 15, 30, 60 o cualquier valor personalizado.
  final int minutesBefore;
}

enum AttachmentType { image, file }

class Attachment {
  const Attachment({
    this.id,
    required this.taskId,
    required this.path,
    required this.name,
    required this.type,
    required this.size,
  });
  final int? id;
  final int taskId;

  /// Ruta relativa a la carpeta de adjuntos de la app.
  final String path;
  final String name;
  final AttachmentType type;
  final int size;
}

enum ExceptionType { skipped, modified }

/// Excepción de una ocurrencia concreta de una serie (RF-23 a RF-26).
class SeriesException {
  const SeriesException({
    this.id,
    required this.seriesId,
    required this.originalDate,
    required this.type,
    this.overrides = const {},
  });
  final int? id;
  final int seriesId;

  /// Fecha original de la ocurrencia (solo fecha).
  final DateTime originalDate;
  final ExceptionType type;
  final Map<String, Object?> overrides;

  String get dateKey => formatDateKey(originalDate);
}

/// Completado de una ocurrencia de una serie (RF-27).
class OccurrenceCompletion {
  const OccurrenceCompletion({
    this.id,
    required this.seriesId,
    required this.occurrenceDate,
    required this.completedAt,
  });
  final int? id;
  final int seriesId;
  final DateTime occurrenceDate;
  final DateTime completedAt;
}

/// Registro del cronómetro de tiempo real dedicado (RF-10).
class TimeEntry {
  const TimeEntry({
    this.id,
    required this.taskId,
    this.occurrenceDate,
    required this.start,
    this.end,
  });
  final int? id;
  final int taskId;
  final DateTime? occurrenceDate;
  final DateTime start;
  final DateTime? end;

  bool get running => end == null;
  Duration elapsed(DateTime now) => (end ?? now).difference(start);
}

/// Elemento de una plantilla / rutina (RF-16).
class TemplateItem {
  const TemplateItem({
    required this.title,
    this.startMinute,
    this.durationMin,
    this.categoryId,
    this.priority = Priority.medium,
  });
  final String title;

  /// Minutos desde medianoche; null = sin hora.
  final int? startMinute;
  final int? durationMin;
  final int? categoryId;
  final Priority priority;

  Map<String, Object?> toJson() => {
        'title': title,
        'startMinute': startMinute,
        'durationMin': durationMin,
        'categoryId': categoryId,
        'priority': priority.name,
      };

  factory TemplateItem.fromJson(Map<String, Object?> j) => TemplateItem(
        title: j['title'] as String,
        startMinute: j['startMinute'] as int?,
        durationMin: j['durationMin'] as int?,
        categoryId: j['categoryId'] as int?,
        priority: Priority.values.byName((j['priority'] as String?) ?? 'medium'),
      );
}

class TaskTemplate {
  const TaskTemplate({this.id, required this.name, required this.items});
  final int? id;
  final String name;
  final List<TemplateItem> items;
}

/// v2: proyecto (aparte de la categoría), con fecha límite opcional.
class Project {
  const Project({
    this.id,
    required this.name,
    required this.color,
    this.dueDate,
    this.archived = false,
    this.building,
  });
  final int? id;
  final String name;
  final int color;
  final DateTime? dueDate;
  final bool archived;

  /// v3: edificio de la aldea (nombre de `BuildingType`); null = automático.
  final String? building;

  Project copyWith({String? name, int? color, DateTime? Function()? dueDate, bool? archived, String? building}) =>
      Project(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        dueDate: dueDate != null ? dueDate() : this.dueDate,
        archived: archived ?? this.archived,
        building: building ?? this.building,
      );
}

/// v2: nota del diario de un día.
class DayNote {
  const DayNote({required this.date, required this.body, required this.updatedAt});
  final DateTime date;
  final String body;
  final DateTime updatedAt;
}
