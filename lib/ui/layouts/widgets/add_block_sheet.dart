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
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
  return showModalBottomSheet<AddBlockResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          return _AddBlockSheetBody(
            scrollController: scrollController,
            allowedTypes: allowedTypes,
            title: title,
          );
        },
      );
    },
  );
}

class _AddBlockSheetBody extends StatelessWidget {
  const _AddBlockSheetBody({
    required this.scrollController,
    required this.allowedTypes,
    required this.title,
  });

  final ScrollController scrollController;
  final Set<BlockType>? allowedTypes;
  final String title;

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
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate((gridCtx, i) {
                  final type = visibleTypes[i];
                  return _BuiltinCell(type: type);
                }, childCount: visibleTypes.length),
              ),
            ),
            if (showCustomSection) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Custom blocks',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (customs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      "You haven't defined any custom carousel blocks yet.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate((gridCtx, i) {
                      final def = customs[i];
                      return _CustomCell(definition: def);
                    }, childCount: customs.length),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Pop the sheet first so the editor pushes onto
                      // the layout-editor screen, not the sheet.
                      Navigator.of(context).pop();
                      context.push(Routes.newCustomBlock);
                    },
                    icon: const AppIcon(PhosphorIconsDuotone.plus),
                    label: const Text('Add custom block'),
                  ),
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
