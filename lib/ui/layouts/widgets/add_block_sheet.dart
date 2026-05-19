import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/post_it_block.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';

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
      SliverToBoxAdapter(
        child: _AddBlockSheetBody(allowedTypes: allowedTypes),
      ),
    ],
  );
}

class _AddBlockSheetBody extends StatelessWidget {
  const _AddBlockSheetBody({required this.allowedTypes});

  final Set<BlockType>? allowedTypes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppDependencies.of(context).blockSettings;
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
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: visibleTypes.length,
                itemBuilder: (gridCtx, i) =>
                    _BuiltinCell(type: visibleTypes[i]),
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
                    itemBuilder: (gridCtx, i) =>
                        _CustomCell(definition: customs[i]),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: OutlinedButton.icon(
                  onPressed: () {
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
  const _BuiltinCell({required this.type});

  final BlockType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(AddBlockResultBuiltin(type)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AbsorbPointer(
              child: PostItBlock(
                child: BlockWidget(
                  data: type.sampleData(id: 'preview-${type.name}'),
                  mode: BlockMode.readOnly,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            type.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CustomCell extends StatelessWidget {
  const _CustomCell({required this.definition});

  final CustomCarouselDefinition definition;

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
      onTap: () => Navigator.of(
        context,
      ).pop(AddBlockResultCustom(definition.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AbsorbPointer(
              child: PostItBlock(
                child: BlockWidget(data: data, mode: BlockMode.readOnly),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            definition.title.isEmpty ? 'Untitled' : definition.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${definition.items.length} item${definition.items.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
