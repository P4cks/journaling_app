import 'package:flutter/material.dart';

/// Generic collapsible-carousel block body.
///
/// Renders [collapsedBuilder] until the user taps; tapping expands a
/// horizontal `PageView` of [options] and starts a 1500 ms timer that
/// auto-collapses back to the centred icon. The timer also fires on
/// every page change, so a steady stream of swipes keeps the carousel
/// open until 1.5 s after the last interaction.
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
    this.viewportFraction = 0.42,
    this.collapseDelay = const Duration(milliseconds: 1500),
    this.switchDuration = const Duration(milliseconds: 180),
    this.editing = false,
  });

  final String blockId;
  final List<T> options;

  /// Currently-selected option, or null when nothing is set. Legacy
  /// empty content falls through here; with the new materialize-time
  /// defaults this is rarely null for editable blocks.
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

  final double viewportFraction;
  final Duration collapseDelay;
  final Duration switchDuration;

  /// True when the hosting block is in edit mode (set by the new
  /// double-tap-to-edit flow). When false, tapping the collapsed view
  /// no longer expands the carousel — the outer grid's double-tap
  /// detector is the only way in. When true, the carousel auto-expands.
  final bool editing;

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
    // When the user hasn't picked anything yet, render the carousel
    // already expanded so every option is visible (none focused, all
    // at the unselected itemBuilder style). The user can swipe to
    // commit; auto-collapse fires after they do, NOT before — so the
    // empty state stays visible until there's a selection to fall
    // back to. This initial empty state does not lock the outer date
    // pager, so the user can still move to another entry before
    // choosing an option.
    //
    // When `editing` is true at mount (e.g. mounted inside the
    // expanded block route), open expanded regardless so the user can
    // pick immediately without a second gesture.
    _expanded = widget.selected == null || widget.editing;
    _controller = PageController(
      initialPage: _initialIndex,
      viewportFraction: widget.viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant CollapsibleCarouselBlock<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editing != widget.editing) {
      if (widget.editing) {
        // Edit-mode just became active — auto-expand. _expand handles
        // the rebuild + lock callback + collapse scheduling.
        _expand();
      } else {
        // Edit-mode left — collapse so the carousel doesn't keep the
        // pager locked while no one is interacting with it.
        if (_expanded && widget.selected != null) {
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
      _scheduleCollapse();
    });
  }

  void _scheduleCollapse() {
    _collapseGen++;
    final gen = _collapseGen;
    Future.delayed(widget.collapseDelay, () {
      if (!mounted || gen != _collapseGen || !_expanded) return;
      // Don't collapse to the placeholder while there's still no
      // pick — the carousel needs to stay visible so the user can
      // make one. Once `widget.selected` is non-null (the parent
      // rebuilt after onPageChanged), the next scheduled collapse
      // proceeds normally.
      if (widget.selected == null) return;
      setState(() => _expanded = false);
      widget.onInteractionLockChanged?.call(widget.blockId, false);
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

    // Internal tap-to-expand only kicks in while edit mode is active.
    // Outside edit mode the outer grid's double-tap detector requests
    // editing — single-tap on the collapsed carousel is inert.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (_expanded || !widget.editing) ? null : _expand,
      child: AnimatedSwitcher(
        duration: widget.switchDuration,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: child,
      ),
    );
  }

  Widget _buildCarousel() {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.options.length,
      onPageChanged: (index) {
        FocusScope.of(context).unfocus();
        widget.onSelected(widget.options[index]);
        _scheduleCollapse();
      },
      itemBuilder: (context, index) {
        final option = widget.options[index];
        final isSelected = option == widget.selected;
        return Center(child: widget.itemBuilder(context, option, isSelected));
      },
    );
  }
}
