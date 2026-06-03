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
    // Empty state. In an editable entry, preview the carousel exactly as
    // it looks once tapped — the same `PageView` peek (centre page +
    // neighbours peeking) — but with EVERY page rendered "unfocused"
    // (scaled down + dimmed), so none is highlighted big and it reads as
    // "you haven't picked anything yet" (GUS-39). Read-only past entries
    // keep the em-dash: faint options there would look like a selection
    // that was never actually made.
    if (widget.mode == BlockMode.readOnly || widget.options.isEmpty) {
      return const _CarouselEmptyPlaceholder();
    }
    return _UnfocusedCarouselPreview<T>(
      options: widget.options,
      itemBuilder: widget.itemBuilder,
    );
  }
}

/// Non-interactive preview of the carousel in its "unfocused" state:
/// the same `PageView` peek the expanded picker uses (centre page plus
/// neighbours peeking via [_kViewportFraction]), but with every page
/// scaled down + dimmed so none is highlighted — signalling "nothing
/// picked yet". Owns its own [PageController] (centred on the middle
/// option) so the controller is disposed properly; built only in the
/// editable empty state by [CarouselBlockScaffold]. (GUS-39)
class _UnfocusedCarouselPreview<T> extends StatefulWidget {
  const _UnfocusedCarouselPreview({
    required this.options,
    required this.itemBuilder,
  });

  final List<T> options;
  final Widget Function(BuildContext context, T option, bool isSelected)
  itemBuilder;

  @override
  State<_UnfocusedCarouselPreview<T>> createState() =>
      _UnfocusedCarouselPreviewState<T>();
}

class _UnfocusedCarouselPreviewState<T>
    extends State<_UnfocusedCarouselPreview<T>> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.options.length ~/ 2,
      viewportFraction: _kViewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      // The whole tile's tap is owned by the scaffold's GestureDetector
      // (single tap expands), so the preview itself must not scroll.
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.options.length,
      itemBuilder: (ctx, index) => Center(
        child: Opacity(
          // Mirrors the expanded carousel's unfocused-page styling.
          opacity: 0.45,
          child: Transform.scale(
            scale: 0.6,
            child: widget.itemBuilder(ctx, widget.options[index], false),
          ),
        ),
      ),
    );
  }
}

/// Viewport fraction shared with `CollapsibleCarouselBlock`'s default so
/// the unfocused preview peeks identically to the expanded picker.
const double _kViewportFraction = 0.42;

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
