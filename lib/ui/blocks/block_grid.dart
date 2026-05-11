import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_card.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';

class BlockGrid extends StatefulWidget {
  const BlockGrid({
    super.key,
    required this.blocks,
    required this.mode,
    this.onBlockChanged,
    this.cardTrailing,
    this.onReorder,
    this.padding = const EdgeInsets.all(16),
  });

  final List<JournalBlockData> blocks;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onBlockChanged;
  final Widget Function(JournalBlockData block, int index)? cardTrailing;

  /// When provided, tiles become drop targets for reordering. The caller
  /// supplies the drag source (typically a [LongPressDraggable] inside
  /// [cardTrailing]) carrying the source tile's index as data.
  final void Function(int from, int to)? onReorder;

  final EdgeInsets padding;

  @override
  State<BlockGrid> createState() => _BlockGridState();
}

class _BlockGridState extends State<BlockGrid> {
  int? _hoveringTargetIndex;
  int? _draggingSourceIndex;

  bool get _reorderable => widget.onReorder != null;

  bool _isNoop(int from, int insertIndex) =>
      from == insertIndex || from + 1 == insertIndex;

  /// Apply [fn] inside [setState], deferring to a post-frame callback if we
  /// are currently inside a build pass. Drag callbacks (`onMove`, `onLeave`)
  /// can fire synchronously when a freshly-mounted `DragTarget` lands under
  /// the user's finger during a rebuild — calling `setState` synchronously
  /// from there trips the `setState during build` assertion.
  void _safeSetState(VoidCallback fn) {
    void apply() {
      if (!mounted) return;
      setState(fn);
    }

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  void _setHover(int targetIndex, int sourceIndex) {
    // Flutter fires onMove regardless of onWillAccept, so guard no-ops here
    // so they can't flash a ghost in an invalid drop position.
    if (_isNoop(sourceIndex, targetIndex)) return;
    if (_hoveringTargetIndex == targetIndex &&
        _draggingSourceIndex == sourceIndex) {
      return;
    }
    _safeSetState(() {
      _hoveringTargetIndex = targetIndex;
      _draggingSourceIndex = sourceIndex;
    });
  }

  void _clearHoverFor(int targetIndex) {
    if (_hoveringTargetIndex != targetIndex) return;
    _safeSetState(() {
      _hoveringTargetIndex = null;
      _draggingSourceIndex = null;
    });
  }

  void _accept(int from, int to) {
    _safeSetState(() {
      _hoveringTargetIndex = null;
      _draggingSourceIndex = null;
    });
    widget.onReorder!(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: widget.padding,
      child: Column(
        children: [
          StaggeredGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: _buildGridChildren(),
          ),
          if (_reorderable && widget.blocks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildTrailingTarget(),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGridChildren() {
    final children = <Widget>[];
    final draggingIdx = _draggingSourceIndex;
    for (var i = 0; i < widget.blocks.length; i++) {
      // While a tile is being dragged, remove it from the grid entirely so
      // the remaining tiles re-flow. The drag itself continues in the
      // Overlay; the source widget can be unmounted safely.
      if (draggingIdx == i) continue;

      if (_reorderable && _hoveringTargetIndex == i) {
        children.add(_buildGhost());
      }
      children.add(_buildTile(i));
    }
    if (_reorderable && _hoveringTargetIndex == widget.blocks.length) {
      children.add(_buildGhost());
    }
    return children;
  }

  Widget _buildTile(int index) {
    final block = widget.blocks[index];
    final scheme = Theme.of(context).colorScheme;
    final card = BlockCard(
      topRight: widget.cardTrailing?.call(block, index),
      child: BlockWidget(
        key: ValueKey(block.id),
        data: block,
        mode: widget.mode,
        onChanged: widget.onBlockChanged,
      ),
    );

    Widget content = card;
    if (_reorderable) {
      final draggable = LongPressDraggable<int>(
        data: index,
        onDragStarted: () {
          _safeSetState(() => _draggingSourceIndex = index);
        },
        onDragEnd: (_) {
          _safeSetState(() {
            _draggingSourceIndex = null;
            _hoveringTargetIndex = null;
          });
        },
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: scheme.primaryContainer,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  block.type.icon,
                  color: scheme.onPrimaryContainer,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  block.type.label,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: card,
      );

      content = DragTarget<int>(
        onWillAcceptWithDetails: (details) => !_isNoop(details.data, index),
        onMove: (details) => _setHover(index, details.data),
        onLeave: (_) => _clearHoverFor(index),
        onAcceptWithDetails: (details) => _accept(details.data, index),
        builder: (context, candidate, rejected) => draggable,
      );
    }

    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1,
      child: content,
    );
  }

  Widget _buildGhost() {
    final scheme = Theme.of(context).colorScheme;
    final source =
        (_draggingSourceIndex != null &&
                _draggingSourceIndex! >= 0 &&
                _draggingSourceIndex! < widget.blocks.length)
            ? widget.blocks[_draggingSourceIndex!]
            : null;
    final targetIndex = _hoveringTargetIndex!;

    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) =>
            !_isNoop(details.data, targetIndex),
        onMove: (details) => _setHover(targetIndex, details.data),
        onLeave: (_) => _clearHoverFor(targetIndex),
        onAcceptWithDetails: (details) => _accept(details.data, targetIndex),
        builder: (context, candidate, rejected) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              border: Border.all(color: scheme.primary, width: 2),
            ),
            child: source == null
                ? null
                : Center(
                    child: Icon(
                      source.type.icon,
                      color: scheme.primary,
                      size: 32,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTrailingTarget() {
    final insertIndex = widget.blocks.length;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => !_isNoop(details.data, insertIndex),
      onMove: (details) => _setHover(insertIndex, details.data),
      onLeave: (_) => _clearHoverFor(insertIndex),
      onAcceptWithDetails: (details) => _accept(details.data, insertIndex),
      builder: (context, candidate, rejected) => const SizedBox(height: 32),
    );
  }
}
