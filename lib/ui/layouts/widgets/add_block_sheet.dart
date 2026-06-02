import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';

/// Block types intentionally hidden from the layout-editor picker.
///
/// `locationBlock` is still WIP. `customCarousel` is excluded from the
/// built-in grid because user-defined carousel "types" surface as their
/// own per-definition tiles in the custom-blocks section below — there's
/// no abstract "Custom carousel" tile that would make sense without an
/// id to attach.
const _hiddenBlockTypes = <BlockType>{
  BlockType.locationBlock,
  BlockType.customCarousel,
};

/// Discriminated return type for [showAddBlockSheet]:
/// - [AddBlockResultBuiltin] — user picked a built-in `BlockType`.
/// - [AddBlockResultCustom] — user picked one of their saved
///   custom-carousel definitions; the layout editor stores
///   `definitionId` on the slot.
sealed class AddBlockResult {
  const AddBlockResult();
}

class AddBlockResultBuiltin extends AddBlockResult {
  const AddBlockResultBuiltin(this.type);
  final BlockType type;
}

class AddBlockResultCustom extends AddBlockResult {
  const AddBlockResultCustom(this.definitionId);
  final String definitionId;
}

/// Half-screen modal sheet that lets the user pick a block to add.
///
/// Top: a 2-column grid of built-in `BlockType`s rendered with their
/// sample preview. Bottom (only when [allowedTypes] is null): a
/// "Custom blocks" section with one tile per
/// `BlockSettings.customCarousels` entry plus an "Add custom block"
/// button that pushes the editor screen — on save the sheet rebuilds
/// via a `ListenableBuilder` on `BlockSettings`, so the new
/// definition appears without a re-open.
///
/// Pass [allowedTypes] to restrict to a subset (e.g.
/// `{photoBlock, memoryBlock}` for feature-block sections). When set,
/// the custom-blocks section is hidden — feature blocks can't be
/// custom carousels.
Future<AddBlockResult?> showAddBlockSheet(
  BuildContext context, {
  Set<BlockType>? allowedTypes,
  String title = 'Add block',
}) {
  return showDraggableSheet<AddBlockResult>(
    context,
    title: title,
    slivers: (ctx, _) => [
      SliverToBoxAdapter(child: _AddBlockSheetBody(allowedTypes: allowedTypes)),
    ],
  );
}

class _AddBlockSheetBody extends StatelessWidget {
  const _AddBlockSheetBody({required this.allowedTypes});

  final Set<BlockType>? allowedTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deps = AppDependencies.of(context);
    final settings = deps.blockSettings;
    final subscriptions = deps.subscriptionRepository;
    final isPro = subscriptions.isPro;
    final visibleTypes = BlockType.values
        .where((t) => !_hiddenBlockTypes.contains(t))
        .where((t) => allowedTypes == null || allowedTypes!.contains(t))
        .toList(growable: false);
    final showCustomSection = allowedTypes == null;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final customs = settings.customCarousels;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: visibleTypes.length,
                itemBuilder: (gridCtx, i) => _BuiltinCell(
                  type: visibleTypes[i],
                  locked: !isPro && visibleTypes[i].isProOnly,
                  subscriptions: subscriptions,
                ),
              ),
            ),
            if (showCustomSection) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Custom blocks',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              if (customs.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    "You haven't defined any custom carousel blocks yet.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: customs.length,
                    itemBuilder: (gridCtx, i) => _CustomCell(
                      definition: customs[i],
                      // Already-created custom blocks are always usable —
                      // the Pro cap applies to *creating* a new one, gated
                      // on the "Add custom block" button below. (GUS-34)
                      locked: false,
                      subscriptions: subscriptions,
                    ),
                  ),
                ),
              ProLimitHint(
                used: customs.length,
                max: kFreeMaxCustomBlocks,
                noun: 'custom blocks',
                subscriptions: subscriptions,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Free users may create up to `kFreeMaxCustomBlocks`
                    // custom blocks; creating a further one presents the
                    // paywall on tap. (GUS-34)
                    if (!isPro &&
                        customs.length >= kFreeMaxCustomBlocks) {
                      if (!await requirePro(subscriptions, context: context)) {
                        return;
                      }
                      if (!context.mounted) return;
                    }
                    // Pop the sheet first so the editor pushes onto
                    // the layout-editor screen, not the sheet.
                    Navigator.of(context).pop();
                    context.push(Routes.newCustomBlock);
                  },
                  icon: AppIcon(HugeIcons.strokeRoundedPlusSign),
                  label: const Text('Add custom block'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BuiltinCell extends StatelessWidget {
  const _BuiltinCell({
    required this.type,
    required this.locked,
    required this.subscriptions,
  });

  final BlockType type;
  final bool locked;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickBlock(
        context: context,
        locked: locked,
        subscriptions: subscriptions,
        result: AddBlockResultBuiltin(type),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewTile(
            locked: locked,
            child: BlockWidget(
              data: type.sampleData(id: 'preview-${type.name}'),
              mode: BlockMode.readOnly,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: locked ? theme.disabledColor : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            type.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Square block preview with the shared chrome. When [locked], the
/// preview dims and a compact Pro crown overlays the top-right corner.
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tile = AspectRatio(
      aspectRatio: 1,
      child: AbsorbPointer(child: BlockChrome(child: child)),
    );
    if (!locked) return tile;
    return Stack(
      children: [
        Opacity(opacity: 0.45, child: tile),
        const Positioned(top: 6, right: 6, child: ProLockBadge(compact: true)),
      ],
    );
  }
}

/// Shared tap handler for both built-in and custom cells: when [locked],
/// present the paywall and only pop with [result] on a successful
/// purchase; otherwise pop immediately.
Future<void> _pickBlock({
  required BuildContext context,
  required bool locked,
  required SubscriptionRepository subscriptions,
  required AddBlockResult result,
}) async {
  if (!locked) {
    Navigator.of(context).pop(result);
    return;
  }
  final ok = await requirePro(subscriptions, context: context);
  if (ok && context.mounted) {
    Navigator.of(context).pop(result);
  }
}

class _CustomCell extends StatelessWidget {
  const _CustomCell({
    required this.definition,
    required this.locked,
    required this.subscriptions,
  });

  final CustomCarouselDefinition definition;
  final bool locked;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Build a sample JournalBlockData that points at this definition
    // and pre-selects the first item so the preview renders something
    // recognisable (the widget reads from BlockSettings live).
    final CarouselItem? sample = definition.items.isEmpty
        ? null
        : definition.items.first;
    final data = JournalBlockData.create(
      id: 'preview-${definition.id}',
      type: BlockType.customCarousel,
      content: CustomCarouselBlockContent(
        definitionId: definition.id,
        selected: sample,
      ).toMap(),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickBlock(
        context: context,
        locked: locked,
        subscriptions: subscriptions,
        result: AddBlockResultCustom(definition.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewTile(
            locked: locked,
            child: BlockWidget(data: data, mode: BlockMode.readOnly),
          ),
          const SizedBox(height: 8),
          Text(
            definition.title.isEmpty ? 'Untitled' : definition.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: locked ? theme.disabledColor : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${definition.items.length} item${definition.items.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
