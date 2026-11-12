// Ajustes de la app, guardados como clave/valor en la tabla Settings.

import 'notification_plan.dart';
import 'stats.dart';

/// Vistas del calendario. `threeDays` = hoy, mañana y pasado; `workWeek` =
/// lunes a viernes.
enum CalendarView { day, threeDays, week, workWeek, month, agenda }

enum AppThemeMode { system, light, dark }

enum SwipeLeftAction { delete, postpone }

/// Páginas del carrusel del menú lateral.
enum MenuCard { today, streak, goal, villager }

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

  // Habitante
  static const kVillagerEnabled = 'whale.enabled';
  static const kVillagerFloating = 'whale.floating';
  static const kVillagerDrawer = 'whale.drawer';
  static const kVillagerTank = 'whale.tank';
  static const kVillagerPos = 'whale.pos';

  // Carrusel del menú
  /// Páginas visibles, separadas por comas (nombres de [MenuCard]).
  static const kMenuCards = 'menu.cards';
  static const kStreakRule = 'streak.rule';

  /// «p:ID» (proyecto) o «c:ID» (categoría); vacío = sin meta.
  static const kWeeklyGoal = 'goal.target';

  /// Lo escriben la importación de copias y de .ics: el habitante re-basa el
  /// recuento de completadas en vez de «comer» lo importado.
  static const kVillagerRebase = 'whale.rebase';

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

  bool get villagerEnabled => _b(kVillagerEnabled, true);
  bool get villagerFloating => _b(kVillagerFloating, true);
  bool get villagerDrawer => _b(kVillagerDrawer, true);
  bool get villagerTank => _b(kVillagerTank, true);
  String? get villagerPos => _s(kVillagerPos);

  /// Por defecto, todas en orden.
  List<MenuCard> get menuCards {
    final v = _s(kMenuCards);
    if (v == null) return MenuCard.values;
    final names = v.split(',').toSet();
    return [for (final c in MenuCard.values) if (names.contains(c.name)) c];
  }

  StreakRule get streakRule => StreakRule.values.asNameMap()[_s(kStreakRule)] ?? StreakRule.all;
  String? get weeklyGoal {
    final v = _s(kWeeklyGoal);
    return v == null || v.isEmpty ? null : v;
  }

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
