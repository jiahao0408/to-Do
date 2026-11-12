// El habitante en una tarjeta: dibujado en código según su ánimo, flotando,
// con bocadillo al tocarlo, saludo al mantener pulsado y sorpresa con 5
// toques en 3 s.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/villager/villager_lines.dart';
import '../../domain/villager/villager_mood.dart';
import '../common/format.dart';
import '../providers.dart';
import 'villager_controller.dart';
import 'villager_copy.dart';
import 'villager_painter.dart';

export 'villager_painter.dart' show kVillagerBlue;

String villagerMoodLabel(BuildContext context, VillagerMood m) {
  final l = context.l10n;
  return switch (m) {
    VillagerMood.normal => l.villagerMoodNormal,
    VillagerMood.celebrate => l.villagerMoodCelebrate,
    VillagerMood.worried => l.villagerMoodWorried,
    VillagerMood.sleep => l.villagerMoodSleep,
  };
}

class VillagerSprite extends ConsumerStatefulWidget {
  const VillagerSprite({
    super.key,
    required this.size,
    this.bubble = true,
    this.bubbleAlignment = Alignment.topCenter,
  });

  final double size;
  final bool bubble;
  final Alignment bubbleAlignment;

  @override
  ConsumerState<VillagerSprite> createState() => _VillagerSpriteState();
}

class _VillagerSpriteState extends ConsumerState<VillagerSprite> with TickerProviderStateMixin {
  final _rnd = Random();
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _bounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  String? _lastLine;
  String? _bubble;
  Timer? _bubbleTimer;
  Timer? _reactionTimer;
  final List<DateTime> _taps = [];

  @override
  void dispose() {
    _float.dispose();
    _bounce.dispose();
    _bubbleTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }

  bool get _animate =>
      ref.read(settingsProvider).animations && !MediaQuery.disableAnimationsOf(context);

  void _syncFloat() {
    if (_animate) {
      if (!_float.isAnimating) _float.repeat(reverse: true);
    } else if (_float.isAnimating) {
      _float.stop();
    }
  }

  void _say(VillagerLineKind kind) {
    if (!widget.bubble) return;
    final v = ref.read(villagerProvider);
    final line = pickLine(villagerCandidates(context.l10n, Fmt.of(context), kind, v.context), _rnd, last: _lastLine);
    _lastLine = line;
    _bubbleTimer?.cancel();
    setState(() => _bubble = line);
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _haptic() {
    if (ref.read(settingsProvider).haptics) HapticFeedback.lightImpact();
  }

  void _onTap() {
    final now = DateTime.now();
    _taps
      ..add(now)
      ..removeWhere((t) => now.difference(t) > const Duration(seconds: 3));
    final ctrl = ref.read(villagerProvider.notifier);
    _haptic();
    if (_animate) _bounce.forward(from: 0);
    if (_taps.length >= 5) {
      _taps.clear();
      ctrl.easter();
      return;
    }
    ctrl.poke();
    final v = ref.read(villagerProvider);
    _say(v.reaction == VillagerReaction.poked ? VillagerLineKind.poked : kindForMood(v.mood, v.context));
  }

  void _onLongPress() {
    _haptic();
    ref.read(villagerProvider.notifier).pet();
    _say(VillagerLineKind.pet);
  }

  /// Cuando llega una reacción: dura 2–3 s y se borra.
  void _onViewChange(VillagerView? prev, VillagerView next) {
    if (next.reaction != null && prev?.reactionTick != next.reactionTick) {
      if (next.reaction == VillagerReaction.eat && prev != null) _say(VillagerLineKind.eat);
      _reactionTimer?.cancel();
      final long = next.reaction == VillagerReaction.poked || next.reaction == VillagerReaction.easter;
      _reactionTimer = Timer(Duration(seconds: long ? 3 : 2), () {
        if (mounted) ref.read(villagerProvider.notifier).clearReaction();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = ref.watch(villagerProvider);
    ref.listen(villagerProvider, _onViewChange);
    _syncFloat();
    final s = widget.size;

    final animated = AnimatedBuilder(
      animation: Listenable.merge([_float, _bounce]),
      builder: (context, _) {
        final f = Curves.easeInOut.transform(_float.value);
        final b = _bounce.isAnimating ? sin(_bounce.value * pi) * 0.15 : 0.0;
        return Transform.translate(
          offset: Offset(0, (f - 0.5) * 6),
          child: Transform.scale(
            scale: 1 + b,
            child: Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                color: v.mood == VillagerMood.sleep ? const Color(0xFFE6E9F5) : Colors.white,
                borderRadius: BorderRadius.circular(s * 0.25),
                border: Border.all(color: kVillagerBlue, width: 2),
              ),
              child: CustomPaint(
                painter: _PortraitPainter(v.mood, v.reaction, _float.value),
              ),
            ),
          ),
        );
      },
    );

    return Semantics(
      button: true,
      label: l.villagerSemantics(villagerMoodLabel(context, v.mood), v.state.fullness.round()),
      onTap: _onTap,
      onLongPress: _onLongPress,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _onTap,
        onLongPress: _onLongPress,
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              animated,
              if (_bubble != null)
                Positioned(
                  bottom: s + 6,
                  // Pegado a un borde: el bocadillo crece hacia dentro de la pantalla.
                  left: widget.bubbleAlignment.x < 0 ? 0 : null,
                  right: widget.bubbleAlignment.x > 0 ? 0 : null,
                  child: _Bubble(key: const ValueKey('villager-bubble'), text: _bubble!, maxWidth: max(s * 2.2, 180)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.mood, this.reaction, this.t);
  final VillagerMood mood;
  final VillagerReaction? reaction;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.25)));
    paintVillager(canvas, Offset(size.width / 2, size.height * 0.9), size.height * 0.78, mood,
        reaction: reaction, t: t);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter old) => old.mood != mood || old.reaction != reaction || old.t != t;
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text, required this.maxWidth});
  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          color: theme.colorScheme.surface,
          elevation: 3,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ),
        ),
      ),
    );
  }
}
