import 'dart:convert';

import 'package:drift/drift.dart';

import '../domain/models/entities.dart';
import '../domain/models/task.dart';
import '../domain/time.dart';
import 'db/database.dart';

Task taskFromRow(TaskRow r) => Task(
      id: r.id,
      title: r.title,
      notes: r.notes,
      start: tryParseWallClock(r.start),
      durationMin: r.durationMin,
      allDay: r.allDay,
      categoryId: r.categoryId,
      priority: Priority.values[r.priority.clamp(0, 2)],
      location: r.location,
      url: r.url,
      pinned: r.pinned,
      countdown: r.countdown,
      estimateMin: r.estimateMin,
      status: TaskStatus.values[r.status.clamp(0, 2)],
      completedAt: r.completedAt,
      rrule: r.rrule,
      tz: r.tz,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      projectId: r.projectId,
      icsUid: r.icsUid,
    );

TasksCompanion taskToCompanion(Task t, {bool includeId = false}) =>
    TasksCompanion(
      id: includeId && t.id != null ? Value(t.id!) : const Value.absent(),
      title: Value(t.title),
      notes: Value(t.notes),
      start: Value(t.start == null ? null : formatWallClock(t.start!)),
      durationMin: Value(t.durationMin),
      allDay: Value(t.allDay),
      categoryId: Value(t.categoryId),
      priority: Value(t.priority.index),
      location: Value(t.location),
      url: Value(t.url),
      pinned: Value(t.pinned),
      countdown: Value(t.countdown),
      estimateMin: Value(t.estimateMin),
      status: Value(t.status.index),
      completedAt: Value(t.completedAt),
      rrule: Value(t.rrule),
      tz: Value(t.tz),
      createdAt: Value(t.createdAt),
      updatedAt: Value(t.updatedAt),
      projectId: Value(t.projectId),
      icsUid: Value(t.icsUid),
    );

Subtask subtaskFromRow(SubtaskRow r) =>
    Subtask(id: r.id, taskId: r.taskId, title: r.title, done: r.done, order: r.ord);

Category categoryFromRow(CategoryRow r) =>
    Category(id: r.id, name: r.name, color: r.color);

Reminder reminderFromRow(ReminderRow r) =>
    Reminder(id: r.id, taskId: r.taskId, minutesBefore: r.minutesBefore);

Attachment attachmentFromRow(AttachmentRow r) => Attachment(
      id: r.id,
      taskId: r.taskId,
      path: r.path,
      name: r.name,
      type: AttachmentType.values[r.type.clamp(0, 1)],
      size: r.size,
    );

SeriesException exceptionFromRow(SeriesExceptionRow r) => SeriesException(
      id: r.id,
      seriesId: r.seriesId,
      originalDate: parseDateKey(r.originalDate),
      type: ExceptionType.values[r.type.clamp(0, 1)],
      overrides: (jsonDecode(r.overrides) as Map).cast<String, Object?>(),
    );

OccurrenceCompletion completionFromRow(CompletionRow r) => OccurrenceCompletion(
      id: r.id,
      seriesId: r.seriesId,
      occurrenceDate: parseDateKey(r.occurrenceDate),
      completedAt: r.completedAt,
    );

TimeEntry timeEntryFromRow(TimeEntryRow r) => TimeEntry(
      id: r.id,
      taskId: r.taskId,
      occurrenceDate:
          r.occurrenceDate == null ? null : parseDateKey(r.occurrenceDate!),
      start: r.start,
      end: r.end,
    );

TaskTemplate templateFromRow(TemplateRow r) => TaskTemplate(
      id: r.id,
      name: r.name,
      items: [
        for (final j in (jsonDecode(r.items) as List))
          TemplateItem.fromJson((j as Map).cast<String, Object?>()),
      ],
    );

Project projectFromRow(ProjectRow r) => Project(
      id: r.id,
      name: r.name,
      color: r.color,
      dueDate: r.dueDate == null ? null : parseDateKey(r.dueDate!),
      archived: r.archived,
    );

DayNote dayNoteFromRow(DayNoteRow r) =>
    DayNote(date: parseDateKey(r.date), body: r.body, updatedAt: r.updatedAt);
