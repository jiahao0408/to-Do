import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/db/open.dart';
import 'data/repository.dart';
import 'domain/settings.dart';
import 'l10n/app_localizations.dart';
import 'presentation/app.dart';
import 'presentation/providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureTimeZones();
  await initializeDateFormatting();

  var tzName = 'UTC';
  try {
    tzName = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {}

  final db = openAppDatabase();
  final repo = Repository(db);
  await seedIfNeeded(repo);
  final localeCode = AppSettings({
    AppSettings.kLocale: await repo.getSetting(AppSettings.kLocale) ?? '',
  }).localeCode;
  await NotificationService.instance.init(localeCode: localeCode);

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      timeZoneProvider.overrideWithValue(tzName),
    ],
    child: const App(),
  ));
}

/// RF-58: categorías iniciales Uni, Trabajo y Personal (editables).
Future<void> seedIfNeeded(Repository repo) async {
  if (await repo.getSetting(AppSettings.kSeeded) == '1') return;
  final lang = PlatformDispatcher.instance.locale.languageCode;
  final l = lookupAppLocalizations(Locale(['es', 'en', 'zh'].contains(lang) ? lang : 'es'));
  await repo.insertCategory(l.catUni, 0xFF3F51B5);
  await repo.insertCategory(l.catWork, 0xFFFF9800);
  await repo.insertCategory(l.catPersonal, 0xFF4CAF50);
  await repo.setSetting(AppSettings.kSeeded, '1');
}
