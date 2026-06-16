import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';

/// Result of [showAddSectionSheet]: the chosen [SectionKind] plus an
/// optional [definitionId] (only set for [SectionKind.wannado], pointing
/// at the chosen `WannadoDefinition`).
class AddSectionResult {
  const AddSectionResult(this.kind, {this.definitionId});

  final SectionKind kind;
  final String? definitionId;
}

/// Modal bottom sheet that picks a new section type — text, block-grid,
/// header, divider, feature block, block+text, or wanna-do carousel.
/// Returns the picked [AddSectionResult] or `null` on dismiss.
/// Block-grid sections start empty; the user adds blocks afterwards and
/// the grid grows to fit.
///
/// Free users may add the section kinds in [kFreeSectionKinds] (text +
/// block-grid + header + divider). `featureBlock` (GUS-19),
/// `blockTextBody` (GUS-9) and `wannado` (GUS-8/GUS-42/GUS-45) are
/// Pro-only: for free users those tiles render greyed with a
/// [ProLockBadge] and tapping presents the paywall, proceeding only on a
/// successful purchase (or if the kind was unlocked via a streak reward).
///
/// Picking the wanna-do carousel tile opens a sub-picker of the user's
/// `WannadoDefinition`s (managed in Block settings) — the chosen
/// definition's id rides back on [AddSectionResult.definitionId].
Future<AddSectionResult?> showAddSectionSheet(
  BuildContext context, {
  required SubscriptionRepository subscriptions,
  required StreakRewardSettings rewards,
  required BlockSettings settings,
}) {
  final isPro = subscriptions.isPro;
  final featureLocked =
      !isPro &&
      !kFreeSectionKinds.contains(SectionKind.featureBlock) &&
      !rewards.isSectionUnlocked(SectionKind.featureBlock);
  final blockTextLocked =
      !isPro &&
      !kFreeSectionKinds.contains(SectionKind.blockTextBody) &&
      !rewards.isSectionUnlocked(SectionKind.blockTextBody);
  final wannadoLocked =
      !isPro &&
      !kFreeSectionKinds.contains(SectionKind.wannado) &&
      !rewards.isSectionUnlocked(SectionKind.wannado);

  return showDraggableSheet<AddSectionResult>(
    context,
    title: "Add a Section",
    slivers: (sheetContext, controller) => [
      SliverList(
        delegate: SliverChildListDelegate([
          _SectionTile(
            icon: HugeIcons.strokeRoundedTextFont,
            label: 'Text section',
            description: 'A full-width multi-line text area.',
            onTap: () => Navigator.of(
              sheetContext,
            ).pop(const AddSectionResult(SectionKind.text)),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedGrid,
            label: 'Block grid',
            description:
                'A 2-column grid of 1×1 blocks. Add blocks to grow it.',
            onTap: () => Navigator.of(
              sheetContext,
            ).pop(const AddSectionResult(SectionKind.blockGrid)),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedHeading,
            label: 'Header',
            description: 'A single-line heading to break up the page.',
            onTap: () => Navigator.of(
              sheetContext,
            ).pop(const AddSectionResult(SectionKind.header)),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedRemove01,
            label: 'Divider',
            description: 'A horizontal rule between sections.',
            onTap: () => Navigator.of(
              sheetContext,
            ).pop(const AddSectionResult(SectionKind.divider)),
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedKeyframe,
            label: 'Feature block',
            description: 'A large 2×2 single block — photo or memory.',
            locked: featureLocked,
            onTap: () async {
              if (!featureLocked) {
                Navigator.of(
                  sheetContext,
                ).pop(const AddSectionResult(SectionKind.featureBlock));
                return;
              }
              final ok = await requirePro(subscriptions, context: sheetContext);
              if (ok && sheetContext.mounted) {
                Navigator.of(
                  sheetContext,
                ).pop(const AddSectionResult(SectionKind.featureBlock));
              }
            },
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedImage01,
            label: 'Block + text',
            description:
                'A photo or memory floated left with text wrapping around it.',
            locked: blockTextLocked,
            onTap: () async {
              if (!blockTextLocked) {
                Navigator.of(
                  sheetContext,
                ).pop(const AddSectionResult(SectionKind.blockTextBody));
                return;
              }
              final ok = await requirePro(subscriptions, context: sheetContext);
              if (ok && sheetContext.mounted) {
                Navigator.of(
                  sheetContext,
                ).pop(const AddSectionResult(SectionKind.blockTextBody));
              }
            },
          ),
          _SectionTile(
            icon: HugeIcons.strokeRoundedSparkles,
            label: 'Wanna-do carousel',
            description:
                'A rotating carousel of one of your wanna-do lists. '
                'Create lists in Block settings.',
            locked: wannadoLocked,
            onTap: () async {
              if (wannadoLocked) {
                final ok = await requirePro(
                  subscriptions,
                  context: sheetContext,
                );
                if (!ok || !sheetContext.mounted) return;
              }
              await _pickWannadoDefinition(
                sheetContext,
                settings: settings,
                subscriptions: subscriptions,
              );
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    ],
  );
}

/// Sub-picker shown after the wanna-do carousel tile is unlocked. Lists
/// the user's `WannadoDefinition`s; choosing one pops the *outer*
/// add-section sheet with an [AddSectionResult] carrying its id. A
/// capped "Add wanna-do carousel" button (mirroring the custom-block
/// flow) pops the sheets and pushes the editor so the user can create a
/// new definition, then re-open the picker to attach it.
Future<void> _pickWannadoDefinition(
  BuildContext sheetContext, {
  required BlockSettings settings,
  required SubscriptionRepository subscriptions,
}) async {
  // Capture the navigator/router of the outer add-section sheet before the
  // nested sheet shadows the context — "Create new" pops both sheets and
  // pushes onto the layout-editor screen behind them.
  final sectionSheetNavigator = Navigator.of(sheetContext);
  final router = GoRouter.of(sheetContext);

  await showModalBottomSheet<void>(
    context: sheetContext,
    isScrollControlled: true,
    builder: (pickerContext) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            final theme = Theme.of(context);
            final defs = settings.wannadoDefinitions;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Pick a wanna-do list',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (defs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      "You haven't created any wanna-do lists yet. Create "
                      'one, then add it as a section.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  for (final def in defs)
                    ListTile(
                      leading: AppIcon(HugeIcons.strokeRoundedSparkles),
                      title: Text(def.title.isEmpty ? 'Untitled' : def.title),
                      subtitle: Text(
                        '${def.items.length} '
                        'item${def.items.length == 1 ? '' : 's'}',
                      ),
                      onTap: () {
                        // Close the picker, then pop the outer sheet with
                        // the chosen definition.
                        Navigator.of(pickerContext).pop();
                        sectionSheetNavigator.pop(
                          AddSectionResult(
                            SectionKind.wannado,
                            definitionId: def.id,
                          ),
                        );
                      },
                    ),
                ProLimitHint(
                  used: defs.length,
                  max: kFreeMaxWannados,
                  noun: 'wanna-do carousels',
                  subscriptions: subscriptions,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AddCustomBlockButton(
                      subscriptions: subscriptions,
                      currentCount: defs.length,
                      max: kFreeMaxWannados,
                      label: 'Add wanna-do carousel',
                      onAddAllowed: () {
                        // Dismiss both sheets, then push the editor onto
                        // the layout-editor screen.
                        Navigator.of(pickerContext).pop();
                        sectionSheetNavigator.pop();
                        router.push(Routes.newWannado);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
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
