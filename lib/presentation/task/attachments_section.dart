// RF-08: adjuntos (fotos de cámara o galería y archivos), copiados a la
// carpeta de la app; miniaturas y pantalla completa.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/entities.dart';
import '../../services/files.dart';
import '../common/format.dart';
import '../providers.dart';
import '../common/ph_icons.dart';

final attachmentsDirProvider = FutureProvider<Directory>((ref) => attachmentsDirectory());

class AttachmentsSection extends ConsumerWidget {
  const AttachmentsSection({super.key, required this.taskId});
  final int taskId;

  Future<void> _add(WidgetRef ref, String sourcePath, String name, AttachmentType type) async {
    final dir = await attachmentsDirectory();
    final ext = p.extension(name);
    final fileName = '${taskId}_${DateTime.now().microsecondsSinceEpoch}$ext';
    final copy = await File(sourcePath).copy(p.join(dir.path, fileName));
    await ref.read(repositoryProvider).insertAttachment(Attachment(
          taskId: taskId,
          path: fileName,
          name: name,
          type: type,
          size: await copy.length(),
        ));
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2400);
    if (x == null) return;
    await _add(ref, x.path, x.name, AttachmentType.image);
  }

  Future<void> _pickFile(WidgetRef ref) async {
    final files = await FilePicker.pickFiles();
    for (final f in files) {
      if (f.path == null) continue;
      const imageExt = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'};
      final type = imageExt.contains(p.extension(f.name).toLowerCase()) ? AttachmentType.image : AttachmentType.file;
      await _add(ref, f.path!, f.name, type);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final items = ref.watch(snapshotProvider).attachmentsOf(taskId);
    final dir = ref.watch(attachmentsDirProvider).value;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.paperclip, size: 20),
              const SizedBox(width: 8),
              Text(l.attachments, style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                tooltip: l.addPhoto,
                icon: const Icon(PhosphorIconsRegular.camera),
                onPressed: () => _pickImage(ref, ImageSource.camera),
              ),
              IconButton(
                tooltip: l.addFromGallery,
                icon: const Icon(PhosphorIconsRegular.images),
                onPressed: () => _pickImage(ref, ImageSource.gallery),
              ),
              IconButton(
                tooltip: l.addFile,
                icon: const Icon(PhosphorIconsRegular.fileArrowUp),
                onPressed: () => _pickFile(ref),
              ),
            ],
          ),
          if (items.isNotEmpty && dir != null)
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final a = items[i];
                  final file = File(p.join(dir.path, a.path));
                  return GestureDetector(
                    onTap: () {
                      if (a.type == AttachmentType.image) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _ImageViewer(file: file, title: a.name),
                        ));
                      } else {
                        OpenFilex.open(file.path);
                      }
                    },
                    onLongPress: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          content: Text('${l.delete} «${a.name}»?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      await ref.read(repositoryProvider).deleteAttachment(a.id!);
                      if (file.existsSync()) await file.delete();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: a.type == AttachmentType.image && file.existsSync()
                          ? Image.file(file, width: 84, height: 84, fit: BoxFit.cover, cacheWidth: 200)
                          : Container(
                              width: 84,
                              height: 84,
                              color: theme.colorScheme.surfaceContainerHighest,
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(PhosphorIconsRegular.file),
                                  Text(a.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center, style: theme.textTheme.labelSmall),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.file, required this.title});
  final File file;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(title)),
        body: Center(child: InteractiveViewer(maxScale: 5, child: Image.file(file))),
      );
}
