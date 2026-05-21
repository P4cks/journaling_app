import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:journaling_app_rewrite/data/model/block_content/photo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Fires the photo block's primary action — opens the Add / Manage
/// sheet without mounting any widget. Called from `MainJournalScreen`
/// when the user double-taps a photo tile and the "expand on edit"
/// setting is OFF (action blocks fire immediately, per the
/// `BlockTypeDisplay.isActionBlock` contract). Reused by the in-grid
/// widget's own taps to keep the picker logic single-sourced.
Future<void> firePhotoBlockAction(
  BuildContext context,
  JournalBlockData data,
  ValueChanged<JournalBlockData> onChanged,
) async {
  final content = PhotoBlockContent.fromMap(data.content);
  final storage = AppDependencies.of(context).photoStorage;
  final picker = ImagePicker();

  Future<void> emit(String? newPath, {String? previousPath}) async {
    if (previousPath != null && previousPath != newPath) {
      storage.deleteAtPath(previousPath);
    }
    onChanged(
      data.copyWith(
        content: PhotoBlockContent(photoPath: newPath).toMap(),
      ),
    );
  }

  Future<void> pick(ImageSource source, {String? previousPath}) async {
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (picked == null || !context.mounted) return;
    final stored = await storage.savePickedFile(picked);
    if (!context.mounted) return;
    await emit(stored, previousPath: previousPath);
  }

  if (!content.hasPhoto) {
    final source = await _showPhotoSourceSheet(context);
    if (source != null && context.mounted) {
      await pick(source);
    }
    return;
  }

  final manage = await _showPhotoManageSheet(context);
  if (!context.mounted) return;
  final currentPath = content.photoPath!;
  switch (manage) {
    case 'replace':
      final source = await _showPhotoSourceSheet(context);
      if (source != null && context.mounted) {
        await pick(source, previousPath: currentPath);
      }
      break;
    case 'remove':
      await emit(null, previousPath: currentPath);
      break;
  }
}

Future<ImageSource?> _showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedCamera01),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedImage01),
              title: const Text('Choose from library'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
}

Future<String?> _showPhotoManageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AppIcon(HugeIcons.strokeRoundedExchange01),
              title: const Text('Replace'),
              onTap: () => Navigator.of(sheetContext).pop('replace'),
            ),
            ListTile(
              leading: AppIcon(
                HugeIcons.strokeRoundedDelete02,
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
}

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
      // Centered "+ Add photo" affordance. Single-tap is suppressed
      // by the grid's gesture model — the host fires
      // `firePhotoBlockAction` directly when the user double-taps the
      // tile (setting OFF) or when the user taps inside the expanded
      // route (setting ON).
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              HugeIcons.strokeRoundedPlusSign,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(child: image),
    );
  }
}
