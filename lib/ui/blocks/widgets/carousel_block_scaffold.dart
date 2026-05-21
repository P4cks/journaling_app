import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/block_with_title.dart';
import 'package:journaling_app_rewrite/ui/blocks/widgets/collapsible_carousel_block.dart';

/// Shared shell for carousel-style blocks (mood, manual weather, custom
/// carousel). Each consumer supplies the typed [options] list, the
/// current [selected] value, and a single [itemBuilder] that renders
/// the raw glyph for an option.
///
/// The scaffold owns:
/// - The [BlockWithTitle] wrap. Callers pass the resolved title (with
///   the global `BlockSettings.carouselTitlesEnabled` gate already
///   applied); `null` collapses the row.
/// - [BlockMode.readOnly] rendering: centred glyph, or an em-dash
///   placeholder when nothing has been picked.
/// - [BlockMode.editable] delegation to [CollapsibleCarouselBlock<T>],
///   wrapping the caller's [itemBuilder] in the standard
///   `AnimatedScale` + `AnimatedOpacity` focus animation that every
///   carousel uses.
///
/// The scaffold does not subscribe to `BlockSettings`. Callers
/// typically build it inside a `ListenableBuilder` so changes to the
/// title-toggle (and any other live-settings) rebuild this widget.
///
/// Variations stay local to each block: e.g. `CustomCarouselWidget`
/// handles missing definitions and preserved picks before delegating
/// here, and `WeatherManualWidget` keeps its `weatherIconFor` helper
/// next to its content shape.
class CarouselBlockScaffold<T> extends StatelessWidget {
  const CarouselBlockScaffold({
    super.key,
    required this.blockId,
    required this.mode,
    required this.title,
    required this.options,
    required this.selected,
    required this.itemBuilder,
    required this.onSelected,
    this.onInteractionLockChanged,
    this.editing = false,
  });

  final String blockId;
  final BlockMode mode;

  /// Title shown above the carousel via [BlockWithTitle]. `null` or
  /// empty hides the row entirely.
  final String? title;

  final List<T> options;
  final T? selected;

  /// Renders the raw glyph for one option. The scaffold wraps the
  /// result in `AnimatedScale` + `AnimatedOpacity` for the expanded
  /// carousel pages and reuses it un-wrapped (inside `Center`) for the
  /// collapsed view.
  final Widget Function(BuildContext context, T option, bool isSelected)
  itemBuilder;

  final void Function(T option) onSelected;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  /// Forwarded to [CollapsibleCarouselBlock.editing]. When true the
  /// carousel auto-expands. When false the carousel's internal
  /// tap-to-expand is suppressed — only the outer grid's double-tap
  /// detector can promote the block into edit mode.
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return BlockWithTitle(title: title, body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (mode == BlockMode.readOnly) {
      return _buildCollapsed(context, selected);
    }
    return CollapsibleCarouselBlock<T>(
      blockId: blockId,
      options: options,
      selected: selected,
      collapsedBuilder: _buildCollapsed,
      itemBuilder: (ctx, option, isSelected) => AnimatedScale(
        scale: isSelected ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 180),
          child: itemBuilder(ctx, option, isSelected),
        ),
      ),
      onSelected: onSelected,
      onInteractionLockChanged: onInteractionLockChanged,
      editing: editing,
    );
  }

  Widget _buildCollapsed(BuildContext context, T? value) {
    if (value == null) return const _CarouselEmptyPlaceholder();
    return Center(child: itemBuilder(context, value, true));
  }
}

/// Dimmed em-dash shown when a carousel has no selection yet. Shared
/// by every block that delegates to [CarouselBlockScaffold]; kept
/// private so callers go through the scaffold rather than reaching in
/// directly.
class _CarouselEmptyPlaceholder extends StatelessWidget {
  const _CarouselEmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '—',
        style: TextStyle(fontSize: 40, color: Theme.of(context).disabledColor),
      ),
    );
  }
}
