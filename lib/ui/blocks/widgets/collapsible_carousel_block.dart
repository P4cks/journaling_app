import 'package:flutter/material.dart';

/// Generic collapsible-carousel block body.
///
/// **Edit-mode is the only way in.** The carousel never auto-expands
/// on its own — it opens only when `widget.editing` is true (the
/// hosting block has been promoted into in-place edit mode via the
/// outer grid's double-tap detector, OR the block is mounted inside
/// the expanded route). When `editing` is false the collapsed icon
/// is inert; the user has to double-tap the tile to engage the
/// picker.
///
/// While expanded a 1.5 s auto-collapse timer ticks. The timer resets
/// on every page change (steady swipes keep the picker open). When
/// the timer fires it both collapses the carousel **and** signals
/// `onRequestExitEdit()` so the host can clear its `_editingBlockId`
/// in lock-step — the outline disappears with the carousel instead
/// of lingering.
///
/// Reports its expanded state via [onInteractionLockChanged] so the
/// outer `JournalPager` can disable horizontal date-swipes while the
/// carousel is open — see [lib/ui/journal/widgets/journal_pager.dart].
class CollapsibleCarouselBlock<T> extends StatefulWidget {
  const CollapsibleCarouselBlock({
    super.key,
    required this.blockId,
    required this.options,
    required this.selected,
    required this.itemBuilder,
    required this.collapsedBuilder,
    required this.onSelected,
    this.onInteractionLockChanged,
    this.onRequestExitEdit,
    this.viewportFraction = 0.42,
    this.collapseDelay = const Duration(milliseconds: 1500),
    this.switchDuration = const Duration(milliseconds: 180),
    this.editing = false,
    this.autoCollapse = true,
  });

  final String blockId;
  final List<T> options;

  /// Currently-selected option, or null when nothing is set.
  final T? selected;

  /// Build one option for the carousel page. `isSelected` lets the
  /// caller scale / fill / colour the option.
  final Widget Function(BuildContext context, T option, bool isSelected)
  itemBuilder;

  /// Build the collapsed view (single centred icon, or placeholder
  /// when [selected] is null).
  final Widget Function(BuildContext context, T? selected) collapsedBuilder;

  /// Fired when the user swipes to a new page.
  final ValueChanged<T> onSelected;

  /// Lock callback — when `true`, the outer pager should disable
  /// horizontal swipes for the duration of this block's expansion.
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  /// Fired in lock-step with the 1.5 s auto-collapse — lets the host
  /// drop `_editingBlockId` so the in-place edit-mode outline
  /// disappears alongside the carousel collapsing. Optional; the
  /// expanded-route host omits this because it wants the picker to
  /// stay open until the route is dismissed.
  final VoidCallback? onRequestExitEdit;

  final double viewportFraction;
  final Duration collapseDelay;
  final Duration switchDuration;

  /// True when the hosting block is in edit mode. The carousel
  /// auto-expands on the false → true flip and collapses on the
  /// true → false flip.
  final bool editing;

  /// When true (default), the carousel auto-collapses after
  /// [collapseDelay] of no swipe. The expanded route passes `false`
  /// to keep the picker open until the user dismisses the route —
  /// per the design rule "carousel stays open in expanded view".
  final bool autoCollapse;

  @override
  State<CollapsibleCarouselBlock<T>> createState() =>
      _CollapsibleCarouselBlockState<T>();
}

class _CollapsibleCarouselBlockState<T>
    extends State<CollapsibleCarouselBlock<T>> {
  late final PageController _controller;
  late bool _expanded;

  /// Monotonically-incremented token. Pending `Future.delayed` collapse
  /// callbacks capture the current value; when they fire they bail out
  /// if their captured token no longer matches `_collapseGen`. Bumped
  /// on every reschedule and on `dispose`.
  int _collapseGen = 0;

  int get _initialIndex {
    final sel = widget.selected;
    if (sel == null) return 0;
    final idx = widget.options.indexOf(sel);
    return idx < 0 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    // The carousel opens only when the host has promoted the block
    // into edit mode. Null selection no longer triggers an
    // auto-expand on its own — the user must double-tap to engage.
    _expanded = widget.editing;
    _controller = PageController(
      initialPage: _initialIndex,
      viewportFraction: widget.viewportFraction,
    );
    if (_expanded) {
      // Mounted directly in edit mode (e.g. inside the expanded
      // route). Acquire the pager lock + schedule the auto-collapse.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onInteractionLockChanged?.call(widget.blockId, true);
        if (widget.autoCollapse) _scheduleCollapse();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CollapsibleCarouselBlock<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing != widget.editing) {
      if (widget.editing) {
        // Edit-mode just became active — auto-expand.
        _expand();
      } else {
        // Edit-mode left — collapse so the carousel doesn't keep the
        // pager locked while no one is interacting with it.
        if (_expanded) {
          _collapseGen++;
          setState(() => _expanded = false);
          widget.onInteractionLockChanged?.call(widget.blockId, false);
        }
      }
    }
  }

  @override
  void dispose() {
    _collapseGen++;
    if (_expanded) {
      widget.onInteractionLockChanged?.call(widget.blockId, false);
    }
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    if (_expanded) return;
    FocusScope.of(context).unfocus();
    setState(() => _expanded = true);
    widget.onInteractionLockChanged?.call(widget.blockId, true);
    // Schedule jump + collapse together AFTER the rebuild has rendered
    // the carousel — this way the 1.5s window starts when the user
    // actually sees the carousel, and isn't gated on `onPageChanged`
    // firing (it doesn't fire for a no-op jumpToPage).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.hasClients) {
        _controller.jumpToPage(_initialIndex);
      }
      if (widget.autoCollapse) _scheduleCollapse();
    });
  }

  void _scheduleCollapse() {
    _collapseGen++;
    final gen = _collapseGen;
    Future.delayed(widget.collapseDelay, () {
      if (!mounted || gen != _collapseGen || !_expanded) return;
      setState(() => _expanded = false);
      widget.onInteractionLockChanged?.call(widget.blockId, false);
      // Signal the host so in-place edit mode exits in lock-step —
      // the outline shouldn't linger after the carousel collapses.
      widget.onRequestExitEdit?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = _expanded
        ? KeyedSubtree(
            key: const ValueKey('carousel-expanded'),
            child: _buildCarousel(),
          )
        : KeyedSubtree(
            key: const ValueKey('carousel-collapsed'),
            child: widget.collapsedBuilder(context, widget.selected),
          );

    // No internal tap handler — the picker is only reachable when the
    // host flips `editing` to true, which is itself driven by the
    // outer grid's double-tap detector.
    return AnimatedSwitcher(
      duration: widget.switchDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.options.length,
      onPageChanged: (index) {
        FocusScope.of(context).unfocus();
        widget.onSelected(widget.options[index]);
        if (widget.autoCollapse) _scheduleCollapse();
      },
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final isSelected = option == widget.selected;
        return Center(child: widget.itemBuilder(context, option, isSelected));
      },
    );
  }
}
