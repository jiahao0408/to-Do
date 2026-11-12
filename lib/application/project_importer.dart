// Guarda un proyecto importado: el proyecto y, por cada módulo, una tarea con
// sus subtareas. Todo en una transacción.

import '../data/repository.dart';
import '../domain/models/entities.dart';
import '../domain/models/task.dart';
import '../domain/project_import.dart';

class ProjectImporter {
  ProjectImporter(this.repo);
  final Repository repo;

  /// Devuelve el id del proyecto creado.
  Future<int> save(
    ImportedProject p, {
    required String title,
    required int color,
    String? building,
    required String tz,
  }) =>
      repo.db.transaction(() async {
        final now = repo.now;
        final projectId = await repo.saveProject(Project(name: title, color: color, building: building));
        for (final m in p.modules) {
          await repo.insertTask(
            Task(
              title: m.title,
              notes: m.notes,
              start: m.start,
              allDay: m.allDay,
              durationMin: m.start != null && !m.allDay ? m.durationMin : null,
              priority: m.priority ?? Priority.medium,
              status: m.done ? TaskStatus.completed : TaskStatus.pending,
              completedAt: m.done ? now : null,
              projectId: projectId,
              tz: tz,
              createdAt: now,
              updatedAt: now,
            ),
            subtasks: [
              for (var i = 0; i < m.subtasks.length; i++)
                Subtask(taskId: 0, title: m.subtasks[i].title, done: m.subtasks[i].done, order: i),
            ],
          );
        }
        return projectId;
      });
}
