import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/carousel_block_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Block widget for a `BlockType.customCarousel` instance. Resolves
/// `definitionId` against the `BlockSettings` registry and then either:
///
/// - **Found, with items**: delegates to [CarouselBlockScaffold] over
///   the definition's items, gated by the global
///   `BlockSettings.carouselTitlesEnabled` toggle.
/// - **Missing definition + preserved pick**: renders the verbatim
///   pick locked (no carousel) so deleting a definition doesn't erase
///   what the user previously logged.
/// - **Missing definition or itemless definition without a preserved
///   pick**: dimmed "Deleted block" placeholder. The block is treated
///   as empty by the sweep.
///
/// Subscribes to `BlockSettings` so registry edits (title, items,
/// global title toggle) propagate live.
class CustomCarouselWidget extends StatelessWidget {
  const CustomCarouselWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onInteractionLockChanged,
    this.onRequestExitEdit,
    this.onDoubleTap,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;
  final VoidCallback? onRequestExitEdit;
  final VoidCallback? onDoubleTap;
  final bool editing;
  final bool expanded;

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
          return const _DeletedPlaceholder();
        }

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

        return CarouselBlockScaffold<CarouselItem>(
          blockId: data.id,
          mode: mode,
          title: settings.carouselTitlesEnabled ? definition.title : null,
          options: items,
          selected: selectedInDef,
          itemBuilder: (ctx, item, isSelected) => _renderItem(item, isSelected),
          onSelected: (item) => onChanged?.call(
            data.copyWith(
              content: CustomCarouselBlockContent(
                definitionId: definition.id,
                selected: item,
              ).toMap(),
            ),
          ),
          onInteractionLockChanged: onInteractionLockChanged,
          onRequestExitEdit: expanded ? null : onRequestExitEdit,
          onDoubleTap: onDoubleTap,
          editing: editing || expanded,
          // Auto-collapse in both hosts. See
          // mood_tracker_widget.dart for the rationale.
          autoCollapse: true,
        );
      },
    );
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
          return AppIcon(HugeIcons.strokeRoundedQuestion, size: 56);
        }
        return AppIcon(icon.icon, size: 56);
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
