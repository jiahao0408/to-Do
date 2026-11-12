// Secciones en tarjetas: un título y, debajo, sus filas dentro de una Card.
// Uso: ListView(children: groupInCards([SectionHeader('A'), fila, fila, SectionHeader('B'), …]))

import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(text, style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

/// Mete las filas entre cada [SectionHeader] en una tarjeta.
List<Widget> groupInCards(List<Widget> children) {
  final out = <Widget>[];
  var run = <Widget>[];
  void flush() {
    if (run.isEmpty) return;
    out.add(_SectionCard(children: run));
    run = [];
  }

  for (final c in children) {
    if (c is SectionHeader) {
      flush();
      out.add(c);
    } else {
      run.add(c);
    }
  }
  flush();
  return out;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ListTileTheme(
        iconColor: scheme.primary,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
