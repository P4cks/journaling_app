import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Modal bottom sheet that lets the user pick a [LayoutKind] when
/// creating a new layout. Returns the chosen kind, or `null` if
/// dismissed.
///
/// Only [LayoutKind.blockOnly] and [LayoutKind.custom] are offered.
/// `fixedFourPlusText` was retired from the picker (GUS-31) — the enum
/// value is kept (append-only) so any pre-existing layout of that kind
/// still opens, but new ones can no longer be created.
///
/// Both offered kinds are free to pick — monetization moved off the
/// layout *kind* onto block/section selection (GUS-19), so the `custom`
/// kind is no longer Pro-gated here. (Free `blockOnly` layouts are still
/// capped at [kFreeMaxBlocksPerLayout] blocks, and the add-block /
/// add-section sheets gate individual Pro blocks/sections.)
Future<LayoutKind?> showLayoutKindPickerSheet(BuildContext context) {
  return showModalBottomSheet<LayoutKind>(
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
                'New layout — pick a kind',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
          ),
          _KindTile(
            icon: HugeIcons.strokeRoundedGrid,
            label: 'Only blocks',
            description:
                'A single grid of 1×1 blocks. Add, remove, and reorder them freely.',
            onTap: () => Navigator.of(sheetContext).pop(LayoutKind.blockOnly),
          ),
          _KindTile(
            icon: HugeIcons.strokeRoundedAddCircle,
            label: 'Fully customizable',
            description:
                'Add as many sections as you like — text or block-grid (1–4 rows).',
            onTap: () => Navigator.of(sheetContext).pop(LayoutKind.custom),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final HugeIconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: AppIcon(icon),
      title: Text(label, style: theme.textTheme.titleSmall),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}
