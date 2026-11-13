// Habitante: sprite, esquina del calendario, carrusel del menú y aldea.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:todo_calendar/domain/models/entities.dart';
import 'package:todo_calendar/domain/settings.dart';
import 'package:todo_calendar/domain/snapshot.dart';
import 'package:todo_calendar/domain/village/layout.dart';
import 'package:todo_calendar/domain/villager/villager_mood.dart';
import 'package:todo_calendar/domain/villager/villager_lines.dart';
import 'package:todo_calendar/domain/villager/villager_state.dart';
import 'package:todo_calendar/l10n/app_localizations.dart';
import 'package:todo_calendar/presentation/providers.dart';
import 'package:todo_calendar/presentation/village/villager_controller.dart';
import 'package:todo_calendar/presentation/village/menu_carousel.dart';
import 'package:todo_calendar/presentation/village/villager_floating.dart';
import 'package:todo_calendar/presentation/village/villager_sprite.dart';
import 'package:todo_calendar/presentation/village/village_screen.dart';

class FakeVillager extends VillagerController {
  FakeVillager(this.initial);
  final VillagerView initial;
  final calls = <String>[];

  @override
  VillagerView build() => initial;
  @override
  void pet() {
    calls.add('pet');
    super.pet();
  }

  @override
  void poke() {
    calls.add('poke');
    super.poke();
  }

  @override
  void easter() {
    calls.add('easter');
    super.easter();
  }

  @override
  void clearReaction() {
    calls.add('clear');
    super.clearReaction();
  }
}

VillagerView view({VillagerMood mood = VillagerMood.normal, double fullness = 70}) => VillagerView(
      state: VillagerState(fullness: fullness, updatedAt: DateTime(2026, 11, 12), baseline: 0),
      mood: mood,
      context: VillagerContext(remainingToday: 2, overdue: 0, fullness: fullness),
      enabled: true,
    );

AppSnapshot emptySnap({List<Project> projects = const []}) => AppSnapshot(
      tasks: const [],
      subtasks: const [],
      categories: const [],
      reminders: const [],
      attachments: const [],
      exceptions: const [],
      completions: const [],
      timeEntries: const [],
      templates: const [],
      settings: const {},
      projects: projects,
    );

