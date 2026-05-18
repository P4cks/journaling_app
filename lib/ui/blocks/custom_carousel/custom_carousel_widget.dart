import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_with_title.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/collapsible_carousel_block.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Block widget for a `BlockType.customCarousel` instance. Resolves
/// `definitionId` against the `BlockSettings` registry and renders:
///
/// - **Found**: the definition's `title` row (via [BlockWithTitle])
///   above a [CollapsibleCarouselBlock]`<CarouselItem>` over the
///   definition's items.
/// - **Missing** (orphan): a dimmed "Deleted block" placeholder. The
///   user can't pick anything; the block is treated as empty by the
///   sweep.
///
/// Subscribes to `BlockSettings` so edits to the definition (title /
/// items) propagate live.
class CustomCarouselWidget extends StatelessWidget {
  const CustomCarouselWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onInteractionLockChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  @override
  Widget build(BuildContext context) {
    final settings = AppDependencies.of(context).blockSettings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final content = CustomCarouselBlockContent.fromMap(data.content);
        final defId = content.definitionId;
        final definition = defId == null
            ? null
            : settings.findCustomCarousel(defId);
        if (definition == null) {
          // Definition was deleted out from under this block. Keep the
          // user's previously-saved pick visible (locked, no carousel)
          // so deleting a definition doesn't visually erase the past
          // entry's choice. Falls through to the "Deleted block"
          // placeholder only when there's nothing to show.
          final preserved = content.selected;
          if (preserved != null) {
            return Center(child: _renderItem(preserved, true));
          }
          return _DeletedPlaceholder();
        }
        return BlockWithTitle(
          title: definition.title,
          body: _buildBody(context, content, definition),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CustomCarouselBlockContent content,
    CustomCarouselDefinition definition,
  ) {
    final items = definition.items;
    if (items.isEmpty) {
      // Definition exists but is itemless — same UX as orphan.
      return const _DeletedPlaceholder();
    }
    final selected = content.selected;
    // Find the *current* item in the definition that matches the
    // verbatim selection (so reorders keep the pick correct).
    final selectedInDef = selected == null
        ? null
        : items.firstWhere(
            (i) => i == selected,
            orElse: () => CarouselItem(
              kind: selected.kind,
              value: selected.value,
            ),
          );

    if (mode == BlockMode.readOnly) {
      return _buildCollapsed(context, selectedInDef);
    }

    return CollapsibleCarouselBlock<CarouselItem>(
      blockId: data.id,
      options: items,
      selected: selectedInDef,
      collapsedBuilder: _buildCollapsed,
      itemBuilder: (ctx, item, isSelected) => AnimatedScale(
        scale: isSelected ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 180),
          child: _renderItem(item, isSelected),
        ),
      ),
      onSelected: (item) => onChanged?.call(
        data.copyWith(
          content: CustomCarouselBlockContent(
            definitionId: definition.id,
            selected: item,
          ).toMap(),
        ),
      ),
      onInteractionLockChanged: onInteractionLockChanged,
    );
  }

  Widget _buildCollapsed(BuildContext context, CarouselItem? item) {
    if (item == null) {
      return Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 40,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }
    return Center(child: _renderItem(item, true));
  }

  /// One option in the carousel. Emoji items render as a sized [Text];
  /// icon items resolve through [carouselIconFor] and fall back to a
  /// question-mark glyph if the name is unknown (e.g. icon removed
  /// from the catalogue after the definition was saved).
  Widget _renderItem(CarouselItem item, bool selected) {
    switch (item.kind) {
      case CarouselItemKind.emoji:
        return Text(item.value, style: const TextStyle(fontSize: 56));
      case CarouselItemKind.icon:
        final icon = carouselIconFor(item.value);
        if (icon == null) {
          return const AppIcon(PhosphorIconsDuotone.question, size: 56);
        }
        return AppIcon(
          selected ? icon.fill : icon.duotone,
          size: 56,
        );
    }
  }
}

class _DeletedPlaceholder extends StatelessWidget {
  const _DeletedPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Deleted block',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.disabledColor,
          ),
        ),
      ),
    );
  }
}
