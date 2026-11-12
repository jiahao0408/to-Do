// B：pecera pequeña en el menú lateral. Tocarla abre la página de la pecera.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/whale/whale_lines.dart';
import '../common/format.dart';
import '../providers.dart';
import 'whale_controller.dart';
import 'whale_copy.dart';
import 'whale_sprite.dart';
import 'whale_tank_screen.dart';

class WhaleDrawerCard extends ConsumerWidget {
  const WhaleDrawerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    if (!s.whaleEnabled || !s.whaleDrawer) return const SizedBox.shrink();
    final l = context.l10n;
    final v = ref.watch(whaleProvider);
    // Frase estable mientras no cambie el ánimo ni haya interacción.
    final line = pickLine(
      whaleCandidates(l, Fmt.of(context), kindForMood(v.mood, v.context), v.context),
      Random(v.reactionTick * 7 + v.mood.index),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: const Color(0xFFDDEBFF),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: s.whaleTank
              ? () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(MaterialPageRoute(builder: (_) => const WhaleTankScreen()));
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const WhaleSprite(size: 64, bubble: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.whaleTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B2559))),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: v.state.fullness / 100,
                          minHeight: 6,
                          color: kWhaleBlue,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(l.whaleFullness(v.state.fullness.round()),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF3E5BD9))),
                      const SizedBox(height: 4),
                      Text(line,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1B2559))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