Widget host(FakeVillager fake,
        {bool animations = true,
        Widget? child,
        Map<String, String> extra = const {},
        Widget? page,
        List<Project> projects = const []}) =>
    ProviderScope(
      overrides: [
        villagerProvider.overrideWith(() => fake),
        snapshotProvider.overrideWithValue(emptySnap(projects: projects)),
        settingsProvider.overrideWithValue(AppSettings({
          AppSettings.kAnimations: animations ? '1' : '0',
          AppSettings.kHaptics: '0',
          ...extra,
        })),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: page ?? Scaffold(body: Center(child: child ?? const VillagerSprite(size: 120))),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('轻点后出现气泡文字，3 秒后消失', (tester) async {
    final fake = FakeVillager(view());
    await tester.pumpWidget(host(fake, animations: false));
    await tester.pump();
    await tester.tap(find.byType(VillagerSprite));
    await tester.pump();
    expect(fake.calls, contains('poke'));
    expect(find.byKey(const ValueKey('villager-bubble')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('villager-bubble')), findsNothing);
  });

  testWidgets('气泡在左边时从精灵左边缘开始，不会出屏', (tester) async {
    await tester.pumpWidget(host(FakeVillager(view()), animations: false,
        child: const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12, bottom: 12),
            child: VillagerSprite(size: 72, bubbleAlignment: Alignment.topLeft),
          ),
        )));
    await tester.pump();
    await tester.tap(find.byType(VillagerSprite));
    await tester.pump();
    final bubble = tester.getRect(find.byKey(const ValueKey('villager-bubble')));
    final sprite = tester.getRect(find.byType(VillagerSprite));
    expect(bubble.left, closeTo(sprite.left, 0.5));
    expect(bubble.left, greaterThanOrEqualTo(0));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('长按调用 pet', (tester) async {
    final fake = FakeVillager(view());
    await tester.pumpWidget(host(fake, animations: false));
    await tester.pump();
    await tester.longPress(find.byType(VillagerSprite));
    await tester.pump();
    expect(fake.calls, contains('pet'));
    await tester.pump(const Duration(seconds: 3));
    expect(fake.calls, contains('clear'), reason: 'la reacción dura unos 2 s');
  });

  testWidgets('3 秒内连续点 5 下调用 easter', (tester) async {
    final fake = FakeVillager(view());
    await tester.pumpWidget(host(fake, animations: false));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byType(VillagerSprite));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(fake.calls.where((c) => c == 'easter').length, 1);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('关闭动画时，漂浮的 AnimationController 不会运行', (tester) async {
    await tester.pumpWidget(host(FakeVillager(view()), animations: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('打开动画时会持续漂浮', (tester) async {
    await tester.pumpWidget(host(FakeVillager(view()), animations: true));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('语义标签包含饱腹度', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(FakeVillager(view(fullness: 42.4)), animations: false));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('村民.*体力 42%')), findsOneWidget);
    handle.dispose();
  });

  group('三个位置', () {
    Widget floating(Map<String, String> extra, {bool hidden = false}) => SizedBox(
          width: 400,
          height: 700,
          child: Stack(children: [const Positioned.fill(child: ColoredBox(color: Colors.white)), VillagerFloating(hidden: hidden)]),
        );

    testWidgets('habitante apagado: ni esquina ni página del habitante; el carrusel sigue', (tester) async {
      final off = {AppSettings.kVillagerEnabled: '0'};
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: off, child: floating(off)));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsNothing);
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: off, child: const MenuCarousel()));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsNothing);
      expect(find.text('今天'), findsOneWidget);
    });

    testWidgets('carrusel: solo las páginas elegidas y se puede apagar', (tester) async {
      final only = {AppSettings.kMenuCards: 'villager'};
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: only, child: const MenuCarousel()));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsOneWidget);
      expect(find.text('今天'), findsNothing);
      final off = {AppSettings.kVillagerDrawer: '0'};
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: off, child: const MenuCarousel()));
      await tester.pump();
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('carrusel: deslizar pasa de Hoy a Racha', (tester) async {
      await tester.pumpWidget(host(FakeVillager(view()), animations: false,
          child: const SizedBox(width: 320, child: MenuCarousel())));
      await tester.pump();
      expect(find.text('今天'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('连续'), findsOneWidget);
    });

    testWidgets('solo se apaga la esquina: la página del habitante en el carrusel sigue', (tester) async {
      final ex = {AppSettings.kVillagerFloating: '0', AppSettings.kMenuCards: 'villager'};
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: ex, child: floating(ex)));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsNothing);
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: ex, child: const MenuCarousel()));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsOneWidget);
    });

    // Regresión v2.1.2: oculto o apagado dejaba el calendario en blanco
    // (dentro de Column > Expanded > Stack, el Stack medía 0 de ancho).
    for (final (name, hidden, extra) in [
      ('oculto (bandeja abierta)', true, const <String, String>{}),
      ('esquina apagada', false, {AppSettings.kVillagerFloating: '0'}),
      ('habitante apagado', false, {AppSettings.kVillagerEnabled: '0'}),
    ]) {
      testWidgets('$name: el calendario de debajo conserva su tamaño', (tester) async {
        await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: extra,
            child: SizedBox(
              width: 400,
              height: 700,
              child: Column(children: [
                Expanded(
                  child: Stack(children: [
                    const Positioned.fill(child: ColoredBox(key: ValueKey('cal'), color: Colors.white)),
                    VillagerFloating(hidden: hidden),
                  ]),
                ),
              ]),
            )));
        await tester.pump();
        final size = tester.getSize(find.byKey(const ValueKey('cal')));
        expect(size.width, 400, reason: 'antes medía 0 y el calendario desaparecía');
        expect(size.height, greaterThan(500));
      });
    }

    testWidgets('hidden: true 时不显示 VillagerFloating', (tester) async {
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, child: floating(const {}, hidden: true)));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsNothing);
    });

    testWidgets('键盘弹出（viewInsets.bottom = 300）时隐藏', (tester) async {
      await tester.pumpWidget(host(FakeVillager(view()), animations: false,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800), viewInsets: EdgeInsets.only(bottom: 300)),
            child: floating(const {}),
          )));
      await tester.pump();
      expect(find.byType(VillagerSprite), findsNothing);
    });

    testWidgets('默认在左下角', (tester) async {
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, child: floating(const {})));
      await tester.pump();
      final box = tester.getRect(find.byType(VillagerSprite));
      final area = tester.getRect(find.byType(VillagerFloating));
      expect(box.left - area.left, closeTo(12, 0.5));
      expect(area.bottom - box.bottom, closeTo(12, 0.5));
    });

    testWidgets('whale.pos = "right:2.0"（越界）时，夹回可见区域', (tester) async {
      final ex = {AppSettings.kVillagerPos: 'right:2.0'};
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, extra: ex, child: floating(ex)));
      await tester.pump();
      final box = tester.getRect(find.byType(VillagerSprite));
      final area = tester.getRect(find.byType(VillagerFloating));
      expect(box.bottom, lessThanOrEqualTo(area.bottom - 12 + 0.5));
      expect(area.right - box.right, closeTo(12, 0.5));
    });

    testWidgets('aldea vacía: invita a crear un proyecto', (tester) async {
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, page: const VillageScreen()));
      await tester.pump();
      expect(find.textContaining('打下第一块基石'), findsOneWidget);
      expect(find.textContaining('体力 70%'), findsWidgets);
    });

    testWidgets('aldea con proyectos: se dibuja el mapa', (tester) async {
      await tester.pumpWidget(host(FakeVillager(view()), animations: false, page: const VillageScreen(), projects: const [
        Project(id: 1, name: 'TFG', color: 0xFF5B7CFA, building: 'castle'),
        Project(id: 2, name: 'Mudanza', color: 0xFFE57373, archived: true),
      ]));
      await tester.pump();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is VillagePainter), findsOneWidget);
    });

    test('tocar un solar devuelve su proyecto (el de delante si se solapan)', () {
      final layout = VillageLayout.of([1, 2], [3]);
      final geo = VillageGeometry(layout);
      final lots = villageLots(const [
        Project(id: 1, name: 'A', color: 1),
        Project(id: 2, name: 'B', color: 1),
        Project(id: 3, name: 'C', color: 1, archived: true),
      ], (_) => (1, 2), layout);
      for (final v in lots) {
        final front = geo.iso.p(v.lot.x + 0.5, v.lot.y + 0.9);
        expect(geo.hitTest(lots, front)?.project.id, v.project.id);
      }
      expect(geo.hitTest(lots, const Offset(-999, -999)), isNull);
    });
  });
}
