// RF-52 / RF-53: exportar e importar copia de seguridad.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup_service.dart';
import '../../services/files.dart';
import '../common/actions.dart';
import '../common/format.dart';
import '../providers.dart';

class BackupTiles extends ConsumerWidget {
  const BackupTiles({super.key});

  Future<BackupService> _service(WidgetRef ref) async =>
      BackupService(ref.read(databaseProvider), attachmentsDir: await attachmentsDirectory());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: Text(l.exportBackup),
          subtitle: Text(l.exportBackupHint),
          onTap: () async {
            final ui = Ui.of(context);
            final box = context.findRenderObject() as RenderBox?;
            try {
              final service = await _service(ref);
              final file = await service.exportZip(await getTemporaryDirectory());
              await SharePlus.instance.share(ShareParams(
                files: [XFile(file.path, mimeType: 'application/zip')],
                subject: file.uri.pathSegments.last,
                sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
              ));
              ui.message(l.backupExported);
            } catch (e) {
              ui.message(l.backupError('$e'));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text(l.importBackup),
          subtitle: Text(l.importBackupHint),
          onTap: () async {
            final ui = Ui.of(context);
            final picked = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['zip', 'json'],
            );
            final path = picked.isEmpty ? null : picked.first.path;
            if (path == null || !context.mounted) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                content: Text(l.importConfirm),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.importBackup)),
                ],
              ),
            );
            if (ok != true) return;
            try {
              await (await _service(ref)).importFile(File(path));
              ui.message(l.backupImported);
            } catch (e) {
              ui.message(l.backupError('$e'));
            }
          },
        ),
      ],
    );
  }
}
