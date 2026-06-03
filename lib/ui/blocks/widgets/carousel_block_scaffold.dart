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
/// - The single-vs-double-tap disambiguation. A `GestureDetector` with
///   both `onTap` (single tap → expand the carousel) and `onDoubleTap`
///   (double tap → host pushes the expanded route) sits over the body.
///   Flutter's arena waits `kDoubleTapTimeout` (~300 ms) before firing
///   `onTap`, so a double-tap is intercepted before the picker
///   visibly expands.
/// - The internal `_editing` flag that the carousel reads to decide
///   when to expand. It's seeded from `widget.editing` (the route
///   passes `true` so the picker is interactive from the moment the
///   Hero lands) and flipped on tap (in-grid).
/// - [BlockMode.readOnly] rendering: centred glyph, or an em-dash
///   placeholder when nothing has been picked.
///
/// The scaffold does not subscribe to `BlockSettings`. Callers
/// typically build it inside a `ListenableBuilder` so changes to the
/// title-toggle (and any other live-settings) rebuild this widget.
class CarouselBlockScaffold<T> extends StatefulWidget {
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
    this.onRequestExitEdit,
    this.onDoubleTap,
    this.editing = false,
    this.autoCollapse = true,
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

  /// Seeds the local `_editing` state at mount. Pass `true` from the
  /// expanded route so the carousel auto-opens; pass `false` (default)
  /// in the grid so the user has to tap once.
  final bool editing;

  /// Fires after the 1.5 s auto-collapse so the host can drop its
  /// in-place edit-mode marker. Pass null in the expanded route since
  /// the picker stays open until the user dismisses the route.
  final VoidCallback? onRequestExitEdit;

  /// Host's "push expanded route" callback — fires on double-tap.
  final VoidCallback? onDoubleTap;

  /// When false, the carousel won't auto-collapse after 1.5 s — used
  /// by the expanded route so the picker stays available.
  final bool autoCollapse;

  @override
  State<CarouselBlockScaffold<T>> createState() =>
      _CarouselBlockScaffoldState<T>();
}

class _CarouselBlockScaffoldState<T> extends State<CarouselBlockScaffold<T>> {
  late bool _editing;

  @override
  void initState() {
    super.initState();
    _editing = widget.editing;
  }

  @override
  void didUpdateWidget(covariant CarouselBlockScaffold<T> old) {
    super.didUpdateWidget(old);
    // If the host's editing flag flips externally, mirror it locally.
    // (The route doesn't do this today — initial value suffices — but
    // future hosts that toggle dynamically still work.)
    if (widget.editing != old.editing) {
      setState(() => _editing = widget.editing);
    }
  }

  void _onSingleTap() {
    if (_editing) return;
    setState(() => _editing = true);
  }

  void _onCarouselExitEdit() {
    if (mounted && _editing) {
      setState(() => _editing = false);
    }
    widget.onRequestExitEdit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final titledBody = BlockWithTitle(
      title: widget.title,
      body: _buildBody(context),
    );
    if (widget.mode == BlockMode.readOnly) {
      return Padding(padding: const EdgeInsets.all(12), child: titledBody);
    }
    // `GestureDetector(onTap, onDoubleTap)` wraps the WHOLE inset
    // (title + body + 12 px chrome padding) so taps anywhere inside
    // the chrome — including the visual padding — engage the carousel
    // or push the expanded route. Flutter's arena waits ~300 ms before
    // resolving: single tap flips `_editing` (carousel expands), double
    // tap pushes the route. Inside the PageView swipe drags still work
    // because they're pan gestures, not tap gestures, and don't compete
    // with us in the arena.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onSingleTap,
      onDoubleTap: widget.onDoubleTap,
      child: Padding(padding: const EdgeInsets.all(12), child: titledBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.mode == BlockMode.readOnly) {
      return _buildCollapsed(context, widget.selected);
    }
    return CollapsibleCarouselBlock<T>(
      blockId: widget.blockId,
      options: widget.options,
      selected: widget.selected,
      collapsedBuilder: _buildCollapsed,
      itemBuilder: (ctx, option, isSelected) => AnimatedScale(
        scale: isSelected ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 180),
          child: widget.itemBuilder(ctx, option, isSelected),
        ),
      ),
      onSelected: widget.onSelected,
      onInteractionLockChanged: widget.onInteractionLockChanged,
      onRequestExitEdit: _onCarouselExitEdit,
      editing: _editing,
      autoCollapse: widget.autoCollapse,
    );
  }

  Widget _buildCollapsed(BuildContext context, T? value) {
    if (value != null) {
      return Center(child: widget.itemBuilder(context, value, true));
    }
    // Empty state. In an editable entry, preview the carousel "unfocused"
    // — every option laid out small and dimmed — so the tile reads as a
    // picker you can engage rather than a dead em-dash (GUS-39). Read-only
    // past entries keep the em-dash: faint options there would look like a
    // selection that was never actually made.
    if (widget.mode == BlockMode.readOnly || widget.options.isEmpty) {
      return const _CarouselEmptyPlaceholder();
    }
    return Center(
      child: Opacity(
        opacity: 0.4,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in widget.options)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: widget.itemBuilder(context, option, false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dimmed em-dash shown when a carousel has no selection and no options
/// to preview (or in a read-only past entry). Kept private so callers go
/// through the scaffold rather than reaching in directly.
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
