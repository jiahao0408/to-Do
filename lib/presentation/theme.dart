// Tema de la app (v2): flex_color_scheme con superficies tintadas suaves del
// color de acento, fuente Inter y transiciones Material del paquete animations.

import 'package:animations/animations.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

const kFontFamily = 'Inter';

/// Chino y demás: la fuente del sistema.
const _fallback = ['Noto Sans SC', 'PingFang SC', 'sans-serif'];

const _sub = FlexSubThemesData(
  blendOnLevel: 10,
  blendOnColors: true,
  useM2StyleDividerInM3: true,
  defaultRadius: 14,
  cardRadius: 18,
  dialogRadius: 24,
  bottomSheetRadius: 28,
  chipRadius: 10,
  fabRadius: 18,
  fabUseShape: true,
  inputDecoratorRadius: 14,
  inputDecoratorBorderType: FlexInputBorderType.outline,
  inputDecoratorUnfocusedHasBorder: true,
  inputDecoratorIsFilled: true,
  segmentedButtonRadius: 12,
  navigationBarIndicatorRadius: 16,
  drawerRadius: 24,
  alignedDropdown: true,
);

const _transitions = PageTransitionsTheme(builders: {
  TargetPlatform.android: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  TargetPlatform.windows: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
  TargetPlatform.linux: SharedAxisPageTransitionsBuilder(transitionType: SharedAxisTransitionType.horizontal),
});

TextTheme _tighter(TextTheme t) => t.copyWith(
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

ThemeData appTheme(ColorScheme scheme) {
  final base = scheme.brightness == Brightness.light
      ? FlexThemeData.light(
          colorScheme: scheme,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 8,
          subThemesData: _sub,
          visualDensity: VisualDensity.standard,
          fontFamily: kFontFamily,
          fontFamilyFallback: _fallback,
          pageTransitionsTheme: _transitions,
        )
      : FlexThemeData.dark(
          colorScheme: scheme,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 14,
          subThemesData: _sub,
          visualDensity: VisualDensity.standard,
          fontFamily: kFontFamily,
          fontFamilyFallback: _fallback,
          pageTransitionsTheme: _transitions,
        );
  return base.copyWith(textTheme: _tighter(base.textTheme));
}
