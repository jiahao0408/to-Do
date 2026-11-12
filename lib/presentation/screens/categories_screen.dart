// RF-06: crear, renombrar, cambiar color y borrar categorías.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/entities.dart';
import '../common/format.dart';
import '../providers.dart';
import '../common/ph_icons.dart';

const kPalette = <int>[
  0xFF3F51B5, 0xFF2196F3, 0xFF00BCD4, 0xFF009688, 0xFF4CAF50, 0xFF8BC34A,
  0xFFCDDC39, 0xFFFFC107, 0xFFFF9800, 0xFFFF5722, 0xFFF44336, 0xFFE91E63,
  0xFF9C27B0, 0xFF673AB7, 0xFF795548, 0xFF607D8B,
];

Future<int?> pickColor(BuildContext context, int current) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final c in kPalette)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(ctx, c),
              child: CircleAvatar(
                backgroundColor: Color(c),
                radius: 18,
                child: c == current ? const Icon(PhosphorIconsRegular.check, color: Colors.white) : null,
              ),
            ),
        ],
      ),
    ),
  );
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Category? c]) async {
    final l = context.l10n;
    final ctrl = TextEditingController(text: c?.name ?? '');
    var color = c?.color ?? kPalette[(ref.read(snapshotProvider).categories.length * 5) % kPalette.length];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(c == null ? l.newCategory : l.edit),
          content: Row(
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final picked = await pickColor(ctx, color);
                  if (picked != null) setState(() => color = picked);
                },
                child: CircleAvatar(backgroundColor: Color(color), radius: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l.categoryName),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    final name = ctrl.text.trim();
    if (ok != true || name.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    if (c == null) {
      await repo.insertCategory(name, color);
    } else {
      await repo.updateCategory(c.copyWith(name: name, color: color));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cats = ref.watch(snapshotProvider).categories;
    return Scaffold(
      appBar: AppBar(title: Text(l.categories)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref),
        tooltip: l.newCategory,
        child: const Icon(PhosphorIconsRegular.plus),
      ),
      body: ListView(
        children: [
          for (final c in cats)
            ListTile(
              leading: CircleAvatar(backgroundColor: Color(c.color), radius: 12),
              title: Text(c.name),
              onTap: () => _edit(context, ref, c),
              trailing: IconButton(
                icon: const Icon(PhosphorIconsRegular.trash),
                tooltip: l.delete,
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: Text(l.deleteCategoryConfirm(c.name)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                      ],
                    ),
                  );
                  if (ok == true) await ref.read(repositoryProvider).deleteCategory(c.id!);
                },
              ),
            ),
        ],
      ),
    );
  }
}
