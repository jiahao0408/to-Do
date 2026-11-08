# to Do — Calendario + tareas (Flutter)

App móvil personal (Android e iOS) que combina calendario y lista de tareas, 100 % local y sin cuenta.
Especificación: [Requisitos — App Calendario + To-Do](https://claude.ai/artifact/6iyHVc8BPKqx2BQnSdakuC).

## Compilar, ejecutar y probar

Requisitos: Flutter estable 3.47+ (probado con 3.47.9 / Dart 3.13.7), Android SDK con plataforma 37, JDK 17+.

```bash
flutter pub get
dart run build_runner build      # genera lib/data/db/database.g.dart (Drift)
flutter gen-l10n                 # genera lib/l10n/app_localizations*.dart
flutter analyze                  # debe salir sin avisos (RNF-09)
flutter test                     # tests unitarios y de base de datos
flutter run                      # en un emulador o móvil conectado
flutter build apk --release      # APK de Android
```

En este equipo Windows:

- Flutter está en `D:\flutter` y la caché de paquetes en `D:\pub-cache`. Antes de usar `flutter`, ejecuta `$env:PUB_CACHE='D:\pub-cache'` en PowerShell. La caché por defecto de `AppData` no funciona dentro de la app de escritorio por la virtualización de carpetas.
- `android/gradle.properties` desactiva la compilación incremental de Kotlin (`kotlin.incremental=false`). Si no, falla porque el proyecto (C:) y los paquetes (D:) están en unidades distintas.

iOS se compila en un Mac: `cd ios && pod install`, luego `flutter build ios`. Desde Windows no se ha podido compilar ni probar.

## Arquitectura

Capas: presentación / aplicación / dominio / datos. Así se podrá añadir sincronización en el futuro sin reescribir las pantallas.

```
lib/
  domain/          Dart puro, sin Flutter: modelos, motor de repetición, parser de texto
                   natural, solapamientos, plan de avisos, estadísticas.
  application/     Casos de uso (TaskService): editar o borrar con alcance, completar,
                   mover, posponer, duplicar, plantillas. Cada cambio devuelve un
                   punto de deshacer.
  data/            Drift (SQLite): tablas, migraciones versionadas, repositorio,
                   copia de seguridad.
  services/        Notificaciones locales, widget de inicio, archivos.
  presentation/    Riverpod + Material 3: vistas día, semana, mes y agenda, editor,
                   detalle, ajustes…
  l10n/            Textos ARB (es plantilla, en, zh).
android/app/src/main/kotlin/…/TodayWidgetProvider.kt   Widget nativo de Android.
ios/TodayWidget/                                       Widget de iOS (WidgetKit), ver más abajo.
```

- **Datos.** Toda la base de datos se carga en memoria como una «foto» (`AppSnapshot`) que se recarga al cambiar cualquier tabla. Las ocurrencias de las series se calculan al vuelo para el rango visible.
- **Horas.** Se guardan como hora local de pared (`yyyy-MM-ddTHH:mm`) más la zona IANA. Una tarea de las 9:00 sigue a las 9:00 tras el cambio de horario (RNF-11).
- **Series.** Una tarea con regla RRULE es una serie. Cada ocurrencia puede tener una excepción (saltada o modificada, con los campos sobrescritos) y un completado propio (RF-27).

## Esquema de base de datos (versión 1)

| Tabla | Campos clave |
| --- | --- |
| tasks | id, title, notes, start (hora de pared, nullable), durationMin, allDay, categoryId, priority, location, url, pinned, countdown, estimateMin, status, completedAt, rrule, tz, createdAt, updatedAt |
| subtasks | id, taskId, title, done, ord |
| categories | id, name, color |
| reminders | id, taskId, minutesBefore |
| attachments | id, taskId, path (relativa), name, type, size |
| series_exceptions | id, seriesId, originalDate, type (saltada/modificada), overrides (JSON) |
| occurrence_completions | id, seriesId, occurrenceDate, completedAt |
| time_entries | id, taskId, occurrenceDate, start, end |
| templates | id, name, items (JSON con hora relativa) |
| settings | key, value |

Las migraciones van en `AppDatabase.migration.onUpgrade`, con un bloque por versión. Las copias de seguridad guardan `schemaVersion`, y `BackupService._migrateRow` adapta las filas de copias antiguas.

## Requisitos hechos por fase

Leyenda: ✅ hecho y probado (test o emulador) · ☑️ hecho, solo compilado · ⚠️ parcial, ver notas.

### Fase 1 — Núcleo (MVP)

| ID | Estado | Notas |
| --- | --- | --- |
| RF-01 Crear tarea | ✅ | Editor completo y creación rápida |
| RF-03 Todo el día | ☑️ | Franja superior en las vistas día y semana |
| RF-04 Completar | ✅ | Check con animación; tachada y atenuada |
| RF-05 Subtareas | ☑️ | Progreso «2/5»; al completarlas todas, sugiere completar la tarea |
| RF-06 Categorías | ☑️ | Crear, renombrar, color, borrar |
| RF-07 Prioridad | ✅ | A igual hora, ordena por prioridad (test) |
| RF-17 Atrasadas | ✅ | Diálogo al abrir, una vez al día |
| RF-18 Borrar | ☑️ | Con deshacer |
| RF-19 Repetición básica | ✅ | Tests del motor |
| RF-21 Fin de repetición | ✅ | Nunca, hasta fecha, N veces |
| RF-23 / RF-24 Alcance | ✅ | Solo esta, siguientes, todas (tests con base de datos) |
| RF-26 Saltar una | ✅ | |
| RF-27 Completado por ocurrencia | ✅ | |
| RF-28 a RF-32 Vistas | ✅ | Día, semana, mes y agenda probadas en el emulador; deslizar y «Hoy» |
| RF-36 Pulsar hueco | ☑️ | Mantener pulsado un hueco abre la creación rápida |
| RF-37 Deshacer | ✅ | Aviso de 5 s |
| RF-38 Deslizar | ☑️ | Derecha completa; izquierda borra o pospone |
| RF-43 / RF-44 Recordatorios | ✅ | Plan de avisos probado en tests |
| RF-47 Fiabilidad de avisos | ⚠️ | Permisos, alarmas exactas (`USE_EXACT_ALARM`; en el emulador quedan con `window=0`), receptor de reinicio y tope de 60 pendientes. No he comprobado que suenen con la app cerrada |
| RF-54 Tema | ☑️ | Claro, oscuro o sistema; color de acento; color dinámico en Android 12+ |
| RF-55 Idiomas | ☑️ | es / en / zh |
| RF-56 Ajustes de semana | ☑️ | |
| RF-58 Categorías iniciales | ✅ | |

### Fase 2 — Interacción y repetición avanzada

| ID | Estado | Notas |
| --- | --- | --- |
| RF-02 Bandeja | ☑️ | Panel inferior arrastrable al calendario |
| RF-13 Duplicar | ✅ | |
| RF-14 Posponer | ✅ | |
| RF-15 Solapamientos | ✅ | Aviso al guardar o mover; bloques lado a lado (emulador) |
| RF-20 Reglas avanzadas | ✅ | |
| RF-22 Resumen legible | ☑️ | |
| RF-25 Seleccionadas | ✅ | |
| RF-33 Selección múltiple | ☑️ | |
| RF-34 Arrastrar y estirar | ✅ | Arrastrar probado en el emulador (saltos de 15 min) |
| RF-35 Mover en semana o mes | ☑️ | |
| RF-39 Pellizcar | ☑️ | |
| RF-40 Búsqueda y filtros | ☑️ | |
| RF-45 Acciones en notificación | ☑️ | Completar y posponer 10 min sin abrir la app |
| RF-52 / RF-53 Backup | ✅ | Ida y vuelta sin pérdidas (test) |

### Fase 3 — Productividad

| ID | Estado | Notas |
| --- | --- | --- |
| RF-08 Adjuntos | ☑️ | Cámara, galería y archivos; miniatura y pantalla completa |
| RF-09 Ubicación y enlace | ☑️ | |
| RF-10 Cronómetro | ☑️ | |
| RF-11 Fijadas | ☑️ | Arriba en la agenda y en el widget |
| RF-12 Cuenta atrás | ☑️ | |
| RF-16 Plantillas | ✅ | |
| RF-41 Vibración | ☑️ | |
| RF-42 Animaciones | ☑️ | Tachado y celebración al completar el día |
| RF-46 Resúmenes | ✅ | Diario, semanal y mensual |
| RF-49 Estadísticas | ✅ | |
| RF-50 Revisión semanal | ☑️ | |
| RF-57 Ajustes de avisos | ☑️ | |

### Fase 4 — Extras

| ID | Estado | Notas |
| --- | --- | --- |
| RF-48 Texto natural | ✅ | es / en / zh, con vista previa (tests y emulador) |
| RF-51 Widget | ⚠️ | Android: widget nativo con check interactivo, compilado pero no colocado en la pantalla de inicio. iOS: código de WidgetKit incluido, falta crear el target en Xcode (ver abajo) |

## Novedades v2 (2026-11-08)

Decididas por ti: cada punto recoge la opción que elegiste.

| Función | Estado | Detalle |
| --- | --- | --- |
| Vista 3 días | ✅ | Hoy, mañana y pasado; al deslizar avanza 1 día. Pestaña propia (probado en el emulador) |
| Vista entre semana | ✅ | Lunes a viernes. Se activa tocando otra vez «Semana» o con el botón de la cabecera (probado en el emulador) |
| Importar .ics | ✅ | Vista previa con casillas y categoría destino (según el archivo, ninguna o una concreta). Los UID ya importados salen desmarcados; si los marcas, se reemplazan. Lee VEVENT/VTODO, RRULE, EXDATE, RECURRENCE-ID, VALARM, TZID/UTC/flotante. Las reglas no compatibles se avisan y se importa solo la primera ocurrencia (tests + emulador) |
| Exportar .ics | ✅ | Diálogo con rango de fechas, categorías, completadas y sin fecha. Las tareas con fecha van como VEVENT (con TZID IANA, RRULE, EXDATE y RECURRENCE-ID) y las sin fecha como VTODO. Ida y vuelta probada en tests |
| Abrir .ics con la app | ✅ Android / ☑️ iOS | «Abrir con» y «Compartir» en `text/calendar` llevan directo a la vista previa (probado en el emulador). En iOS está el código, sin probar |
| Proyectos | ☑️ | Aparte de la categoría: nombre, color, fecha límite opcional y avance (tareas puntuales completadas / totales; las series no cuentan). Pantalla de proyecto y campo en el editor |
| Diario | ☑️ | Una nota por día: botón en la cabecera de la vista día (relleno si hay nota) y pantalla «Diario» con búsqueda |
| Mostrar/ocultar categorías | ✅ | Casillas en el menú. Solo afecta a las vistas del calendario; avisos, widget y búsqueda siguen viéndolo todo (test) |
| Cuentas atrás y fijadas | ☑️ | Sección en el menú |
| Procesar bandeja | ☑️ | Asistente tarea a tarea: hoy, mañana, hueco libre, elegir fecha, categoría, descartar o saltar |
| Guía de gestos | ☑️ | Gestos y ejemplos de texto natural |
| Mapa de calor anual | ☑️ | En Estadísticas, % completado por día; toca un día para ver su recuento |
| Nombre «to Do» | ✅ | En Android, iOS y los tres idiomas |

Esquema de la base de datos v2: columnas `tasks.projectId` y `tasks.icsUid`, y tablas `projects` y `day_notes`. La migración desde v1 se ha probado instalando encima de la v1 en el emulador sin perder datos, y las copias de seguridad de v1 se siguen importando (test).

## Decisiones tomadas

El documento pide preguntar ante las ambigüedades. Como pediste avanzar sin parar, las he resuelto así; cualquiera se puede cambiar:

1. **Motor de repetición propio** en lugar del paquete `rrule`. Guarda texto RRULE (subconjunto de RFC 5545) y es puro y probado; el documento permitía alternativas.
2. **Todo el esquema en la versión 1.** No había datos previos, así que no hizo falta migrar entre fases. La infraestructura de migraciones está lista.
3. **Atrasadas (RF-17).** Incluye las tareas puntuales sin completar. De las series solo mira los últimos 7 días, para no inundar el diálogo con hábitos diarios. «Descartar» marca la tarea puntual como descartada o salta la ocurrencia de la serie.
4. **«Esta y las siguientes»** parte la serie en dos. Si tenía COUNT, el total se conserva.
5. **Mantener pulsado un bloque.** Si lo mueves, lo arrastras (RF-34/35). Si lo sueltas sin moverlo, activa la selección múltiple (RF-33).
6. **Fechas dd/mm** en el texto natural (formato europeo, también en inglés).
7. **Avisos de tareas de todo el día**: se calculan desde las 9:00 de ese día.
8. **Hasta 60 avisos programados** a la vez (límite de 64 en iOS). Los de más allá de 30 días se reponen al abrir la app o al cambiar datos.
9. **Chino** como locale `zh` (simplificado por defecto).
10. **compileSdk 37**, porque lo exige algún plugin. minSdk 26 (Android 8), como pide el documento.
11. **`dynamic_color` 1.x**: la 2.x usa el nuevo paquete `material_ui`, incompatible con `MaterialApp`.

## Widget de iOS (pendiente en un Mac)

En `ios/TodayWidget/` está el código de WidgetKit y del App Intent del check (iOS 17+). Para activarlo:

1. En Xcode: *File › New › Target › Widget Extension*, con el nombre `TodayWidget`, y sustituye los archivos generados por los de esa carpeta.
2. Añade el *App Group* `group.com.chenj.todoCalendar` al target Runner y al del widget.
3. Ajusta la versión mínima del target del widget a iOS 15; el check interactivo solo aparece en iOS 17+.

## Limitaciones conocidas

- No se ha probado en iOS ni en un móvil físico; solo en el emulador de Android (API 37).
- Al borrar una tarea, sus archivos adjuntos se quedan en la carpeta de la app; solo se borra la fila.
- Para alarmas exactas uso `USE_EXACT_ALARM`, que Android concede a las apps de calendario. Google Play pide justificar ese permiso al publicar; si se quitara, los avisos serían inexactos (hasta 1 h de margen).
