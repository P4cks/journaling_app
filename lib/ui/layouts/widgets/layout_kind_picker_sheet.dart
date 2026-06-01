import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';

/// Modal bottom sheet that lets the user pick a [LayoutKind] when
/// creating a new layout. Returns the chosen kind, or `null` if
/// dismissed.
///
/// Free users may pick `blockOnly` and `fixedFourPlusText`; the
/// `custom` kind is Pro-only (BACKLOG #96). When a free user taps the
/// locked `custom` tile, the paywall is presented in place; on a
/// successful purchase the sheet pops with `LayoutKind.custom`.
Future<LayoutKind?> showLayoutKindPickerSheet(
  BuildContext context, {
  required SubscriptionRepository subscriptions,
}) {
  final isPro = subscriptions.isPro;
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
            icon: HugeIcons.strokeRoundedLayout01,
            label: '4 blocks + text',
            description:
                'A 2×2 block grid above a text section. Pick the four block types — structure is locked.',
            onTap: () =>
                Navigator.of(sheetContext).pop(LayoutKind.fixedFourPlusText),
          ),
          _KindTile(
            icon: HugeIcons.strokeRoundedAddCircle,
            label: 'Fully customizable',
            description:
                'Add as many sections as you like — text or block-grid (1–4 rows).',
            locked: !isPro,
            onTap: () async {
              if (isPro) {
                Navigator.of(sheetContext).pop(LayoutKind.custom);
                return;
              }
              final ok = await requirePro(
                subscriptions,
                context: sheetContext,
              );
              if (ok && sheetContext.mounted) {
                Navigator.of(sheetContext).pop(LayoutKind.custom);
              }
            },
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
    this.locked = false,
  });

  final HugeIconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = locked ? theme.disabledColor : null;
    return ListTile(
      leading: AppIcon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(color: color),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: locked ? theme.disabledColor : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: locked ? const ProLockBadge() : null,
      onTap: onTap,
    );
  }
}
