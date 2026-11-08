// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'to Do';

  @override
  String get viewDay => 'Día';

  @override
  String get viewWeek => 'Semana';

  @override
  String get viewMonth => 'Mes';

  @override
  String get viewAgenda => 'Agenda';

  @override
  String get today => 'Hoy';

  @override
  String get goToDate => 'Ir a fecha';

  @override
  String get search => 'Buscar';

  @override
  String get inbox => 'Bandeja';

  @override
  String get settings => 'Ajustes';

  @override
  String get categories => 'Categorías';

  @override
  String get templates => 'Plantillas';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get weeklyReview => 'Revisión semanal';

  @override
  String get backup => 'Copia de seguridad';

  @override
  String get newTask => 'Nueva tarea';

  @override
  String get editTask => 'Editar tarea';

  @override
  String get title => 'Título';

  @override
  String get titleRequired => 'El título es obligatorio';

  @override
  String get notes => 'Notas';

  @override
  String get date => 'Fecha';

  @override
  String get noDate => 'Sin fecha (bandeja)';

  @override
  String get allDay => 'Todo el día';

  @override
  String get startTime => 'Inicio';

  @override
  String get endTime => 'Fin';

  @override
  String get duration => 'Duración';

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String get category => 'Categoría';

  @override
  String get noCategory => 'Sin categoría';

  @override
  String get priority => 'Prioridad';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityLow => 'Baja';

  @override
  String get location => 'Ubicación';

  @override
  String get link => 'Enlace';

  @override
  String get estimate => 'Tiempo estimado (min)';

  @override
  String get pinned => 'Fijada';

  @override
  String get countdownLabel => 'Cuenta atrás (fecha importante)';

  @override
  String get subtasks => 'Subtareas';

  @override
  String get addSubtask => 'Añadir subtarea';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get reminderAtTime => 'A la hora';

  @override
  String reminderMinutesBefore(int n) {
    return '$n min antes';
  }

  @override
  String reminderHoursBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n horas antes',
      one: '1 hora antes',
    );
    return '$_temp0';
  }

  @override
  String reminderDaysBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días antes',
      one: '1 día antes',
    );
    return '$_temp0';
  }

  @override
  String get customReminder => 'Personalizado…';

  @override
  String get minutesBeforeLabel => 'Minutos antes';

  @override
  String get repeat => 'Repetir';

  @override
  String get noRepeat => 'No se repite';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Borrar';

  @override
  String get edit => 'Editar';

  @override
  String get complete => 'Completar';

  @override
  String get uncomplete => 'Desmarcar';

  @override
  String get postpone => 'Posponer';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get skipOccurrence => 'Saltar esta';

  @override
  String get undo => 'Deshacer';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get close => 'Cerrar';

  @override
  String get ok => 'Aceptar';

  @override
  String completedCount(int done, int total) {
    return '$done/$total completadas';
  }

  @override
  String get taskCompleted => 'Tarea completada';

  @override
  String get taskUncompleted => 'Tarea pendiente';

  @override
  String get taskDeleted => 'Tarea borrada';

  @override
  String get taskMoved => 'Tarea movida';

  @override
  String get taskSaved => 'Tarea guardada';

  @override
  String get taskSkipped => 'Ocurrencia saltada';

  @override
  String get taskDuplicated => 'Tarea duplicada';

  @override
  String taskPostponed(String when) {
    return 'Pospuesta a $when';
  }

  @override
  String tasksCompleted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas completadas',
      one: '1 tarea completada',
    );
    return '$_temp0';
  }

  @override
  String tasksDeleted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas borradas',
      one: '1 tarea borrada',
    );
    return '$_temp0';
  }

  @override
  String tasksMoved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas movidas',
      one: '1 tarea movida',
    );
    return '$_temp0';
  }

  @override
  String overlapWarning(String title) {
    return 'Se solapa con «$title»';
  }

  @override
  String get deleteConfirmTitle => '¿Borrar tarea?';

  @override
  String get deleteConfirmBody => 'Podrás deshacerlo durante unos segundos.';

  @override
  String get scopeEditTitle => 'Editar tarea repetida';

  @override
  String get scopeDeleteTitle => 'Borrar tarea repetida';

  @override
  String get scopeThisOne => 'Solo esta';

  @override
  String get scopeThisAndFollowing => 'Esta y las siguientes';

  @override
  String get scopeAll => 'Todas';

  @override
  String get scopeSelected => 'Seleccionadas…';

  @override
  String get selectOccurrences => 'Elegir ocurrencias';

  @override
  String get postponePlusHour => '+1 hora';

  @override
  String get postponeThisAfternoon => 'Esta tarde';

  @override
  String get postponeTomorrow => 'Mañana';

  @override
  String get postponeNextWeek => 'Próxima semana';

  @override
  String get postponePickDate => 'Elegir fecha…';

  @override
  String get freqDaily => 'Diaria';

  @override
  String get freqWeekly => 'Semanal';

  @override
  String get freqMonthly => 'Mensual';

  @override
  String get freqYearly => 'Anual';

  @override
  String get every => 'Cada';

  @override
  String intervalUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'días',
      'week': 'semanas',
      'month': 'meses',
      'year': 'años',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get onDays => 'Días';

  @override
  String monthlyByDay(int day) {
    return 'El día $day';
  }

  @override
  String monthlyByPosition(String ordinal, String weekday) {
    return 'El $ordinal $weekday';
  }

  @override
  String ordinal(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'primer',
      '2': 'segundo',
      '3': 'tercer',
      '4': 'cuarto',
      '5': 'quinto',
      'other': 'último',
    });
    return '$_temp0';
  }

  @override
  String get endsLabel => 'Termina';

  @override
  String get endsNever => 'Nunca';

  @override
  String get endsUntil => 'Hasta una fecha';

  @override
  String get endsCount => 'Tras N repeticiones';

  @override
  String get repetitions => 'Repeticiones';

  @override
  String rrEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cada $n días',
      one: 'Cada día',
    );
    return '$_temp0';
  }

  @override
  String rrEveryWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cada $n semanas',
      one: 'Cada semana',
    );
    return '$_temp0';
  }

  @override
  String rrEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cada $n meses',
      one: 'Cada mes',
    );
    return '$_temp0';
  }

  @override
  String rrEveryYear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cada $n años',
      one: 'Cada año',
    );
    return '$_temp0';
  }

  @override
  String rrOnMonthDay(int day) {
    return 'el día $day';
  }

  @override
  String rrOnNth(String ordinal, String weekday) {
    return 'el $ordinal $weekday';
  }

  @override
  String rrOnDate(String date) {
    return 'el $date';
  }

  @override
  String rrUntil(String date) {
    return 'hasta el $date';
  }

  @override
  String rrCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n veces',
      one: '1 vez',
    );
    return '$_temp0';
  }

  @override
  String get listAnd => 'y';

  @override
  String get listSeparator => ', ';

  @override
  String get overdueTitle => 'Tareas atrasadas';

  @override
  String overdueBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tienes $n tareas sin completar de días pasados.',
      one: 'Tienes 1 tarea sin completar de días pasados.',
    );
    return '$_temp0';
  }

  @override
  String get moveToToday => 'Mover a hoy';

  @override
  String get reschedule => 'Reprogramar';

  @override
  String get discard => 'Descartar';

  @override
  String get allToToday => 'Todas a hoy';

  @override
  String get discardAll => 'Descartar todas';

  @override
  String get later => 'Más tarde';

  @override
  String get inboxEmpty => 'No hay tareas sin fecha';

  @override
  String get dragToCalendar =>
      'Mantén pulsada una tarea y arrástrala a un hueco del calendario';

  @override
  String get searchHint => 'Buscar en títulos, notas y subtareas';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get statusCompleted => 'Completada';

  @override
  String get statusOverdue => 'Atrasada';

  @override
  String get status => 'Estado';

  @override
  String get dateRange => 'Fechas';

  @override
  String get anyDate => 'Cualquier fecha';

  @override
  String get clearFilters => 'Quitar filtros';

  @override
  String get noResults => 'Sin resultados';

  @override
  String selectedCount(int n) {
    return '$n seleccionadas';
  }

  @override
  String get moveTo => 'Mover a…';

  @override
  String get changeCategory => 'Cambiar categoría';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get accentColor => 'Color de acento';

  @override
  String get dynamicColor => 'Color del fondo de pantalla (Android 12+)';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get weekStart => 'Inicio de semana';

  @override
  String get monday => 'Lunes';

  @override
  String get sunday => 'Domingo';

  @override
  String get showWeekNumbers => 'Mostrar número de semana';

  @override
  String get notificationsSection => 'Avisos';

  @override
  String get defaultReminder => 'Recordatorio por defecto';

  @override
  String get none => 'Ninguno';

  @override
  String get dailySummary => 'Resumen diario';

  @override
  String get weeklySummary => 'Resumen semanal';

  @override
  String get monthlySummary => 'Resumen mensual (día 1)';

  @override
  String get summaryTime => 'Hora';

  @override
  String get summaryDay => 'Día';

  @override
  String get haptics => 'Vibración';

  @override
  String get animations => 'Animaciones';

  @override
  String get swipeLeftAction => 'Deslizar a la izquierda';

  @override
  String get swipeDelete => 'Borra';

  @override
  String get swipePostpone => 'Pospone';

  @override
  String get reviewDay => 'Día de la revisión semanal';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get calendarSection => 'Calendario';

  @override
  String get interactionSection => 'Interacción';

  @override
  String get dataSection => 'Datos';

  @override
  String get exportBackup => 'Exportar copia';

  @override
  String get importBackup => 'Importar copia';

  @override
  String get exportBackupHint =>
      'Archivo .zip con tus tareas y adjuntos para guardarlo donde quieras';

  @override
  String get importBackupHint =>
      'Restaura desde un archivo .zip exportado antes';

  @override
  String get importConfirm =>
      'Importar reemplaza todos los datos actuales. ¿Continuar?';

  @override
  String get backupExported => 'Copia exportada';

  @override
  String get backupImported => 'Copia restaurada';

  @override
  String backupError(String error) {
    return 'Error: $error';
  }

  @override
  String get newCategory => 'Nueva categoría';

  @override
  String get categoryName => 'Nombre';

  @override
  String deleteCategoryConfirm(String name) {
    return '¿Borrar «$name»? Sus tareas quedarán sin categoría.';
  }

  @override
  String get catUni => 'Uni';

  @override
  String get catWork => 'Trabajo';

  @override
  String get catPersonal => 'Personal';

  @override
  String get notifPermissionTitle => 'Activar avisos';

  @override
  String get notifPermissionBody =>
      'La app te avisa antes de cada tarea, incluso con la app cerrada. Para ello necesita permiso para mostrar notificaciones y programar alarmas exactas.';

  @override
  String get allow => 'Permitir';

  @override
  String get notifActionComplete => 'Completar';

  @override
  String get notifActionSnooze => 'Posponer 10 min';

  @override
  String get notifChannelReminders => 'Recordatorios';

  @override
  String get notifChannelSummaries => 'Resúmenes';

  @override
  String startsIn(int n) {
    return 'Empieza en $n min';
  }

  @override
  String get startsNow => 'Empieza ahora';

  @override
  String startsAt(String time) {
    return 'A las $time';
  }

  @override
  String get dailySummaryTitle => 'Tu día';

  @override
  String dailySummaryBody(int n, String first) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas hoy: $first',
      one: '1 tarea hoy: $first',
      zero: 'No tienes tareas hoy',
    );
    return '$_temp0';
  }

  @override
  String get weeklySummaryTitle => 'Tu semana';

  @override
  String weeklySummaryBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas esta semana',
      one: '1 tarea esta semana',
      zero: 'Semana libre de tareas',
    );
    return '$_temp0';
  }

  @override
  String get monthlySummaryTitle => 'Tu mes';

  @override
  String monthlySummaryBody(int n, String countdowns) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas este mes',
      one: '1 tarea este mes',
    );
    return '$_temp0$countdowns';
  }

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Faltan $n días',
      one: 'Falta 1 día',
      zero: 'Es hoy',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Hace $n días',
      one: 'Hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get suggestCompleteTask =>
      'Has completado todas las subtareas. ¿Completar la tarea?';

  @override
  String get quickAddHint => '¿Qué tienes que hacer?';

  @override
  String weekNumberShort(int n) {
    return 'S$n';
  }

  @override
  String get noTasks => 'Sin tareas';

  @override
  String get pinnedSection => 'Fijadas';

  @override
  String get countdownSection => 'Cuentas atrás';

  @override
  String get loadMore => 'Ver más';

  @override
  String get repeats => 'Se repite';

  @override
  String get error => 'Algo ha fallado';

  @override
  String get allDayShort => 'Todo el día';

  @override
  String get unscheduled => 'Sin fecha';

  @override
  String get attachments => 'Adjuntos';

  @override
  String get addPhoto => 'Foto';

  @override
  String get addFromGallery => 'Galería';

  @override
  String get addFile => 'Archivo';

  @override
  String get timer => 'Tiempo dedicado';

  @override
  String get timerStart => 'Iniciar';

  @override
  String get timerPause => 'Pausar';

  @override
  String get timerStop => 'Parar';

  @override
  String get timerReset => 'Reiniciar';

  @override
  String estimatedVsReal(String est, String real) {
    return 'Estimado $est · Real $real';
  }

  @override
  String get applyTemplate => 'Aplicar a un día';

  @override
  String get newTemplate => 'Nueva plantilla';

  @override
  String get templateName => 'Nombre de la plantilla';

  @override
  String get templateApplied => 'Plantilla aplicada';

  @override
  String get saveAsTemplate => 'Guardar día como plantilla';

  @override
  String get noTemplates =>
      'Aún no hay plantillas. Guarda un día como plantilla desde la vista día.';

  @override
  String get addItem => 'Añadir tarea';

  @override
  String get statsCompletionRate => 'Completadas';

  @override
  String get statsThisWeek => 'Esta semana';

  @override
  String get statsThisMonth => 'Este mes';

  @override
  String get statsToday => 'Hoy';

  @override
  String get statsStreak => 'Racha';

  @override
  String statsStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int n) {
    return 'Mejor racha: $n';
  }

  @override
  String get statsHabits => 'Hábitos (tareas repetidas)';

  @override
  String get statsTimeByCategory => 'Estimado vs. real por categoría';

  @override
  String get statsLast7Days => 'Últimos 7 días';

  @override
  String get statsWeeklySummary => 'Resumen semanal';

  @override
  String statsWeeklySummaryBody(int done, int total, int minutes) {
    return '$done de $total completadas · $minutes min dedicados';
  }

  @override
  String get reviewStep1 => 'Pendientes';

  @override
  String get reviewStep1Body =>
      'Tareas atrasadas o sin completar de la semana pasada';

  @override
  String get reviewStep2 => 'Próxima semana';

  @override
  String get reviewStep2Body => 'Lo que tienes planificado';

  @override
  String get reviewStep3 => 'Bandeja';

  @override
  String get reviewStep3Body => 'Coloca tareas sin fecha en huecos libres';

  @override
  String get reviewDone => 'Revisión completada';

  @override
  String get reviewNothing => 'Nada por aquí';

  @override
  String get next => 'Siguiente';

  @override
  String get back => 'Atrás';

  @override
  String get finish => 'Terminar';

  @override
  String get placeInFreeSlot => 'Colocar en hueco libre';

  @override
  String placedAt(String when) {
    return 'Colocada el $when';
  }

  @override
  String get reviewReminder => 'Toca tu revisión semanal';

  @override
  String get allDoneCelebration => '¡Día completado!';

  @override
  String get quickAddPreview => 'Detectado';

  @override
  String get naturalLanguageHint =>
      'p. ej. «gym mañana 18h cada lunes #Personal !alta»';

  @override
  String get widgetTodayTitle => 'Hoy';

  @override
  String get openMap => 'Abrir en mapas';

  @override
  String get openLink => 'Abrir enlace';

  @override
  String get notificationsDisabled =>
      'Los avisos están desactivados en el sistema';

  @override
  String get exactAlarmsDisabled =>
      'Las alarmas exactas están desactivadas: los avisos pueden retrasarse';

  @override
  String get openSystemSettings => 'Abrir ajustes';

  @override
  String get about => 'Acerca de';

  @override
  String get viewThreeDays => '3 días';

  @override
  String get viewWorkWeek => 'Entre semana';

  @override
  String get icsImport => 'Importar .ics';

  @override
  String get icsExport => 'Exportar .ics';

  @override
  String get icsImportHint =>
      'Añade eventos de Google Calendar, Outlook u otras apps';

  @override
  String get icsExportHint => 'Comparte tus tareas como archivo de calendario';

  @override
  String get icsSelectAll => 'Todos';

  @override
  String get icsSelectNone => 'Ninguno';

  @override
  String get icsAlreadyImported => 'Ya importado: se reemplaza si lo marcas';

  @override
  String get icsUnsupportedRule =>
      'Repetición no compatible: solo se importa la primera';

  @override
  String get icsMultiDay => 'Varios días: se importa el primero';

  @override
  String get icsCategoryFromFile => 'Según el archivo';

  @override
  String icsImportButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Importar $n',
      one: 'Importar 1',
    );
    return '$_temp0';
  }

  @override
  String icsImported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tareas importadas',
      one: '1 tarea importada',
    );
    return '$_temp0';
  }

  @override
  String get icsNothing => 'El archivo no tiene eventos ni tareas';

  @override
  String icsError(String error) {
    return 'No se pudo leer el archivo: $error';
  }

  @override
  String get icsRange => 'Fechas';

  @override
  String get icsAllDates => 'Todas';

  @override
  String get icsChooseRange => 'Elegir rango';

  @override
  String get icsIncludeCompleted => 'Incluir completadas';

  @override
  String get icsIncludeUndated =>
      'Incluir tareas sin fecha (como tareas pendientes)';

  @override
  String icsWillExport(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Se exportarán $n tareas',
      one: 'Se exportará 1 tarea',
      zero: 'No hay tareas que exportar',
    );
    return '$_temp0';
  }

  @override
  String get icsExportButton => 'Exportar y compartir';

  @override
  String get projects => 'Proyectos';

  @override
  String get project => 'Proyecto';

  @override
  String get newProject => 'Nuevo proyecto';

  @override
  String get projectName => 'Nombre del proyecto';

  @override
  String get noProject => 'Sin proyecto';

  @override
  String get projectDue => 'Fecha límite';

  @override
  String get noDueDate => 'Sin fecha límite';

  @override
  String deleteProjectConfirm(String name) {
    return '¿Borrar «$name»? Sus tareas quedarán sin proyecto.';
  }

  @override
  String get projectEmpty => 'Este proyecto aún no tiene tareas';

  @override
  String get projectSeriesNote =>
      'Las tareas repetidas no cuentan en el avance';

  @override
  String get diary => 'Diario';

  @override
  String get dayNote => 'Nota del día';

  @override
  String get dayNoteHint => '¿Cómo ha ido el día?';

  @override
  String get diaryEmpty => 'Aún no has escrito en el diario';

  @override
  String get searchDiary => 'Buscar en el diario';

  @override
  String get showInCalendar => 'Mostrar en el calendario';

  @override
  String get manageCategories => 'Gestionar categorías';

  @override
  String get countdownsAndPinned => 'Cuentas atrás y fijadas';

  @override
  String get nothingPinned => 'Nada fijado ni con cuenta atrás';

  @override
  String get processInbox => 'Procesar bandeja';

  @override
  String processInboxProgress(int i, int n) {
    return '$i de $n';
  }

  @override
  String get skip => 'Saltar';

  @override
  String get inboxDone => '¡Bandeja vacía!';

  @override
  String get gestureGuide => 'Guía de gestos';

  @override
  String get gestures => 'Gestos';

  @override
  String get naturalLanguage => 'Texto natural';

  @override
  String get gTapBlock => 'Tocar una tarea: ver el detalle';

  @override
  String get gLongPressMove =>
      'Mantener pulsada y mover: cambiar la hora (y el día en semana o 3 días)';

  @override
  String get gLongPress => 'Mantener pulsada sin mover: selección múltiple';

  @override
  String get gResize =>
      'Arrastrar el borde inferior de un bloque: cambiar la duración';

  @override
  String get gPinch => 'Pellizcar con dos dedos: ampliar o reducir las horas';

  @override
  String get gSwipePages =>
      'Deslizar a los lados: pasar al día, semana o mes anterior o siguiente';

  @override
  String get gSwipeList =>
      'En listas: deslizar a la derecha completa; a la izquierda borra o pospone';

  @override
  String get gLongPressEmpty =>
      'Mantener pulsado un hueco vacío: crear una tarea a esa hora';

  @override
  String get gWeekTap =>
      'Tocar otra vez «Semana»: alternar con entre semana (lunes a viernes)';

  @override
  String get gInboxDrag =>
      'Bandeja: mantener pulsada una tarea y soltarla en un hueco del calendario';

  @override
  String get gMonthDrag =>
      'Vista mes: mantener pulsada una tarea y soltarla en otro día';

  @override
  String get nlTips =>
      'Escribe la tarea con fecha, hora, repetición, #categoría y !prioridad';

  @override
  String heatmapTitle(int year) {
    return 'Año $year';
  }

  @override
  String get heatLess => 'Menos';

  @override
  String get heatMore => 'Más';
}
