// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calendar';

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
}
