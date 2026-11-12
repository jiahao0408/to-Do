// Importar un proyecto desde texto Markdown (p. ej. la respuesta de una IA).
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_calendar/domain/models/task.dart';
import 'package:todo_calendar/domain/nlp/quick_parser.dart';
import 'package:todo_calendar/domain/project_import.dart';

void main() {
  final now = DateTime(2026, 11, 13, 10); // viernes
  QuickParser parser() => QuickParser(now: now);

  test('# título, ## módulos y - subtareas', () {
    final p = parseProjectMarkdown('''
# TFG: App de reciclaje
## Módulo 1: Investigación
- Leer artículos sobre reciclaje
- Entrevistar a 5 usuarios
## Módulo 2: Diseño
- Bocetos de pantallas
  - Pantalla de inicio
  - Pantalla de mapa
''');
    expect(p.title, 'TFG: App de reciclaje');
    expect(p.modules.map((m) => m.title), ['Módulo 1: Investigación', 'Módulo 2: Diseño']);
    expect(p.modules[0].subtasks.map((s) => s.title), ['Leer artículos sobre reciclaje', 'Entrevistar a 5 usuarios']);
    expect(p.modules[1].subtasks.map((s) => s.title), ['Bocetos de pantallas', 'Pantalla de inicio', 'Pantalla de mapa']);
  });

  test('sin encabezados de módulo: puntos de primer nivel = módulos, anidados = subtareas', () {
    final p = parseProjectMarkdown('''
Plan de mudanza

1. **Empaquetar**
   - Comprar cajas
   - Etiquetar
2. *Transporte*
   * Alquilar furgoneta
''');
    expect(p.title, 'Plan de mudanza');
    expect(p.modules.map((m) => m.title), ['Empaquetar', 'Transporte']);
    expect(p.modules[0].subtasks.map((s) => s.title), ['Comprar cajas', 'Etiquetar']);
    expect(p.modules[1].subtasks.single.title, 'Alquilar furgoneta');
  });

  test('### bajo ## son subtareas; texto suelto = nota del módulo', () {
    final p = parseProjectMarkdown('''
## Viaje a Japón
Algo de introducción que se ignora.
### Reservas
Antes de diciembre.
- Vuelo
### Documentos
''');
    // Un solo ## en el nivel más alto: es el título.
    expect(p.title, 'Viaje a Japón');
    expect(p.modules.map((m) => m.title), ['Reservas', 'Documentos']);
    expect(p.modules[0].notes, 'Antes de diciembre.');
    expect(p.modules[0].subtasks.single.title, 'Vuelo');
  });

  test('varios # al mismo nivel: todos son módulos y el título queda vacío', () {
    final p = parseProjectMarkdown('# Uno\n- a\n# Dos\n- b');
    expect(p.title, isEmpty);
    expect(p.modules.map((m) => m.title), ['Uno', 'Dos']);
  });

  test('limpia Markdown: negritas, código, enlaces, casillas y numeración', () {
    final p = parseProjectMarkdown('''
# **Web** personal
## 1. Montar `Flutter`
- [x] Instalar [SDK](https://flutter.dev)
- [ ] Crear __proyecto__
''');
    expect(p.title, 'Web personal');
    expect(p.modules.single.title, 'Montar Flutter');
    expect(p.modules.single.subtasks.map((s) => (s.title, s.done)), [('Instalar SDK', true), ('Crear proyecto', false)]);
  });

  test('módulo con casilla marcada sale completado', () {
    final p = parseProjectMarkdown('- [x] Hecho\n- [ ] Pendiente');
    expect(p.modules.map((m) => m.done), [true, false]);
  });

  test('ignora bloques de código, separadores y líneas vacías', () {
    final p = parseProjectMarkdown('''
# P
---
```
- esto no es una tarea
```
## M
- s
''');
    expect(p.modules.single.subtasks.single.title, 's');
  });

  test('fechas del texto en los módulos (y se quitan del título)', () {
    final p = parseProjectMarkdown('''
# P
## Entregar memoria mañana a las 10
## Revisar bibliografía
''', dates: parser());
    final m = p.modules[0];
    expect(m.title, 'Entregar memoria');
    expect(m.start, DateTime(2026, 11, 14, 10));
    expect(m.allDay, isFalse);
    expect(p.modules[1].start, isNull);
    expect(p.modules[1].title, 'Revisar bibliografía');
  });

  test('fecha sin hora: todo el día', () {
    final p = parseProjectMarkdown('- Comprar regalo el lunes', dates: parser());
    expect(p.modules.single.start, DateTime(2026, 11, 16));
    expect(p.modules.single.allDay, isTrue);
  });

  test('texto vacío o sin nada útil: sin módulos', () {
    expect(parseProjectMarkdown('   \n\n').modules, isEmpty);
    expect(parseProjectMarkdown('¡Claro! Aquí tienes:').modules, isEmpty);
  });

  test('prioridad del texto natural', () {
    final p = parseProjectMarkdown('- Pagar matrícula !alta', dates: parser());
    expect(p.modules.single.priority, Priority.high);
  });
}
