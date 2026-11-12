// Ajustes de la app, guardados como clave/valor en la tabla Settings.

import 'notification_plan.dart';

/// Vistas del calendario. `threeDays` = hoy, mañana y pasado; `workWeek` =
/// lunes a viernes.
enum CalendarView { day, threeDays, week, workWeek, month, agenda }

enum AppThemeMode { system, light, dark }

enum SwipeLeftAction { delete, postpone }

class AppSettings {
  const AppSettings(this.raw);
  final Map<String, String> raw;

  String? _s(String k) => raw[k];
  bool _b(String k, bool def) => raw[k] == null ? def : raw[k] == '1';
  int _i(String k, int def) => int.tryParse(raw[k] ?? '') ?? def;

  // Claves
  static const kLocale = 'locale';
  static const kTheme = 'theme';
  static const kAccent = 'accent';
  static const kDynamicColor = 'dynamicColor';
  static const kWeekStartsMonday = 'weekStartsMonday';
  static const kShowWeekNumbers = 'showWeekNumbers';
  static const kDefaultReminder = 'defaultReminder';
  static const kDailySummary = 'dailySummary';
  static const kDailySummaryMinute = 'dailySummaryMinute';
  static const kWeeklySummary = 'weeklySummary';
  static const kWeeklySummaryWeekday = 'weeklySummaryWeekday';
  static const kWeeklySummaryMinute = 'weeklySummaryMinute';
  static const kMonthlySummary = 'monthlySummary';
  static const kMonthlySummaryMinute = 'monthlySummaryMinute';
  static const kHaptics = 'haptics';
  static const kAnimations = 'animations';
  static const kSwipeLeft = 'swipeLeft';
  static const kLastView = 'lastView';
  static const kHourHeight = 'hourHeight';
  static const kReviewWeekday = 'reviewWeekday';
  static const kLastReviewDate = 'lastReviewDate';
  static const kPermissionAsked = 'permissionAsked';
  static const kSeeded = 'seeded';
  static const kLastOverdueCheck = 'lastOverdueCheck';

  // 鲸鱼娘
  static const kWhaleEnabled = 'whale.enabled';
  static const kWhaleFloating = 'whale.floating';
  static const kWhaleDrawer = 'whale.drawer';
  static const kWhaleTank = 'whale.tank';
  static const kWhalePos = 'whale.pos';

  /// Lo escriben la importación de copias y de .ics: la ballenita re-basa el
  /// recuento de completadas en vez de «comer» lo importado.
  static const kWhaleRebase = 'whale.rebase';

  /// Código de idioma ('es', 'en', 'zh') o null = idioma del sistema.
  String? get localeCode {
    final v = _s(kLocale);
    return v == null || v.isEmpty || v == 'system' ? null : v;
  }

  AppThemeMode get themeMode =>
      AppThemeMode.values.asNameMap()[_s(kTheme)] ?? AppThemeMode.system;
  int get accentColor => _i(kAccent, 0xFF3F51B5);
  bool get dynamicColor => _b(kDynamicColor, true);
  bool get weekStartsMonday => _b(kWeekStartsMonday, true);
  bool get showWeekNumbers => _b(kShowWeekNumbers, false);

  /// Minutos antes del recordatorio por defecto; -1 = sin recordatorio.
  int get defaultReminder => _i(kDefaultReminder, 15);
  bool get haptics => _b(kHaptics, true);
  bool get animations => _b(kAnimations, true);
  SwipeLeftAction get swipeLeft =>
      SwipeLeftAction.values.asNameMap()[_s(kSwipeLeft)] ?? SwipeLeftAction.delete;
  CalendarView get lastView =>
      CalendarView.values.asNameMap()[_s(kLastView)] ?? CalendarView.day;
  double get hourHeight => double.tryParse(_s(kHourHeight) ?? '') ?? 64;
  int get reviewWeekday => _i(kReviewWeekday, DateTime.sunday);
  bool get permissionAsked => _b(kPermissionAsked, false);

  bool get whaleEnabled => _b(kWhaleEnabled, true);
  bool get whaleFloating => _b(kWhaleFloating, true);
  bool get whaleDrawer => _b(kWhaleDrawer, true);
  bool get whaleTank => _b(kWhaleTank, true);
  String? get whalePos => _s(kWhalePos);

  SummarySettings get summaries => SummarySettings(
        dailyEnabled: _b(kDailySummary, false),
        dailyMinute: _i(kDailySummaryMinute, 8 * 60),
        weeklyEnabled: _b(kWeeklySummary, false),
        weeklyWeekday: _i(kWeeklySummaryWeekday, DateTime.monday),
        weeklyMinute: _i(kWeeklySummaryMinute, 8 * 60),
        monthlyEnabled: _b(kMonthlySummary, false),
        monthlyMinute: _i(kMonthlySummaryMinute, 8 * 60),
      );
}
