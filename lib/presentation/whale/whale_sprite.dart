// 鲸鱼娘：la ballenita en pantalla. Imagen del ánimo (rotando cada ~20 s),
// flotando, con bocadillo al tocarla, caricia al mantener pulsado y huevo de
// pascua con 5 toques en 3 s.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/whale/whale_lines.dart';
import '../common/format.dart';
import '../providers.dart';
import 'whale_assets.dart';
import 'whale_controller.dart';
import 'whale_copy.dart';

final whaleAssetsProvider = FutureProvider<WhaleAssets>((ref) => WhaleAssets.load(rootBundle));

const kWhaleBlue = Color(0xFF5B7CFA);

String whaleMoodLabel(BuildContext context, WhaleMood m) {
  final l = context.l10n;
  return switch (m) {
    WhaleMood.normal => l.whaleMoodNormal,
    WhaleMood.celebrate => l.whaleMoodCelebrate,
    WhaleMood.worried => l.whaleMoodWorried,
    WhaleMood.sleep => l.whaleMoodSleep,
  };
}

class WhaleSprite extends ConsumerStatefulWidget {
  const WhaleSprite({
    super.key,
    required this.size,
    this.bubble = true,
    this.bubbleAlignment = Alignment.topCenter,
  });

  final double size;
  final bool bubble;
  final Alignment bubbleAlignment;

  @override
  ConsumerState<WhaleSprite> createState() => _WhaleSpriteState();
}

class _WhaleSpriteState extends ConsumerState<WhaleSprite> with TickerProviderStateMixin {
  final _rnd = Random();
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _bounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final AnimationController _hearts =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  String? _image;
  String? _lastLine;
  String? _bubble;
  Timer? _bubbleTimer;
  Timer? _rotate;
  Timer? _reactionTimer;
  final List<DateTime> _taps = [];

  @override
  void dispose() {
    _float.dispose();
    _bounce.dispose();
    _hearts.dispose();
    _bubbleTimer?.cancel();
    _rotate?.cancel();
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

  List<String> _pool(WhaleView v, WhaleAssets a) =>
      v.reaction != null ? a.forReaction(v.reaction!) : a.forMood(v.mood);

  void _pickImage(WhaleView v, WhaleAssets a) {
    final pool = _pool(v, a);
    if (pool.isEmpty) {
      _image = null;
      return;
    }
    final options = pool.length > 1 ? pool.where((p) => p != _image).toList() : pool;
    _image = options[_rnd.nextInt(options.length)];
  }

  void _restartRotation() {
    _rotate?.cancel();
    _rotate = Timer.periodic(const Duration(seconds: 20), (_) {
      final a = ref.read(whaleAssetsProvider).value;
      final v = ref.read(whaleProvider);
      if (a == null || v.reaction != null || !mounted) return;
      setState(() => _pickImage(v, a));
    });
  }

  void _say(WhaleLineKind kind) {
    if (!widget.bubble) return;
    final v = ref.read(whaleProvider);
    final line = pickLine(whaleCandidates(context.l10n, Fmt.of(context), kind, v.context), _rnd, last: _lastLine);
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
    final ctrl = ref.read(whaleProvider.notifier);
    _haptic();
    if (_animate) _bounce.forward(from: 0);
    if (_taps.length >= 5) {
      _taps.clear();
      ctrl.easter();
      return;
    }
    ctrl.poke();
    final v = ref.read(whaleProvider);
    _say(v.reaction == WhaleReaction.poked ? WhaleLineKind.poked : kindForMood(v.mood, v.context));
  }

  void _onLongPress() {
    _haptic();
    ref.read(whaleProvider.notifier).pet();
    if (_animate) _hearts.forward(from: 0);
    _say(WhaleLineKind.pet);
  }

  /// Cuando llega una reacción: imagen de la reacción y vuelta tras 2–3 s.
  void _onViewChange(WhaleView? prev, WhaleView next) {
    final a = ref.read(whaleAssetsProvider).value;
    final changed = prev == null ||
        prev.mood != next.mood ||
        prev.reactionTick != next.reactionTick ||
        prev.reaction != next.reaction;
    if (a != null && changed) setState(() => _pickImage(next, a));
    if (next.reaction != null && prev?.reactionTick != next.reactionTick) {
      if (next.reaction == WhaleReaction.eat && prev != null) _say(WhaleLineKind.eat);
      _reactionTimer?.cancel();
      final long = next.reaction == WhaleReaction.poked || next.reaction == WhaleReaction.easter;
      _reactionTimer = Timer(Duration(seconds: long ? 3 : 2), () {
        if (mounted) ref.read(whaleProvider.notifier).clearReaction();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = ref.watch(whaleProvider);
    final assets = ref.watch(whaleAssetsProvider).value;
    ref.listen(whaleProvider, _onViewChange);
    ref.listen(whaleAssetsProvider, (_, next) {
      final a = next.value;
      if (a != null) setState(() => _pickImage(ref.read(whaleProvider), a));
    });
    if (_image == null && assets != null) {
      _pickImage(v, assets);
      _restartRotation();
    }
    _syncFloat();
    final s = widget.size;

    final card = Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s * 0.25),
        border: Border.all(color: kWhaleBlue, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: _image == null
          ? const Icon(Icons.water, color: kWhaleBlue)
          : Image.asset(
              _image!,
              key: ValueKey(_image),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const Icon(Icons.water, color: kWhaleBlue),
            ),
    );

    final animated = AnimatedBuilder(
      animation: Listenable.merge([_float, _bounce]),
      builder: (context, child) {
        final f = Curves.easeInOut.transform(_float.value);
        final b = _bounce.isAnimating ? sin(_bounce.value * pi) * 0.15 : 0.0;
        return Transform.translate(
          offset: Offset(0, (f - 0.5) * 8),
          child: Transform.rotate(
            angle: (f - 0.5) * 4 * pi / 180,
            child: Transform.scale(scale: 1 + b, child: child),
          ),
        );
      },
      child: card,
    );

    return Semantics(
      button: true,
      label: l.whaleSemantics(whaleMoodLabel(context, v.mood), v.state.fullness.round()),
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
              AnimatedBuilder(
                animation: _hearts,
                builder: (context, _) {
                  if (!_hearts.isAnimating) return const SizedBox.shrink();
                  final t = _hearts.value;
                  return IgnorePointer(
                    child: Stack(clipBehavior: Clip.none, children: [
                      for (var i = 0; i < 3; i++)
                        Positioned(
                          left: s * (0.2 + 0.3 * i),
                          top: s * 0.1 - t * s * 0.5 - i * 6,
                          child: Opacity(
                            opacity: (1 - t).clamp(0.0, 1.0),
                            child: const Icon(Icons.favorite, color: Color(0xFFF28AAE), size: 18),
                          ),
                        ),
                    ]),
                  );
                },
              ),
              if (_bubble != null)
                Positioned(
                  bottom: s + 6,
                  child: _Bubble(key: const ValueKey('whale-bubble'), text: _bubble!, maxWidth: max(s * 2.2, 180)),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
