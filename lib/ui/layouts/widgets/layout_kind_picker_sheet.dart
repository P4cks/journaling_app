import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Modal bottom sheet that lets the user pick a [LayoutKind] when
/// creating a new layout. Returns the chosen kind, or `null` if
/// dismissed.
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
            icon: PhosphorIconsDuotone.squaresFour,
            label: 'Only blocks',
            description:
                'A single grid of 1×1 blocks. Add, remove, and reorder them freely.',
            onTap: () => Navigator.of(sheetContext).pop(LayoutKind.blockOnly),
          ),
          _KindTile(
            icon: PhosphorIconsDuotone.layout,
            label: '4 blocks + text',
            description:
                'A 2×2 block grid above a text section. Pick the four block types — structure is locked.',
            onTap: () =>
                Navigator.of(sheetContext).pop(LayoutKind.fixedFourPlusText),
          ),
          _KindTile(
            icon: PhosphorIconsDuotone.stackPlus,
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

  final IconData icon;
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
