import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Modal bottom sheet that picks a new section type — text or
/// block-grid. Returns the picked [SectionKind] or `null` on dismiss.
/// Block-grid sections start empty; the user adds blocks afterwards
/// and the grid grows to fit.
Future<SectionKind?> showAddSectionSheet(BuildContext context) {
  return showModalBottomSheet<SectionKind>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add a section',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: AppIcon(HugeIcons.strokeRoundedTextFont),
            title: const Text('Text section'),
            subtitle: const Text('A full-width multi-line text area.'),
            onTap: () => Navigator.of(sheetContext).pop(SectionKind.text),
          ),
          ListTile(
            leading: AppIcon(HugeIcons.strokeRoundedGrid),
            title: const Text('Block grid'),
            subtitle: const Text(
              'A 2-column grid of 1×1 blocks. Add blocks to grow it.',
            ),
            onTap: () => Navigator.of(sheetContext).pop(SectionKind.blockGrid),
          ),
          ListTile(
            leading: AppIcon(HugeIcons.strokeRoundedKeyframe),
            title: const Text('Feature block'),
            subtitle: const Text('A large 2×2 single block — photo or memory.'),
            onTap: () =>
                Navigator.of(sheetContext).pop(SectionKind.featureBlock),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
