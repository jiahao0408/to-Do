// Entradas del menú de la Fase 3 (plantillas, estadísticas, revisión) y
// aviso de la revisión semanal (RF-50).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings.dart';
import '../../domain/time.dart';
import '../common/format.dart';
import '../providers.dart';
import '../screens/weekly_review_screen.dart';

/// RF-50: el día configurado (domingo por defecto) ofrece la revisión.
Future<void> maybeOfferWeeklyReview(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final now = ref.read(clockProvider).now();
  if (now.weekday != settings.reviewWeekday) return;
  if (settings.raw[AppSettings.kLastReviewDate] == formatDateKey(now)) return;
  final l = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(l.reviewReminder),
    duration: const Duration(seconds: 8),
    persist: false,
    action: SnackBarAction(
      label: l.weeklyReview,
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeeklyReviewScreen())),
    ),
  ));
}
