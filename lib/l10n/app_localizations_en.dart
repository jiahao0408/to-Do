// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'to Do';

  @override
  String get viewDay => 'Day';

  @override
  String get viewWeek => 'Week';

  @override
  String get viewMonth => 'Month';

  @override
  String get viewAgenda => 'Agenda';

  @override
  String get today => 'Today';

  @override
  String get goToDate => 'Go to date';

  @override
  String get search => 'Search';

  @override
  String get inbox => 'Inbox';

  @override
  String get settings => 'Settings';

  @override
  String get categories => 'Categories';

  @override
  String get templates => 'Templates';

  @override
  String get statistics => 'Statistics';

  @override
  String get weeklyReview => 'Weekly review';

  @override
  String get backup => 'Backup';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get title => 'Title';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get notes => 'Notes';

  @override
  String get date => 'Date';

  @override
  String get noDate => 'No date (inbox)';

  @override
  String get allDay => 'All day';

  @override
  String get startTime => 'Start';

  @override
  String get endTime => 'End';

  @override
  String get duration => 'Duration';

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String get category => 'Category';

  @override
  String get noCategory => 'No category';

  @override
  String get priority => 'Priority';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String get location => 'Location';

  @override
  String get link => 'Link';

  @override
  String get estimate => 'Estimated time (min)';

  @override
  String get pinned => 'Pinned';

  @override
  String get countdownLabel => 'Countdown (important date)';

  @override
  String get subtasks => 'Subtasks';

  @override
  String get addSubtask => 'Add subtask';

  @override
  String get reminders => 'Reminders';

  @override
  String get reminderAtTime => 'At start time';

  @override
  String reminderMinutesBefore(int n) {
    return '$n min before';
  }

  @override
  String reminderHoursBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours before',
      one: '1 hour before',
    );
    return '$_temp0';
  }

  @override
  String reminderDaysBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get customReminder => 'Custom…';

  @override
  String get minutesBeforeLabel => 'Minutes before';

  @override
  String get repeat => 'Repeat';

  @override
  String get noRepeat => 'Does not repeat';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get complete => 'Complete';

  @override
  String get uncomplete => 'Mark as pending';

  @override
  String get postpone => 'Postpone';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get skipOccurrence => 'Skip this one';

  @override
  String get undo => 'Undo';

  @override
  String get moreOptions => 'More options';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String completedCount(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get taskCompleted => 'Task completed';

  @override
  String get taskUncompleted => 'Task pending';

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String get taskMoved => 'Task moved';

  @override
  String get taskSaved => 'Task saved';

  @override
  String get taskSkipped => 'Occurrence skipped';

  @override
  String get taskDuplicated => 'Task duplicated';

  @override
  String taskPostponed(String when) {
    return 'Postponed to $when';
  }

  @override
  String tasksCompleted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks completed',
      one: '1 task completed',
    );
    return '$_temp0';
  }

  @override
  String tasksDeleted(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks deleted',
      one: '1 task deleted',
    );
    return '$_temp0';
  }

  @override
  String tasksMoved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks moved',
      one: '1 task moved',
    );
    return '$_temp0';
  }

  @override
  String overlapWarning(String title) {
    return 'Overlaps with “$title”';
  }

  @override
  String get deleteConfirmTitle => 'Delete task?';

  @override
  String get deleteConfirmBody => 'You can undo this for a few seconds.';

  @override
  String get scopeEditTitle => 'Edit repeating task';

  @override
  String get scopeDeleteTitle => 'Delete repeating task';

  @override
  String get scopeThisOne => 'This one only';

  @override
  String get scopeThisAndFollowing => 'This and following';

  @override
  String get scopeAll => 'All';

  @override
  String get scopeSelected => 'Selected…';

  @override
  String get selectOccurrences => 'Choose occurrences';

  @override
  String get postponePlusHour => '+1 hour';

  @override
  String get postponeThisAfternoon => 'This afternoon';

  @override
  String get postponeTomorrow => 'Tomorrow';

  @override
  String get postponeNextWeek => 'Next week';

  @override
  String get postponePickDate => 'Pick a date…';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get every => 'Every';

  @override
  String intervalUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'day': 'days',
      'week': 'weeks',
      'month': 'months',
      'year': 'years',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get onDays => 'Days';

  @override
  String monthlyByDay(int day) {
    return 'On day $day';
  }

  @override
  String monthlyByPosition(String ordinal, String weekday) {
    return 'On the $ordinal $weekday';
  }

  @override
  String ordinal(String n) {
    String _temp0 = intl.Intl.selectLogic(n, {
      '1': 'first',
      '2': 'second',
      '3': 'third',
      '4': 'fourth',
      '5': 'fifth',
      'other': 'last',
    });
    return '$_temp0';
  }

  @override
  String get endsLabel => 'Ends';

  @override
  String get endsNever => 'Never';

  @override
  String get endsUntil => 'On a date';

  @override
  String get endsCount => 'After N times';

  @override
  String get repetitions => 'Repetitions';

  @override
  String rrEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String rrEveryWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String rrEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String rrEveryYear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String rrOnMonthDay(int day) {
    return 'on day $day';
  }

  @override
  String rrOnNth(String ordinal, String weekday) {
    return 'on the $ordinal $weekday';
  }

  @override
  String rrOnDate(String date) {
    return 'on $date';
  }

  @override
  String rrUntil(String date) {
    return 'until $date';
  }

  @override
  String rrCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String get listAnd => 'and';

  @override
  String get listSeparator => ', ';

  @override
  String get overdueTitle => 'Overdue tasks';

  @override
  String overdueBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'You have $n unfinished tasks from past days.',
      one: 'You have 1 unfinished task from past days.',
    );
    return '$_temp0';
  }

  @override
  String get moveToToday => 'Move to today';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get discard => 'Discard';

  @override
  String get allToToday => 'All to today';

  @override
  String get discardAll => 'Discard all';

  @override
  String get later => 'Later';

  @override
  String get inboxEmpty => 'No tasks without a date';

  @override
  String get dragToCalendar =>
      'Long-press a task and drag it to a free slot in the calendar';

  @override
  String get searchHint => 'Search titles, notes and subtasks';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get status => 'Status';

  @override
  String get dateRange => 'Dates';

  @override
  String get anyDate => 'Any date';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get noResults => 'No results';

  @override
  String selectedCount(int n) {
    return '$n selected';
  }

  @override
  String get moveTo => 'Move to…';

  @override
  String get changeCategory => 'Change category';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent color';

  @override
  String get dynamicColor => 'Wallpaper colors (Android 12+)';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get weekStart => 'Week starts on';

  @override
  String get monday => 'Monday';

  @override
  String get sunday => 'Sunday';

  @override
  String get showWeekNumbers => 'Show week numbers';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get defaultReminder => 'Default reminder';

  @override
  String get none => 'None';

  @override
  String get dailySummary => 'Daily summary';

  @override
  String get weeklySummary => 'Weekly summary';

  @override
  String get monthlySummary => 'Monthly summary (1st)';

  @override
  String get summaryTime => 'Time';

  @override
  String get summaryDay => 'Day';

  @override
  String get haptics => 'Vibration';

  @override
  String get animations => 'Animations';

  @override
  String get swipeLeftAction => 'Swipe left';

  @override
  String get swipeDelete => 'Deletes';

  @override
  String get swipePostpone => 'Postpones';

  @override
  String get reviewDay => 'Weekly review day';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get calendarSection => 'Calendar';

  @override
  String get interactionSection => 'Interaction';

  @override
  String get dataSection => 'Data';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Import backup';

  @override
  String get exportBackupHint =>
      '.zip file with your tasks and attachments to save wherever you like';

  @override
  String get importBackupHint => 'Restore from a previously exported .zip file';

  @override
  String get importConfirm => 'Importing replaces all current data. Continue?';

  @override
  String get backupExported => 'Backup exported';

  @override
  String get backupImported => 'Backup restored';

  @override
  String backupError(String error) {
    return 'Error: $error';
  }

  @override
  String get newCategory => 'New category';

  @override
  String get categoryName => 'Name';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete “$name”? Its tasks will have no category.';
  }

  @override
  String get catUni => 'Uni';

  @override
  String get catWork => 'Work';

  @override
  String get catPersonal => 'Personal';

  @override
  String get notifPermissionTitle => 'Turn on reminders';

  @override
  String get notifPermissionBody =>
      'The app reminds you before each task, even when it is closed. It needs permission to show notifications and schedule exact alarms.';

  @override
  String get allow => 'Allow';

  @override
  String get notifActionComplete => 'Complete';

  @override
  String get notifActionSnooze => 'Snooze 10 min';

  @override
  String get notifChannelReminders => 'Reminders';

  @override
  String get notifChannelSummaries => 'Summaries';

  @override
  String startsIn(int n) {
    return 'Starts in $n min';
  }

  @override
  String get startsNow => 'Starts now';

  @override
  String startsAt(String time) {
    return 'At $time';
  }

  @override
  String get dailySummaryTitle => 'Your day';

  @override
  String dailySummaryBody(int n, String first) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks today: $first',
      one: '1 task today: $first',
      zero: 'No tasks today',
    );
    return '$_temp0';
  }

  @override
  String get weeklySummaryTitle => 'Your week';

  @override
  String weeklySummaryBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks this week',
      one: '1 task this week',
      zero: 'No tasks this week',
    );
    return '$_temp0';
  }

  @override
  String get monthlySummaryTitle => 'Your month';

  @override
  String monthlySummaryBody(int n, String countdowns) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks this month',
      one: '1 task this month',
    );
    return '$_temp0$countdowns';
  }

  @override
  String daysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days left',
      one: '1 day left',
      zero: 'It\'s today',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get suggestCompleteTask => 'All subtasks are done. Complete the task?';

  @override
  String get quickAddHint => 'What do you need to do?';

  @override
  String weekNumberShort(int n) {
    return 'W$n';
  }

  @override
  String get noTasks => 'No tasks';

  @override
  String get pinnedSection => 'Pinned';

  @override
  String get countdownSection => 'Countdowns';

  @override
  String get loadMore => 'Show more';

  @override
  String get repeats => 'Repeats';

  @override
  String get error => 'Something went wrong';

  @override
  String get allDayShort => 'All day';

  @override
  String get unscheduled => 'No date';

  @override
  String get attachments => 'Attachments';

  @override
  String get addPhoto => 'Photo';

  @override
  String get addFromGallery => 'Gallery';

  @override
  String get addFile => 'File';

  @override
  String get timer => 'Time spent';

  @override
  String get timerStart => 'Start';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerStop => 'Stop';

  @override
  String get timerReset => 'Reset';

  @override
  String estimatedVsReal(String est, String real) {
    return 'Estimated $est · Actual $real';
  }

  @override
  String get applyTemplate => 'Apply to a day';

  @override
  String get newTemplate => 'New template';

  @override
  String get templateName => 'Template name';

  @override
  String get templateApplied => 'Template applied';

  @override
  String get saveAsTemplate => 'Save day as template';

  @override
  String get noTemplates =>
      'No templates yet. Save a day as a template from the day view.';

  @override
  String get addItem => 'Add task';

  @override
  String get statsCompletionRate => 'Completed';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsToday => 'Today';

  @override
  String get statsStreak => 'Streak';

  @override
  String statsStreakDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String statsBestStreak(int n) {
    return 'Best streak: $n';
  }

  @override
  String get statsHabits => 'Habits (repeating tasks)';

  @override
  String get statsTimeByCategory => 'Estimated vs. actual by category';

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsWeeklySummary => 'Weekly summary';

  @override
  String statsWeeklySummaryBody(int done, int total, int minutes) {
    return '$done of $total completed · $minutes min spent';
  }

  @override
  String get reviewStep1 => 'Pending';

  @override
  String get reviewStep1Body => 'Overdue or unfinished tasks from last week';

  @override
  String get reviewStep2 => 'Next week';

  @override
  String get reviewStep2Body => 'What you have planned';

  @override
  String get reviewStep3 => 'Inbox';

  @override
  String get reviewStep3Body => 'Place undated tasks in free slots';

  @override
  String get reviewDone => 'Review complete';

  @override
  String get reviewNothing => 'Nothing here';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String get placeInFreeSlot => 'Place in a free slot';

  @override
  String placedAt(String when) {
    return 'Placed on $when';
  }

  @override
  String get reviewReminder => 'Time for your weekly review';

  @override
  String get allDoneCelebration => 'Day complete!';

  @override
  String get quickAddPreview => 'Detected';

  @override
  String get naturalLanguageHint =>
      'e.g. “dentist next tuesday 10am for 1h #Personal !high”';

  @override
  String get widgetTodayTitle => 'Today';

  @override
  String get openMap => 'Open in maps';

  @override
  String get openLink => 'Open link';

  @override
  String get notificationsDisabled =>
      'Notifications are turned off in system settings';

  @override
  String get exactAlarmsDisabled =>
      'Exact alarms are off: reminders may be late';

  @override
  String get openSystemSettings => 'Open settings';

  @override
  String get about => 'About';

  @override
  String get viewThreeDays => '3 days';

  @override
  String get viewWorkWeek => 'Work week';

  @override
  String get icsImport => 'Import .ics';

  @override
  String get icsExport => 'Export .ics';

  @override
  String get icsImportHint =>
      'Add events from Google Calendar, Outlook or other apps';

  @override
  String get icsExportHint => 'Share your tasks as a calendar file';

  @override
  String get icsSelectAll => 'All';

  @override
  String get icsSelectNone => 'None';

  @override
  String get icsAlreadyImported => 'Already imported: replaced if checked';

  @override
  String get icsUnsupportedRule =>
      'Unsupported repeat: only the first one is imported';

  @override
  String get icsMultiDay => 'Multi-day: imported on its first day';

  @override
  String get icsCategoryFromFile => 'From the file';

  @override
  String icsImportButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Import $n',
      one: 'Import 1',
    );
    return '$_temp0';
  }

  @override
  String icsImported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks imported',
      one: '1 task imported',
    );
    return '$_temp0';
  }

  @override
  String get icsNothing => 'The file has no events or tasks';

  @override
  String icsError(String error) {
    return 'Could not read the file: $error';
  }

  @override
  String get icsRange => 'Dates';

  @override
  String get icsAllDates => 'All';

  @override
  String get icsChooseRange => 'Choose range';

  @override
  String get icsIncludeCompleted => 'Include completed';

  @override
  String get icsIncludeUndated => 'Include undated tasks (as to-dos)';

  @override
  String icsWillExport(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks will be exported',
      one: '1 task will be exported',
      zero: 'Nothing to export',
    );
    return '$_temp0';
  }

  @override
  String get icsExportButton => 'Export and share';

  @override
  String get projects => 'Projects';

  @override
  String get project => 'Project';

  @override
  String get newProject => 'New project';

  @override
  String get projectName => 'Project name';

  @override
  String get noProject => 'No project';

  @override
  String get projectDue => 'Due date';

  @override
  String get noDueDate => 'No due date';

  @override
  String deleteProjectConfirm(String name) {
    return 'Delete “$name”? Its tasks will have no project.';
  }

  @override
  String get projectEmpty => 'This project has no tasks yet';

  @override
  String get projectSeriesNote =>
      'Repeating tasks do not count towards progress';

  @override
  String get diary => 'Journal';

  @override
  String get dayNote => 'Note of the day';

  @override
  String get dayNoteHint => 'How did the day go?';

  @override
  String get diaryEmpty => 'Nothing written in the journal yet';

  @override
  String get searchDiary => 'Search the journal';

  @override
  String get showInCalendar => 'Show in calendar';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get countdownsAndPinned => 'Countdowns and pinned';

  @override
  String get nothingPinned => 'Nothing pinned or counting down';

  @override
  String get processInbox => 'Process inbox';

  @override
  String processInboxProgress(int i, int n) {
    return '$i of $n';
  }

  @override
  String get skip => 'Skip';

  @override
  String get inboxDone => 'Inbox zero!';

  @override
  String get gestureGuide => 'Gesture guide';

  @override
  String get gestures => 'Gestures';

  @override
  String get naturalLanguage => 'Natural language';

  @override
  String get gTapBlock => 'Tap a task: see its details';

  @override
  String get gLongPressMove =>
      'Long-press and move: change the time (and the day in week or 3-day view)';

  @override
  String get gLongPress => 'Long-press without moving: multi-select';

  @override
  String get gResize => 'Drag the bottom edge of a block: change its duration';

  @override
  String get gPinch => 'Pinch with two fingers: zoom the hours in or out';

  @override
  String get gSwipePages =>
      'Swipe sideways: previous or next day, week or month';

  @override
  String get gSwipeList =>
      'In lists: swipe right to complete; left to delete or postpone';

  @override
  String get gLongPressEmpty =>
      'Long-press an empty slot: create a task at that time';

  @override
  String get gWeekTap =>
      'Tap «Week» again: switch to work week (Monday to Friday)';

  @override
  String get gInboxDrag =>
      'Inbox: long-press a task and drop it on a calendar slot';

  @override
  String get gMonthDrag =>
      'Month view: long-press a task and drop it on another day';

  @override
  String get nlTips =>
      'Type the task with date, time, repeat, #category and !priority';

  @override
  String heatmapTitle(int year) {
    return 'Year $year';
  }

  @override
  String get heatLess => 'Less';

  @override
  String get heatMore => 'More';

  @override
  String villagerNormal1(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things left today',
      one: '1 thing left today',
      zero: 'Nothing left for today',
    );
    return '$_temp0';
  }

  @override
  String villagerNormal2(String title, String time) {
    return 'Next: $title at $time';
  }

  @override
  String get villagerNormal3 => 'A little break and we keep going';

  @override
  String get villagerNormal4 => 'Here I am, building with you!';

  @override
  String get villagerCelebrate1 => 'All done! You were great today';

  @override
  String get villagerCelebrate2 => 'Day complete, the village is celebrating!';

  @override
  String get villagerCelebrate3 => 'What a productive day!';

  @override
  String villagerWorried1(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks are overdue… shall we look?',
      one: '1 task is overdue… shall we look?',
    );
    return '$_temp0';
  }

  @override
  String get villagerWorried2 => 'Overdue stuff makes me uneasy…';

  @override
  String get villagerHungry1 =>
      'Running out of energy… finish a task and we keep building';

  @override
  String get villagerHungry2 => 'I have no strength left…';

  @override
  String get villagerSleep1 => 'Zzz…';

  @override
  String get villagerSleep2 => 'Let\'s continue tomorrow…';

  @override
  String get villagerPet1 => 'Hi!';

  @override
  String get villagerPet2 => 'Thanks for stopping by';

  @override
  String get villagerPet3 => 'What a nice day';

  @override
  String get villagerPoked1 => 'Mm… what time is it?';

  @override
  String get villagerPoked2 => 'Five more minutes…';

  @override
  String get villagerEat1 => 'One more brick!';

  @override
  String get villagerEat2 => 'Another task, another!';

  @override
  String get villagerEat3 => 'Let\'s build!';

  @override
  String get villagerTitle => 'Villager';

  @override
  String villagerFullness(int p) {
    return 'Energy $p%';
  }

  @override
  String villagerTodayDone(int done, int total) {
    return 'Today: $done/$total done';
  }

  @override
  String get villagerMoodNormal => 'Calm';

  @override
  String get villagerMoodCelebrate => 'Celebrating';

  @override
  String get villagerMoodWorried => 'In a hurry';

  @override
  String get villagerMoodSleep => 'Sleeping';

  @override
  String get villagerPetButton => 'Wave';

  @override
  String get villagerPokeButton => 'Poke';

  @override
  String get villagerShow => 'Show the villager and the village';

  @override
  String get villagerFloating => 'Calendar corner';

  @override
  String get villagerDrawer => 'Card in the menu';

  @override
  String get villagerTank => 'Village page';

  @override
  String villagerSemantics(String mood, int p) {
    return 'Villager, $mood, energy $p%';
  }

  @override
  String get villageTitle => 'Village';

  @override
  String get villageEmpty => 'Create a project to lay the first stone';

  @override
  String get villageHistoric => 'Historic quarter';

  @override
  String villageStage(int n) {
    return 'Stage $n/10';
  }

  @override
  String get villageHint =>
      'Every 10% of a project adds a stage to its building';

  @override
  String get building => 'Village building';

  @override
  String get buildingAuto => 'Automatic';

  @override
  String get buildingGroupHomes => 'Homes';

  @override
  String get buildingGroupWork => 'Work & study';

  @override
  String get buildingGroupInfrastructure => 'Infrastructure';

  @override
  String get buildingGroupLeisure => 'Leisure & nature';

  @override
  String get buildingHouse => 'House';

  @override
  String get buildingCabin => 'Cabin';

  @override
  String get buildingApartments => 'Apartments';

  @override
  String get buildingSchool => 'School';

  @override
  String get buildingLibrary => 'Library';

  @override
  String get buildingOffice => 'Office';

  @override
  String get buildingWorkshop => 'Workshop';

  @override
  String get buildingBridge => 'Bridge';

  @override
  String get buildingWaterTower => 'Water tower';

  @override
  String get buildingPowerPlant => 'Power plant';

  @override
  String get buildingStation => 'Station';

  @override
  String get buildingPark => 'Park';

  @override
  String get buildingFarm => 'Farm';

  @override
  String get buildingLighthouse => 'Lighthouse';

  @override
  String get buildingCastle => 'Castle';

  @override
  String get cardToday => 'Today';

  @override
  String get cardStreak => 'Streak';

  @override
  String get cardGoal => 'Weekly goal';

  @override
  String get cardVillager => 'Villager';

  @override
  String get cardPages => 'Card pages';

  @override
  String cardOverdue(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n overdue',
      one: '1 overdue',
      zero: 'Nothing overdue',
    );
    return '$_temp0';
  }

  @override
  String cardNext(String title) {
    return 'Next: $title';
  }

  @override
  String get cardNothingNext => 'Nothing else today';

  @override
  String get streakRule => 'Streak rule';

  @override
  String get streakRuleAny => 'At least 1 task';

  @override
  String get streakRuleAll => 'All of the day';

  @override
  String get goalTarget => 'Weekly goal';

  @override
  String get goalNone => 'No goal';

  @override
  String get goalPick => 'Pick a project or a category in Settings';

  @override
  String goalThisWeek(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+$n this week',
      one: '+1 this week',
      zero: 'Nothing this week',
    );
    return '$_temp0';
  }

  @override
  String get villageSection => 'Village & villager';

  @override
  String get menuCardSection => 'Menu card';

  @override
  String get menuCardShow => 'Show the card';
}
