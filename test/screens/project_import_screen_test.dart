// Pantalla de importar proyecto: vista previa en vivo y crear.
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:todo_calendar/data/db/database.dart';
import 'package:todo_calendar/data/repository.dart';
import 'package:todo_calendar/domain/time.dart';
import 'package:todo_calendar/l10n/app_localizations.dart';
import 'package:todo_calendar/presentation/providers.dart';
import 'package:todo_calendar/presentation/screens/project_import_screen.dart';
import 'package:todo_calendar/presentation/screens/projects_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(() => initializeDateFormatting());

  testWidgets('pegar texto, ver la vista previa y crear el proyecto', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final clock = FixedClock(DateTime(2026, 11, 13, 10));
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ProjectImportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no hay módulos'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('import-text')), '# Mudanza\n## Empaquetar\n- Cajas\n- Cinta\n## Transporte');
    await tester.pump();
    expect(find.text('2 módulos · 2 subtareas'), findsOneWidget);
    expect(find.text('Empaquetar'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('import-title'))).controller!.text, 'Mudanza');

    await tester.tap(find.text('Crear proyecto'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectScreen), findsOneWidget);

    final snap = await tester.runAsync(() => Repository(db, clock: clock).loadSnapshot());
    expect(snap!.projects.single.name, 'Mudanza');
    expect(snap.tasks.map((t) => t.title).toSet(), {'Empaquetar', 'Transporte'});
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => db.close());
  });

  testWidgets('copiar prompt deja el texto en el portapapeles', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ProjectImportScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar prompt para la IA'));
    await tester.pump();
    expect(copied, contains('# Título del proyecto'));
    expect(copied, contains('## Módulo 1'));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => db.close());
  });
}
