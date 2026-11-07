import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get appTitle;

  /// No description provided for @viewDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get viewDay;

  /// No description provided for @viewWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get viewWeek;

  /// No description provided for @viewMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get viewMonth;

  /// No description provided for @viewAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda'**
  String get viewAgenda;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @goToDate.
  ///
  /// In es, this message translates to:
  /// **'Ir a fecha'**
  String get goToDate;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @inbox.
  ///
  /// In es, this message translates to:
  /// **'Bandeja'**
  String get inbox;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @categories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categories;

  /// No description provided for @templates.
  ///
  /// In es, this message translates to:
  /// **'Plantillas'**
  String get templates;

  /// No description provided for @statistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get statistics;

  /// No description provided for @weeklyReview.
  ///
  /// In es, this message translates to:
  /// **'Revisión semanal'**
  String get weeklyReview;

  /// No description provided for @backup.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad'**
  String get backup;

  /// No description provided for @newTask.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get editTask;

  /// No description provided for @title.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get title;

  /// No description provided for @titleRequired.
  ///
  /// In es, this message translates to:
  /// **'El título es obligatorio'**
  String get titleRequired;

  /// No description provided for @notes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notes;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @noDate.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha (bandeja)'**
  String get noDate;

  /// No description provided for @allDay.
  ///
  /// In es, this message translates to:
  /// **'Todo el día'**
  String get allDay;

  /// No description provided for @startTime.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get endTime;

  /// No description provided for @duration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get duration;

  /// No description provided for @durationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{n} min'**
  String durationMinutes(int n);

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @noCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get noCategory;

  /// No description provided for @priority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get priority;

  /// No description provided for @priorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get priorityLow;

  /// No description provided for @location.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get location;

  /// No description provided for @link.
  ///
  /// In es, this message translates to:
  /// **'Enlace'**
  String get link;

  /// No description provided for @estimate.
  ///
  /// In es, this message translates to:
  /// **'Tiempo estimado (min)'**
  String get estimate;

  /// No description provided for @pinned.
  ///
  /// In es, this message translates to:
  /// **'Fijada'**
  String get pinned;

  /// No description provided for @countdownLabel.
  ///
  /// In es, this message translates to:
  /// **'Cuenta atrás (fecha importante)'**
  String get countdownLabel;

  /// No description provided for @subtasks.
  ///
  /// In es, this message translates to:
  /// **'Subtareas'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In es, this message translates to:
  /// **'Añadir subtarea'**
  String get addSubtask;

  /// No description provided for @reminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get reminders;

  /// No description provided for @reminderAtTime.
  ///
  /// In es, this message translates to:
  /// **'A la hora'**
  String get reminderAtTime;

  /// No description provided for @reminderMinutesBefore.
  ///
  /// In es, this message translates to:
  /// **'{n} min antes'**
  String reminderMinutesBefore(int n);

  /// No description provided for @reminderHoursBefore.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 hora antes} other{{n} horas antes}}'**
  String reminderHoursBefore(int n);

  /// No description provided for @reminderDaysBefore.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 día antes} other{{n} días antes}}'**
  String reminderDaysBefore(int n);

  /// No description provided for @customReminder.
  ///
  /// In es, this message translates to:
  /// **'Personalizado…'**
  String get customReminder;

  /// No description provided for @minutesBeforeLabel.
  ///
  /// In es, this message translates to:
  /// **'Minutos antes'**
  String get minutesBeforeLabel;

  /// No description provided for @repeat.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get repeat;

  /// No description provided for @noRepeat.
  ///
  /// In es, this message translates to:
  /// **'No se repite'**
  String get noRepeat;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @complete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get complete;

  /// No description provided for @uncomplete.
  ///
  /// In es, this message translates to:
  /// **'Desmarcar'**
  String get uncomplete;

  /// No description provided for @postpone.
  ///
  /// In es, this message translates to:
  /// **'Posponer'**
  String get postpone;

  /// No description provided for @duplicate.
  ///
  /// In es, this message translates to:
  /// **'Duplicar'**
  String get duplicate;

  /// No description provided for @skipOccurrence.
  ///
  /// In es, this message translates to:
  /// **'Saltar esta'**
  String get skipOccurrence;

  /// No description provided for @undo.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get undo;

  /// No description provided for @moreOptions.
  ///
  /// In es, this message translates to:
  /// **'Más opciones'**
  String get moreOptions;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;

  /// No description provided for @completedCount.
  ///
  /// In es, this message translates to:
  /// **'{done}/{total} completadas'**
  String completedCount(int done, int total);

  /// No description provided for @taskCompleted.
  ///
  /// In es, this message translates to:
  /// **'Tarea completada'**
  String get taskCompleted;

  /// No description provided for @taskUncompleted.
  ///
  /// In es, this message translates to:
  /// **'Tarea pendiente'**
  String get taskUncompleted;

  /// No description provided for @taskDeleted.
  ///
  /// In es, this message translates to:
  /// **'Tarea borrada'**
  String get taskDeleted;

  /// No description provided for @taskMoved.
  ///
  /// In es, this message translates to:
  /// **'Tarea movida'**
  String get taskMoved;

  /// No description provided for @taskSaved.
  ///
  /// In es, this message translates to:
  /// **'Tarea guardada'**
  String get taskSaved;

  /// No description provided for @taskSkipped.
  ///
  /// In es, this message translates to:
  /// **'Ocurrencia saltada'**
  String get taskSkipped;

  /// No description provided for @taskDuplicated.
  ///
  /// In es, this message translates to:
  /// **'Tarea duplicada'**
  String get taskDuplicated;

  /// No description provided for @taskPostponed.
  ///
  /// In es, this message translates to:
  /// **'Pospuesta a {when}'**
  String taskPostponed(String when);

  /// No description provided for @tasksCompleted.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 tarea completada} other{{n} tareas completadas}}'**
  String tasksCompleted(int n);

  /// No description provided for @tasksDeleted.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 tarea borrada} other{{n} tareas borradas}}'**
  String tasksDeleted(int n);

  /// No description provided for @tasksMoved.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 tarea movida} other{{n} tareas movidas}}'**
  String tasksMoved(int n);

  /// No description provided for @overlapWarning.
  ///
  /// In es, this message translates to:
  /// **'Se solapa con «{title}»'**
  String overlapWarning(String title);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar tarea?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Podrás deshacerlo durante unos segundos.'**
  String get deleteConfirmBody;

  /// No description provided for @scopeEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea repetida'**
  String get scopeEditTitle;

  /// No description provided for @scopeDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Borrar tarea repetida'**
  String get scopeDeleteTitle;

  /// No description provided for @scopeThisOne.
  ///
  /// In es, this message translates to:
  /// **'Solo esta'**
  String get scopeThisOne;

  /// No description provided for @scopeThisAndFollowing.
  ///
  /// In es, this message translates to:
  /// **'Esta y las siguientes'**
  String get scopeThisAndFollowing;

  /// No description provided for @scopeAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get scopeAll;

  /// No description provided for @scopeSelected.
  ///
  /// In es, this message translates to:
  /// **'Seleccionadas…'**
  String get scopeSelected;

  /// No description provided for @selectOccurrences.
  ///
  /// In es, this message translates to:
  /// **'Elegir ocurrencias'**
  String get selectOccurrences;

  /// No description provided for @postponePlusHour.
  ///
  /// In es, this message translates to:
  /// **'+1 hora'**
  String get postponePlusHour;

  /// No description provided for @postponeThisAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Esta tarde'**
  String get postponeThisAfternoon;

  /// No description provided for @postponeTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get postponeTomorrow;

  /// No description provided for @postponeNextWeek.
  ///
  /// In es, this message translates to:
  /// **'Próxima semana'**
  String get postponeNextWeek;

  /// No description provided for @postponePickDate.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha…'**
  String get postponePickDate;

  /// No description provided for @freqDaily.
  ///
  /// In es, this message translates to:
  /// **'Diaria'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get freqYearly;

  /// No description provided for @every.
  ///
  /// In es, this message translates to:
  /// **'Cada'**
  String get every;

  /// No description provided for @intervalUnit.
  ///
  /// In es, this message translates to:
  /// **'{unit, select, day{días} week{semanas} month{meses} year{años} other{}}'**
  String intervalUnit(String unit);

  /// No description provided for @onDays.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get onDays;

  /// No description provided for @monthlyByDay.
  ///
  /// In es, this message translates to:
  /// **'El día {day}'**
  String monthlyByDay(int day);

  /// No description provided for @monthlyByPosition.
  ///
  /// In es, this message translates to:
  /// **'El {ordinal} {weekday}'**
  String monthlyByPosition(String ordinal, String weekday);

  /// No description provided for @ordinal.
  ///
  /// In es, this message translates to:
  /// **'{n, select, 1{primer} 2{segundo} 3{tercer} 4{cuarto} 5{quinto} other{último}}'**
  String ordinal(String n);

  /// No description provided for @endsLabel.
  ///
  /// In es, this message translates to:
  /// **'Termina'**
  String get endsLabel;

  /// No description provided for @endsNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get endsNever;

  /// No description provided for @endsUntil.
  ///
  /// In es, this message translates to:
  /// **'Hasta una fecha'**
  String get endsUntil;

  /// No description provided for @endsCount.
  ///
  /// In es, this message translates to:
  /// **'Tras N repeticiones'**
  String get endsCount;

  /// No description provided for @repetitions.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get repetitions;

  /// No description provided for @rrEveryDay.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Cada día} other{Cada {n} días}}'**
  String rrEveryDay(int n);

  /// No description provided for @rrEveryWeek.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Cada semana} other{Cada {n} semanas}}'**
  String rrEveryWeek(int n);

  /// No description provided for @rrEveryMonth.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Cada mes} other{Cada {n} meses}}'**
  String rrEveryMonth(int n);

  /// No description provided for @rrEveryYear.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Cada año} other{Cada {n} años}}'**
  String rrEveryYear(int n);

  /// No description provided for @rrOnMonthDay.
  ///
  /// In es, this message translates to:
  /// **'el día {day}'**
  String rrOnMonthDay(int day);

  /// No description provided for @rrOnNth.
  ///
  /// In es, this message translates to:
  /// **'el {ordinal} {weekday}'**
  String rrOnNth(String ordinal, String weekday);

  /// No description provided for @rrOnDate.
  ///
  /// In es, this message translates to:
  /// **'el {date}'**
  String rrOnDate(String date);

  /// No description provided for @rrUntil.
  ///
  /// In es, this message translates to:
  /// **'hasta el {date}'**
  String rrUntil(String date);

  /// No description provided for @rrCount.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 vez} other{{n} veces}}'**
  String rrCount(int n);

  /// No description provided for @listAnd.
  ///
  /// In es, this message translates to:
  /// **'y'**
  String get listAnd;

  /// No description provided for @listSeparator.
  ///
  /// In es, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @overdueTitle.
  ///
  /// In es, this message translates to:
  /// **'Tareas atrasadas'**
  String get overdueTitle;

  /// No description provided for @overdueBody.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Tienes 1 tarea sin completar de días pasados.} other{Tienes {n} tareas sin completar de días pasados.}}'**
  String overdueBody(int n);

  /// No description provided for @moveToToday.
  ///
  /// In es, this message translates to:
  /// **'Mover a hoy'**
  String get moveToToday;

  /// No description provided for @reschedule.
  ///
  /// In es, this message translates to:
  /// **'Reprogramar'**
  String get reschedule;

  /// No description provided for @discard.
  ///
  /// In es, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @allToToday.
  ///
  /// In es, this message translates to:
  /// **'Todas a hoy'**
  String get allToToday;

  /// No description provided for @discardAll.
  ///
  /// In es, this message translates to:
  /// **'Descartar todas'**
  String get discardAll;

  /// No description provided for @later.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get later;

  /// No description provided for @inboxEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay tareas sin fecha'**
  String get inboxEmpty;

  /// No description provided for @dragToCalendar.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsada una tarea y arrástrala a un hueco del calendario'**
  String get dragToCalendar;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en títulos, notas y subtareas'**
  String get searchHint;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @statusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get statusCompleted;

  /// No description provided for @statusOverdue.
  ///
  /// In es, this message translates to:
  /// **'Atrasada'**
  String get statusOverdue;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @dateRange.
  ///
  /// In es, this message translates to:
  /// **'Fechas'**
  String get dateRange;

  /// No description provided for @anyDate.
  ///
  /// In es, this message translates to:
  /// **'Cualquier fecha'**
  String get anyDate;

  /// No description provided for @clearFilters.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get clearFilters;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @selectedCount.
  ///
  /// In es, this message translates to:
  /// **'{n} seleccionadas'**
  String selectedCount(int n);

  /// No description provided for @moveTo.
  ///
  /// In es, this message translates to:
  /// **'Mover a…'**
  String get moveTo;

  /// No description provided for @changeCategory.
  ///
  /// In es, this message translates to:
  /// **'Cambiar categoría'**
  String get changeCategory;

  /// No description provided for @theme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In es, this message translates to:
  /// **'Color de acento'**
  String get accentColor;

  /// No description provided for @dynamicColor.
  ///
  /// In es, this message translates to:
  /// **'Color del fondo de pantalla (Android 12+)'**
  String get dynamicColor;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In es, this message translates to:
  /// **'Idioma del sistema'**
  String get languageSystem;

  /// No description provided for @weekStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio de semana'**
  String get weekStart;

  /// No description provided for @monday.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get monday;

  /// No description provided for @sunday.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get sunday;

  /// No description provided for @showWeekNumbers.
  ///
  /// In es, this message translates to:
  /// **'Mostrar número de semana'**
  String get showWeekNumbers;

  /// No description provided for @notificationsSection.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get notificationsSection;

  /// No description provided for @defaultReminder.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio por defecto'**
  String get defaultReminder;

  /// No description provided for @none.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get none;

  /// No description provided for @dailySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen diario'**
  String get dailySummary;

  /// No description provided for @weeklySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen semanal'**
  String get weeklySummary;

  /// No description provided for @monthlySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen mensual (día 1)'**
  String get monthlySummary;

  /// No description provided for @summaryTime.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get summaryTime;

  /// No description provided for @summaryDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get summaryDay;

  /// No description provided for @haptics.
  ///
  /// In es, this message translates to:
  /// **'Vibración'**
  String get haptics;

  /// No description provided for @animations.
  ///
  /// In es, this message translates to:
  /// **'Animaciones'**
  String get animations;

  /// No description provided for @swipeLeftAction.
  ///
  /// In es, this message translates to:
  /// **'Deslizar a la izquierda'**
  String get swipeLeftAction;

  /// No description provided for @swipeDelete.
  ///
  /// In es, this message translates to:
  /// **'Borra'**
  String get swipeDelete;

  /// No description provided for @swipePostpone.
  ///
  /// In es, this message translates to:
  /// **'Pospone'**
  String get swipePostpone;

  /// No description provided for @reviewDay.
  ///
  /// In es, this message translates to:
  /// **'Día de la revisión semanal'**
  String get reviewDay;

  /// No description provided for @appearanceSection.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get appearanceSection;

  /// No description provided for @calendarSection.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get calendarSection;

  /// No description provided for @interactionSection.
  ///
  /// In es, this message translates to:
  /// **'Interacción'**
  String get interactionSection;

  /// No description provided for @dataSection.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get dataSection;

  /// No description provided for @exportBackup.
  ///
  /// In es, this message translates to:
  /// **'Exportar copia'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In es, this message translates to:
  /// **'Importar copia'**
  String get importBackup;

  /// No description provided for @exportBackupHint.
  ///
  /// In es, this message translates to:
  /// **'Archivo .zip con tus tareas y adjuntos para guardarlo donde quieras'**
  String get exportBackupHint;

  /// No description provided for @importBackupHint.
  ///
  /// In es, this message translates to:
  /// **'Restaura desde un archivo .zip exportado antes'**
  String get importBackupHint;

  /// No description provided for @importConfirm.
  ///
  /// In es, this message translates to:
  /// **'Importar reemplaza todos los datos actuales. ¿Continuar?'**
  String get importConfirm;

  /// No description provided for @backupExported.
  ///
  /// In es, this message translates to:
  /// **'Copia exportada'**
  String get backupExported;

  /// No description provided for @backupImported.
  ///
  /// In es, this message translates to:
  /// **'Copia restaurada'**
  String get backupImported;

  /// No description provided for @backupError.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String backupError(String error);

  /// No description provided for @newCategory.
  ///
  /// In es, this message translates to:
  /// **'Nueva categoría'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get categoryName;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar «{name}»? Sus tareas quedarán sin categoría.'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @catUni.
  ///
  /// In es, this message translates to:
  /// **'Uni'**
  String get catUni;

  /// No description provided for @catWork.
  ///
  /// In es, this message translates to:
  /// **'Trabajo'**
  String get catWork;

  /// No description provided for @catPersonal.
  ///
  /// In es, this message translates to:
  /// **'Personal'**
  String get catPersonal;

  /// No description provided for @notifPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'Activar avisos'**
  String get notifPermissionTitle;

  /// No description provided for @notifPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'La app te avisa antes de cada tarea, incluso con la app cerrada. Para ello necesita permiso para mostrar notificaciones y programar alarmas exactas.'**
  String get notifPermissionBody;

  /// No description provided for @allow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get allow;

  /// No description provided for @notifActionComplete.
  ///
  /// In es, this message translates to:
  /// **'Completar'**
  String get notifActionComplete;

  /// No description provided for @notifActionSnooze.
  ///
  /// In es, this message translates to:
  /// **'Posponer 10 min'**
  String get notifActionSnooze;

  /// No description provided for @notifChannelReminders.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios'**
  String get notifChannelReminders;

  /// No description provided for @notifChannelSummaries.
  ///
  /// In es, this message translates to:
  /// **'Resúmenes'**
  String get notifChannelSummaries;

  /// No description provided for @startsIn.
  ///
  /// In es, this message translates to:
  /// **'Empieza en {n} min'**
  String startsIn(int n);

  /// No description provided for @startsNow.
  ///
  /// In es, this message translates to:
  /// **'Empieza ahora'**
  String get startsNow;

  /// No description provided for @startsAt.
  ///
  /// In es, this message translates to:
  /// **'A las {time}'**
  String startsAt(String time);

  /// No description provided for @dailySummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu día'**
  String get dailySummaryTitle;

  /// No description provided for @dailySummaryBody.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{No tienes tareas hoy} =1{1 tarea hoy: {first}} other{{n} tareas hoy: {first}}}'**
  String dailySummaryBody(int n, String first);

  /// No description provided for @weeklySummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu semana'**
  String get weeklySummaryTitle;

  /// No description provided for @weeklySummaryBody.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Semana libre de tareas} =1{1 tarea esta semana} other{{n} tareas esta semana}}'**
  String weeklySummaryBody(int n);

  /// No description provided for @monthlySummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu mes'**
  String get monthlySummaryTitle;

  /// No description provided for @monthlySummaryBody.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 tarea este mes} other{{n} tareas este mes}}{countdowns}'**
  String monthlySummaryBody(int n, String countdowns);

  /// No description provided for @daysLeft.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Es hoy} =1{Falta 1 día} other{Faltan {n} días}}'**
  String daysLeft(int n);

  /// No description provided for @daysAgo.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{Hace 1 día} other{Hace {n} días}}'**
  String daysAgo(int n);

  /// No description provided for @suggestCompleteTask.
  ///
  /// In es, this message translates to:
  /// **'Has completado todas las subtareas. ¿Completar la tarea?'**
  String get suggestCompleteTask;

  /// No description provided for @quickAddHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué tienes que hacer?'**
  String get quickAddHint;

  /// No description provided for @weekNumberShort.
  ///
  /// In es, this message translates to:
  /// **'S{n}'**
  String weekNumberShort(int n);

  /// No description provided for @noTasks.
  ///
  /// In es, this message translates to:
  /// **'Sin tareas'**
  String get noTasks;

  /// No description provided for @pinnedSection.
  ///
  /// In es, this message translates to:
  /// **'Fijadas'**
  String get pinnedSection;

  /// No description provided for @countdownSection.
  ///
  /// In es, this message translates to:
  /// **'Cuentas atrás'**
  String get countdownSection;

  /// No description provided for @loadMore.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get loadMore;

  /// No description provided for @repeats.
  ///
  /// In es, this message translates to:
  /// **'Se repite'**
  String get repeats;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Algo ha fallado'**
  String get error;

  /// No description provided for @allDayShort.
  ///
  /// In es, this message translates to:
  /// **'Todo el día'**
  String get allDayShort;

  /// No description provided for @unscheduled.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get unscheduled;

  /// No description provided for @attachments.
  ///
  /// In es, this message translates to:
  /// **'Adjuntos'**
  String get attachments;

  /// No description provided for @addPhoto.
  ///
  /// In es, this message translates to:
  /// **'Foto'**
  String get addPhoto;

  /// No description provided for @addFromGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get addFromGallery;

  /// No description provided for @addFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get addFile;

  /// No description provided for @timer.
  ///
  /// In es, this message translates to:
  /// **'Tiempo dedicado'**
  String get timer;

  /// No description provided for @timerStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get timerStart;

  /// No description provided for @timerPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get timerPause;

  /// No description provided for @timerStop.
  ///
  /// In es, this message translates to:
  /// **'Parar'**
  String get timerStop;

  /// No description provided for @timerReset.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get timerReset;

  /// No description provided for @estimatedVsReal.
  ///
  /// In es, this message translates to:
  /// **'Estimado {est} · Real {real}'**
  String estimatedVsReal(String est, String real);

  /// No description provided for @applyTemplate.
  ///
  /// In es, this message translates to:
  /// **'Aplicar a un día'**
  String get applyTemplate;

  /// No description provided for @newTemplate.
  ///
  /// In es, this message translates to:
  /// **'Nueva plantilla'**
  String get newTemplate;

  /// No description provided for @templateName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la plantilla'**
  String get templateName;

  /// No description provided for @templateApplied.
  ///
  /// In es, this message translates to:
  /// **'Plantilla aplicada'**
  String get templateApplied;

  /// No description provided for @saveAsTemplate.
  ///
  /// In es, this message translates to:
  /// **'Guardar día como plantilla'**
  String get saveAsTemplate;

  /// No description provided for @noTemplates.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay plantillas. Guarda un día como plantilla desde la vista día.'**
  String get noTemplates;

  /// No description provided for @addItem.
  ///
  /// In es, this message translates to:
  /// **'Añadir tarea'**
  String get addItem;

  /// No description provided for @statsCompletionRate.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get statsCompletionRate;

  /// No description provided for @statsThisWeek.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get statsThisMonth;

  /// No description provided for @statsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get statsToday;

  /// No description provided for @statsStreak.
  ///
  /// In es, this message translates to:
  /// **'Racha'**
  String get statsStreak;

  /// No description provided for @statsStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 día} other{{n} días}}'**
  String statsStreakDays(int n);

  /// No description provided for @statsBestStreak.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha: {n}'**
  String statsBestStreak(int n);

  /// No description provided for @statsHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos (tareas repetidas)'**
  String get statsHabits;

  /// No description provided for @statsTimeByCategory.
  ///
  /// In es, this message translates to:
  /// **'Estimado vs. real por categoría'**
  String get statsTimeByCategory;

  /// No description provided for @statsLast7Days.
  ///
  /// In es, this message translates to:
  /// **'Últimos 7 días'**
  String get statsLast7Days;

  /// No description provided for @statsWeeklySummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen semanal'**
  String get statsWeeklySummary;

  /// No description provided for @statsWeeklySummaryBody.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total} completadas · {minutes} min dedicados'**
  String statsWeeklySummaryBody(int done, int total, int minutes);

  /// No description provided for @reviewStep1.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get reviewStep1;

  /// No description provided for @reviewStep1Body.
  ///
  /// In es, this message translates to:
  /// **'Tareas atrasadas o sin completar de la semana pasada'**
  String get reviewStep1Body;

  /// No description provided for @reviewStep2.
  ///
  /// In es, this message translates to:
  /// **'Próxima semana'**
  String get reviewStep2;

  /// No description provided for @reviewStep2Body.
  ///
  /// In es, this message translates to:
  /// **'Lo que tienes planificado'**
  String get reviewStep2Body;

  /// No description provided for @reviewStep3.
  ///
  /// In es, this message translates to:
  /// **'Bandeja'**
  String get reviewStep3;

  /// No description provided for @reviewStep3Body.
  ///
  /// In es, this message translates to:
  /// **'Coloca tareas sin fecha en huecos libres'**
  String get reviewStep3Body;

  /// No description provided for @reviewDone.
  ///
  /// In es, this message translates to:
  /// **'Revisión completada'**
  String get reviewDone;

  /// No description provided for @reviewNothing.
  ///
  /// In es, this message translates to:
  /// **'Nada por aquí'**
  String get reviewNothing;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @finish.
  ///
  /// In es, this message translates to:
  /// **'Terminar'**
  String get finish;

  /// No description provided for @placeInFreeSlot.
  ///
  /// In es, this message translates to:
  /// **'Colocar en hueco libre'**
  String get placeInFreeSlot;

  /// No description provided for @placedAt.
  ///
  /// In es, this message translates to:
  /// **'Colocada el {when}'**
  String placedAt(String when);

  /// No description provided for @reviewReminder.
  ///
  /// In es, this message translates to:
  /// **'Toca tu revisión semanal'**
  String get reviewReminder;

  /// No description provided for @allDoneCelebration.
  ///
  /// In es, this message translates to:
  /// **'¡Día completado!'**
  String get allDoneCelebration;

  /// No description provided for @quickAddPreview.
  ///
  /// In es, this message translates to:
  /// **'Detectado'**
  String get quickAddPreview;

  /// No description provided for @naturalLanguageHint.
  ///
  /// In es, this message translates to:
  /// **'p. ej. «gym mañana 18h cada lunes #Personal !alta»'**
  String get naturalLanguageHint;

  /// No description provided for @widgetTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get widgetTodayTitle;

  /// No description provided for @openMap.
  ///
  /// In es, this message translates to:
  /// **'Abrir en mapas'**
  String get openMap;

  /// No description provided for @openLink.
  ///
  /// In es, this message translates to:
  /// **'Abrir enlace'**
  String get openLink;

  /// No description provided for @notificationsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Los avisos están desactivados en el sistema'**
  String get notificationsDisabled;

  /// No description provided for @exactAlarmsDisabled.
  ///
  /// In es, this message translates to:
  /// **'Las alarmas exactas están desactivadas: los avisos pueden retrasarse'**
  String get exactAlarmsDisabled;

  /// No description provided for @openSystemSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get openSystemSettings;

  /// No description provided for @about.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get about;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
