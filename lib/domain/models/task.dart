import '../recurrence/recurrence_rule.dart';
import '../time.dart';

enum Priority { high, medium, low }

enum TaskStatus { pending, completed, discarded }

/// Tarea o evento (una sola entidad). Si [rrule] no es null, es una serie
/// repetida y cada ocurrencia se completa, edita o salta por separado.
class Task {
  const Task({
    this.id,
    required this.title,
    this.notes = '',
    this.start,
    this.durationMin,
    this.allDay = false,
    this.categoryId,
    this.priority = Priority.medium,
    this.location = '',
    this.url = '',
    this.pinned = false,
    this.countdown = false,
    this.estimateMin,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.rrule,
    this.tz = 'UTC',
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String notes;

  /// Hora de inicio (hora de pared local). Null = tarea sin hora (bandeja).
  final DateTime? start;
  final int? durationMin;
  final bool allDay;
  final int? categoryId;
  final Priority priority;
  final String location;
  final String url;
  final bool pinned;
  final bool countdown;
  final int? estimateMin;
  final TaskStatus status;
  final DateTime? completedAt;
  final String? rrule;

  /// Zona horaria IANA en la que se definió la hora de pared.
  final String tz;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const defaultDurationMin = 60;

  bool get isSeries => rrule != null && rrule!.isNotEmpty && start != null;
  bool get isUnscheduled => start == null;
  bool get isCompleted => status == TaskStatus.completed;

  RecurrenceRule? get rule => RecurrenceRule.tryParse(rrule);

  int get effectiveDurationMin =>
      allDay ? 24 * 60 : (durationMin ?? defaultDurationMin);

  DateTime? get end =>
      start?.add(Duration(minutes: effectiveDurationMin));

  Task copyWith({
    int? Function()? id,
    String? title,
    String? notes,
    DateTime? Function()? start,
    int? Function()? durationMin,
    bool? allDay,
    int? Function()? categoryId,
    Priority? priority,
    String? location,
    String? url,
    bool? pinned,
    bool? countdown,
    int? Function()? estimateMin,
    TaskStatus? status,
    DateTime? Function()? completedAt,
    String? Function()? rrule,
    String? tz,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id != null ? id() : this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      start: start != null ? start() : this.start,
      durationMin: durationMin != null ? durationMin() : this.durationMin,
      allDay: allDay ?? this.allDay,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      url: url ?? this.url,
      pinned: pinned ?? this.pinned,
      countdown: countdown ?? this.countdown,
      estimateMin: estimateMin != null ? estimateMin() : this.estimateMin,
      status: status ?? this.status,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      rrule: rrule != null ? rrule() : this.rrule,
      tz: tz ?? this.tz,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Campos que una excepción de serie puede sobrescribir.
  static const overridableFields = [
    'title',
    'notes',
    'start',
    'durationMin',
    'allDay',
    'categoryId',
    'priority',
    'location',
    'url',
    'estimateMin',
  ];

  Map<String, Object?> overridableValues() => {
        'title': title,
        'notes': notes,
        'start': start == null ? null : formatWallClock(start!),
        'durationMin': durationMin,
        'allDay': allDay,
        'categoryId': categoryId,
        'priority': priority.name,
        'location': location,
        'url': url,
        'estimateMin': estimateMin,
      };

  /// Diferencias de campos sobrescribibles entre [this] y [other].
  Map<String, Object?> diffOverridable(Task other) {
    final a = overridableValues();
    final b = other.overridableValues();
    final out = <String, Object?>{};
    for (final k in overridableFields) {
      if (a[k] != b[k]) out[k] = b[k];
    }
    return out;
  }

  /// Aplica sobrescrituras guardadas en una excepción de serie.
  Task applyOverrides(Map<String, Object?> o) {
    var t = this;
    if (o.containsKey('title')) t = t.copyWith(title: o['title'] as String);
    if (o.containsKey('notes')) t = t.copyWith(notes: o['notes'] as String);
    if (o.containsKey('start')) {
      t = t.copyWith(start: () => tryParseWallClock(o['start'] as String?));
    }
    if (o.containsKey('durationMin')) {
      t = t.copyWith(durationMin: () => o['durationMin'] as int?);
    }
    if (o.containsKey('allDay')) t = t.copyWith(allDay: o['allDay'] as bool);
    if (o.containsKey('categoryId')) {
      t = t.copyWith(categoryId: () => o['categoryId'] as int?);
    }
    if (o.containsKey('priority')) {
      t = t.copyWith(
          priority: Priority.values.byName(o['priority'] as String));
    }
    if (o.containsKey('location')) {
      t = t.copyWith(location: o['location'] as String);
    }
    if (o.containsKey('url')) t = t.copyWith(url: o['url'] as String);
    if (o.containsKey('estimateMin')) {
      t = t.copyWith(estimateMin: () => o['estimateMin'] as int?);
    }
    return t;
  }

  @override
  String toString() => 'Task($id, $title, $start, rrule=$rrule)';
}
