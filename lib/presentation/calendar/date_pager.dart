// Paginación horizontal entre días/semanas/meses (RF-32), sincronizada con
// el día de referencia del calendario.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class DatePager extends ConsumerStatefulWidget {
  const DatePager({
    super.key,
    required this.dateAt,
    required this.offsetOf,
    required this.builder,
  });

  /// Fecha de la página [offset] respecto a [base].
  final DateTime Function(DateTime base, int offset) dateAt;

  /// Página en la que cae [target] respecto a [base].
  final int Function(DateTime base, DateTime target) offsetOf;
  final Widget Function(BuildContext context, DateTime date) builder;

  @override
  ConsumerState<DatePager> createState() => _DatePagerState();
}

class _DatePagerState extends ConsumerState<DatePager> {
  static const _center = 10000;
  late DateTime _base;
  late final PageController _controller;
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    _base = ref.read(calendarProvider).anchor;
    _controller = PageController(initialPage: _center);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(calendarProvider.select((s) => s.anchor), (_, anchor) {
      if (!_controller.hasClients) return;
      final page = _center + widget.offsetOf(_base, anchor);
      final current = _controller.page?.round() ?? _center;
      if (page != current) {
        _programmatic = true;
        final far = (page - current).abs() > 2;
        if (far) {
          _controller.jumpToPage(page);
          _programmatic = false;
        } else {
          _controller
              .animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut)
              .whenComplete(() => _programmatic = false);
        }
      }
    });
    return PageView.builder(
      controller: _controller,
      onPageChanged: (page) {
        if (_programmatic) return;
        final date = widget.dateAt(_base, page - _center);
        final anchor = ref.read(calendarProvider).anchor;
        if (widget.offsetOf(_base, anchor) != page - _center) {
          ref.read(calendarProvider.notifier).goTo(date);
        }
      },
      itemBuilder: (context, page) => widget.builder(context, widget.dateAt(_base, page - _center)),
    );
  }
}
