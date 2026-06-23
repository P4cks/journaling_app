import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';

/// One Pro section the streak reward can unlock. Label / icon /
/// description are inlined here (rather than derived) so the copy matches
/// `add_section_sheet`'s `_SectionTile` — keep the two in sync if either
/// changes.
class _RewardSection {
  const _RewardSection({
    required this.kind,
    required this.icon,
    required this.label,
    required this.description,
  });

  final SectionKind kind;
  final HugeIconData icon;
  final String label;
  final String description;
}

const _rewardSections = <_RewardSection>[
  _RewardSection(
    kind: SectionKind.featureBlock,
    icon: HugeIcons.strokeRoundedKeyframe,
    label: 'Feature block',
    description: 'A large 2×2 single block — photo or memory.',
  ),
  _RewardSection(
    kind: SectionKind.blockTextBody,
    icon: HugeIcons.strokeRoundedImage01,
    label: 'Block + text',
    description: 'A photo or memory floated left with text wrapping around it.',
  ),
  _RewardSection(
    kind: SectionKind.wannado,
    icon: HugeIcons.strokeRoundedSparkles,
    label: 'Wanna-dos',
    description:
        'A rotating carousel of your wanna-dos. Manage the list in '
        'Block settings.',
  ),
];

/// Bottom sheet that spends the streak-reward token. Lists the still-
/// locked Pro blocks and Pro sections; tapping one permanently unlocks it
/// via [StreakRewardSettings.claimBlock] / [StreakRewardSettings.claimSection]
/// and pops. The claim methods guard against a second spend, so even if
/// the sheet is somehow open twice only the first tap takes effect.
Future<void> showClaimRewardSheet(
  BuildContext context, {
  required StreakRewardSettings rewards,
}) {
  final lockedBlocks = kProOnlyBlockTypes
      .where((t) => !rewards.isBlockUnlocked(t))
      .toList(growable: false);

  return showDraggableSheet<void>(
    context,
    title: 'Pick your reward',
    slivers: (sheetContext, controller) => [
      SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Choose one block or section to unlock for free. This is '
              'a one-time reward.',
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final type in lockedBlocks)
            _ClaimTile(
              icon: type.icon,
              label: type.label,
              description: type.description,
              onTap: () async {
                await rewards.claimBlock(type);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
          for (final section in _rewardSections)
            if (!rewards.isSectionUnlocked(section.kind))
              _ClaimTile(
                icon: section.icon,
                label: section.label,
                description: section.description,
                onTap: () async {
                  await rewards.claimSection(section.kind);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
          const SizedBox(height: 8),
        ]),
      ),
    ],
  );
}

class _ClaimTile extends StatelessWidget {
  const _ClaimTile({
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
      title: Text(label),
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
