import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/settings.dart';
import '../domain/snapshot.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import 'home/home_shell.dart';
import 'providers.dart';
import 'task/task_detail.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ns = NotificationService.instance;
    ns.onOpenTask = _openTask;
    ns.onForegroundAction = (r) => handleNotificationAction(r, repo: ref.read(repositoryProvider));
    final launch = TaskPayload.parse(ns.launchPayload);
    if (launch != null) {
      ns.launchPayload = null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(snapshotStreamProvider.future);
        _openTask(launch);
      });
    }
    WidgetService.instance.onOpenTask = _openTask;
    WidgetService.instance.init(ref.read(repositoryProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recoge cambios hechos desde notificaciones o el widget.
      ref.read(repositoryProvider).notifyExternalChange();
    }
  }

  void _openTask(TaskPayload p) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final o = ref.read(snapshotProvider).occurrenceOf(p.taskId, p.date);
    if (o != null) showTaskDetail(ctx, o);
  }

  /// Reprograma avisos y widget cuando cambian los datos (con retardo para
  /// agrupar cambios seguidos).
  void _onData(AppSnapshot snap) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final settings = AppSettings(snap.settings);
      final tz = ref.read(timeZoneProvider);
      NotificationService.instance.reschedule(snap, settings, tzName: tz);
      WidgetService.instance.update(snap, settings, ref.read(clockProvider).now());
    });
  }

  ThemeData _theme(ColorScheme scheme) => ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(snapshotStreamProvider, (_, next) {
      if (next case AsyncData(:final value)) _onData(value);
    });
    final loaded = ref.watch(snapshotStreamProvider).hasValue;
    final settings = ref.watch(settingsProvider);
    final locale = settings.localeCode == null ? null : Locale(settings.localeCode!);
    final mode = switch (settings.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return DynamicColorBuilder(builder: (lightDynamic, darkDynamic) {
      final seed = Color(settings.accentColor);
      final useDynamic = settings.dynamicColor && lightDynamic != null && darkDynamic != null;
      ColorScheme light = ColorScheme.fromSeed(seedColor: seed);
      ColorScheme dark = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
      if (useDynamic) {
        light = lightDynamic;
        dark = darkDynamic;
      }
      return MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
        debugShowCheckedModeBanner: false,
        theme: _theme(light),
        darkTheme: _theme(dark),
        themeMode: mode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: loaded ? const HomeShell() : const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    });
  }
}
