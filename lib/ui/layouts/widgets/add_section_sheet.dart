import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';

/// Modal bottom sheet that picks a new section type — text, block-grid,
/// or feature block. Returns the picked [SectionKind] or `null` on
/// dismiss. Block-grid sections start empty; the user adds blocks
/// afterwards and the grid grows to fit.
///
/// Free users may add the section kinds in [kFreeSectionKinds] (text +
/// block-grid). `featureBlock` is Pro-only (GUS-19): for free users its
/// tile renders greyed with a [ProLockBadge] and tapping it presents the
/// paywall, popping `SectionKind.featureBlock` only on a successful
/// purchase.
Future<SectionKind?> showAddSectionSheet(
  BuildContext context, {
  required SubscriptionRepository subscriptions,
}) {
  final isPro = subscriptions.isPro;
  final featureLocked =
      !isPro && !kFreeSectionKinds.contains(SectionKind.featureBlock);
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
          _SectionTile(
            icon: HugeIcons.strokeRoundedTextFont,
            label: 'Text section',
            description: 'A full-width multi-line text area.',
            onTap: () => Navigator.of(sheetContext).pop(SectionKind.text),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedGrid,
            label: 'Block grid',
            description:
                'A 2-column grid of 1×1 blocks. Add blocks to grow it.',
            onTap: () => Navigator.of(sheetContext).pop(SectionKind.blockGrid),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedHeading,
            label: 'Header',
            description: 'A single-line heading to break up the page.',
            onTap: () => Navigator.of(sheetContext).pop(SectionKind.header),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedRemove01,
            label: 'Divider',
            description: 'A horizontal rule between sections.',
            onTap: () => Navigator.of(sheetContext).pop(SectionKind.divider),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedKeyframe,
            label: 'Feature block',
            description: 'A large 2×2 single block — photo or memory.',
            locked: featureLocked,
            onTap: () async {
              if (!featureLocked) {
                Navigator.of(sheetContext).pop(SectionKind.featureBlock);
                return;
              }
              final ok = await requirePro(subscriptions, context: sheetContext);
              if (ok && sheetContext.mounted) {
                Navigator.of(sheetContext).pop(SectionKind.featureBlock);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
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
      title: Text(label, style: TextStyle(color: color)),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: locked
              ? theme.disabledColor
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: locked ? const ProLockBadge() : null,
      onTap: onTap,
    );
  }
}
