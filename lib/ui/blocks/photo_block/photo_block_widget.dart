import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journaling_app_rewrite/data/model/block_content/photo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/services/photo_storage_service.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One image filling the 1×1 cell. Empty state shows a centred "+ Add
/// photo" affordance that opens a Camera / Gallery action sheet. Once
/// set, long-press in editable mode opens a Replace / Remove sheet.
class PhotoBlockWidget extends StatefulWidget {
  const PhotoBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  @override
  State<PhotoBlockWidget> createState() => _PhotoBlockWidgetState();
}

class _PhotoBlockWidgetState extends State<PhotoBlockWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _picking = false;

  PhotoStorageService get _storage => AppDependencies.of(context).photoStorage;

  void _emit(String? newPath, {String? previousPath}) {
    if (previousPath != null && previousPath != newPath) {
      // Best-effort cleanup of the file we're replacing/removing.
      _storage.deleteAtPath(previousPath);
    }
    widget.onChanged?.call(
      widget.data.copyWith(
        content: PhotoBlockContent(photoPath: newPath).toMap(),
      ),
    );
  }

  Future<void> _pick(ImageSource source, {String? previousPath}) async {
    if (_picking) return;
    _picking = true;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      final stored = await _storage.savePickedFile(picked);
      if (!mounted) return;
      _emit(stored, previousPath: previousPath);
    } finally {
      _picking = false;
    }
  }

  Future<void> _showAddSheet({String? previousPath}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(PhosphorIconsDuotone.camera),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const AppIcon(PhosphorIconsDuotone.image),
                title: const Text('Choose from library'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) {
      await _pick(source, previousPath: previousPath);
    }
  }

  Future<void> _showManageSheet(String currentPath) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const AppIcon(PhosphorIconsDuotone.swap),
                title: const Text('Replace'),
                onTap: () => Navigator.of(sheetContext).pop('replace'),
              ),
              ListTile(
                leading: AppIcon(
                  PhosphorIconsDuotone.trash,
                  color: Theme.of(sheetContext).colorScheme.error,
                ),
                title: Text(
                  'Remove',
                  style: TextStyle(
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    switch (action) {
      case 'replace':
        await _showAddSheet(previousPath: currentPath);
        break;
      case 'remove':
        _emit(null, previousPath: currentPath);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = PhotoBlockContent.fromMap(widget.data.content);

    if (!content.hasPhoto) {
      if (widget.mode == BlockMode.readOnly) {
        return Center(
          child: Text(
            'No photo',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.disabledColor,
            ),
          ),
        );
      }
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showAddSheet(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                PhosphorIconsBold.plus,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                'Add photo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final file = File(content.photoPath!);
    final image = Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Center(
        child: Text(
          'Image missing',
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.disabledColor,
          ),
        ),
      ),
    );

    final shaped = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(child: image),
    );

    if (widget.mode == BlockMode.readOnly) return shaped;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showManageSheet(content.photoPath!),
      child: shaped,
    );
  }
}
