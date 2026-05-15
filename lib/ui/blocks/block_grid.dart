import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_card.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';

// ---------------------------------------------------------------------------
// BlockGrid — Notion-style drag-to-reorder
//
// Design:
//  • The grid layout stays completely stable while dragging. No ghost tiles
//    are injected into the StaggeredGrid, so there is no reflow jank.
//  • A single DragTarget wraps the entire scrollable area.  Its onMove
//    callback converts the pointer position into a logical insertion index
//    by iterating over the RenderBoxes of each tile key.
//  • A CustomPainter draws a coloured insertion line between the two tiles
//    that straddle the current insertion index.  The line is rendered in an
//    overlay Stack so it never affects layout.
//  • The dragged tile is rendered semi-transparent (0.35 opacity) so the
//    user can still see where it came from.
// ---------------------------------------------------------------------------

class BlockGrid extends StatefulWidget {
  const BlockGrid({
    super.key,
    required this.blocks,
    required this.mode,
    this.onBlockChanged,
    this.cardTrailing,
    this.onReorder,
    this.padding = const EdgeInsets.all(16),
    this.onJumpToDate,
    this.onInteractionLockChanged,
  });

  final List<JournalBlockData> blocks;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onBlockChanged;
  final ValueChanged<DateTime>? onJumpToDate;
  final Widget Function(JournalBlockData block, int index)? cardTrailing;
  final void Function(int from, int to)? onReorder;
  final EdgeInsets padding;

  /// Forwarded to `BlockWidget`. When a block reports `locked: true`
  /// the journal pager disables its outer horizontal swipe — see
  /// [lib/ui/journal/widgets/journal_pager.dart].
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  @override
  State<BlockGrid> createState() => _BlockGridState();
}

class _BlockGridState extends State<BlockGrid> {
  // Logical insertion index where the item will land (0 … blocks.length).
  // null = no active drag or cursor has left the grid.
  int? _insertionIndex;

  // One GlobalKey per tile so we can measure each tile's screen position.
  // Initialised inline (not `late`) so it is never uninitialized, even if
  // something accesses it before initState runs (e.g. during a hot-reload
  // didUpdateWidget call that arrives before initState completes).
  List<GlobalKey> _tileKeys = const [];

  // Key on the Stack that wraps the whole grid, used as the RenderBox
  // ancestor for coordinate conversions.
  final GlobalKey _gridKey = GlobalKey();

  bool get _reorderable => widget.onReorder != null;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  List<GlobalKey> _buildKeys(int length) =>
      List.generate(length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _tileKeys = _buildKeys(widget.blocks.length);
  }

  @override
  void didUpdateWidget(BlockGrid old) {
    super.didUpdateWidget(old);
    if (widget.blocks.length != _tileKeys.length) {
      _tileKeys = _buildKeys(widget.blocks.length);
    }
  }

  // -------------------------------------------------------------------------
  // Coordinate helpers
  // -------------------------------------------------------------------------

  /// Returns the [Rect] of tile [index] in the grid Stack's local space,
  /// or null if it hasn't been laid out yet.
  Rect? _tileRect(int index) {
    if (index < 0 || index >= _tileKeys.length) return null;
    final tileBox =
        _tileKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (tileBox == null || gridBox == null) return null;
    final topLeft = tileBox.localToGlobal(Offset.zero, ancestor: gridBox);
    return topLeft & tileBox.size;
  }

  // -------------------------------------------------------------------------
  // Insertion-index computation
  // -------------------------------------------------------------------------

  /// Converts a pointer offset (global coordinates) to the best logical
  /// insertion index using the Notion heuristic:
  ///
  ///  1. Find the row (group of tiles sharing the same centre-Y) nearest to
  ///     the cursor's Y.
  ///  2. On that row, find the tile whose centre-X is nearest to the cursor's X.
  ///  3. Left half of that tile → insert before it; right half → insert after.
  int _computeInsertionIndex(Offset globalPos) {
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return widget.blocks.length;

    final local = gridBox.globalToLocal(globalPos);
    final n = widget.blocks.length;
    if (n == 0) return 0;

    // Build centre list (may contain nulls for not-yet-laid-out tiles).
    final centres = List<Offset?>.generate(n, (i) => _tileRect(i)?.center);

    // 1. Find the row (by Y) closest to local.dy.
    double bestDy = double.infinity;
    int closestIdx = 0;
    for (var i = 0; i < n; i++) {
      final c = centres[i];
      if (c == null) continue;
      final dy = (c.dy - local.dy).abs();
      if (dy < bestDy) {
        bestDy = dy;
        closestIdx = i;
      }
    }

    // 2. Collect all tile indices on the same row.
    final rowY = centres[closestIdx]?.dy ?? 0;
    const rowEpsilon = 4.0;
    final rowIndices = <int>[
      for (var i = 0; i < n; i++)
        if (centres[i] != null && (centres[i]!.dy - rowY).abs() < rowEpsilon) i,
    ];

    // 3. Within that row, find the tile nearest horizontally.
    double bestDx = double.infinity;
    int nearest = closestIdx;
    for (final i in rowIndices) {
      final dx = (centres[i]!.dx - local.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        nearest = i;
      }
    }

    // 4. Left/right half decision.
    final cx = centres[nearest]?.dx ?? local.dx;
    return local.dx < cx ? nearest : nearest + 1;
  }

  // -------------------------------------------------------------------------
  // Drag lifecycle
  // -------------------------------------------------------------------------

  void _onDragStarted() {
    setState(() {
      _insertionIndex = null;
    });
  }

  void _onDragUpdate(DragTargetDetails<int> details) {
    final idx = _computeInsertionIndex(details.offset);
    if (idx == _insertionIndex) return;

    void apply() {
      if (!mounted) return;
      setState(() => _insertionIndex = idx);
    }

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  void _onDragEnd() {
    if (!mounted) return;
    setState(() => _insertionIndex = null);
  }

  void _onAccept(int from) {
    final insertAt = _insertionIndex ?? widget.blocks.length;
    setState(() => _insertionIndex = null);
    // Normalise: when inserting after the source the logical index shifts by 1.
    final to = insertAt > from ? insertAt - 1 : insertAt;
    if (from != to) widget.onReorder!(from, to);
  }

  // -------------------------------------------------------------------------
  // Insertion line geometry
  // -------------------------------------------------------------------------

  _InsertionLineInfo? _insertionLineInfo() {
    final idx = _insertionIndex;
    if (idx == null) return null;
    final n = widget.blocks.length;
    if (n == 0) return null;

    // Drop after the last tile → vertical line to the right of it.
    if (idx >= n) {
      final r = _tileRect(n - 1);
      if (r == null) return null;
      return _InsertionLineInfo(
        start: Offset(r.right + 5, r.top),
        end: Offset(r.right + 5, r.bottom),
      );
    }

    final targetRect = _tileRect(idx);
    if (targetRect == null) return null;

    // Check for a left neighbour on the same row.
    if (idx > 0) {
      final prevRect = _tileRect(idx - 1);
      if (prevRect != null &&
          (prevRect.center.dy - targetRect.center.dy).abs() < 4) {
        // Same row: vertical line in the gap between the two tiles.
        final x = (prevRect.right + targetRect.left) / 2;
        final top = prevRect.top < targetRect.top
            ? prevRect.top
            : targetRect.top;
        final bottom = prevRect.bottom > targetRect.bottom
            ? prevRect.bottom
            : targetRect.bottom;
        return _InsertionLineInfo(
          start: Offset(x, top),
          end: Offset(x, bottom),
        );
      }
    }

    // First tile on a row (or idx == 0): vertical line to its left.
    return _InsertionLineInfo(
      start: Offset(targetRect.left - 5, targetRect.top),
      end: Offset(targetRect.left - 5, targetRect.bottom),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  static const double _crossAxisSpacing = 12;

  @override
  Widget build(BuildContext context) {
    final lineInfo = _reorderable ? _insertionLineInfo() : null;

    // The stable grid — never mutated during a drag.
    Widget gridContent = SingleChildScrollView(
      padding: widget.padding,
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: _crossAxisSpacing,
        children: _buildTiles(),
      ),
    );

    if (!_reorderable) return gridContent;

    // Wrap in a full-area DragTarget so pointer events reach us everywhere.
    final dragTarget = DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onMove: _onDragUpdate,
      onLeave: (_) {
        if (_insertionIndex != null) {
          setState(() => _insertionIndex = null);
        }
      },
      onAcceptWithDetails: (details) => _onAccept(details.data),
      builder: (_, _, _) => gridContent,
    );

    return Stack(
      key: _gridKey,
      children: [
        dragTarget,
        // Insertion-line overlay — pointer events pass through.
        if (lineInfo != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _InsertionLinePainter(
                  info: lineInfo,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTiles() {
    return [for (var i = 0; i < widget.blocks.length; i++) _buildTile(i)];
  }

  Widget _buildTile(int index) {
    final block = widget.blocks[index];

    final card = BlockCard(
      topRight: widget.cardTrailing?.call(block, index),
      child: BlockWidget(
        key: ValueKey(block.id),
        data: block,
        mode: widget.mode,
        onChanged: widget.onBlockChanged,
        onJumpToDate: widget.onJumpToDate,
        onInteractionLockChanged: widget.onInteractionLockChanged,
      ),
    );

    Widget content = card;

    if (_reorderable) {
      // Feedback widget shown under the finger/cursor while dragging.
      // We use a LayoutBuilder so the feedback matches the actual tile size.
      final feedback = _DraggableFeedback(
        tileKey: _tileKeys[index],
        child: BlockCard(
          child: BlockWidget(data: block, mode: BlockMode.readOnly),
        ),
      );

      content = LongPressDraggable<int>(
        data: index,
        onDragStarted: _onDragStarted,
        onDragEnd: (_) => _onDragEnd(),
        onDraggableCanceled: (_, _) => _onDragEnd(),
        feedback: feedback,
        // Dim the source tile; it stays in place (no grid reflow).
        childWhenDragging: Opacity(opacity: 0.35, child: card),
        child: card,
      );
    }

    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1,
      key: _tileKeys[index],
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widget: sizes the drag feedback to match the source tile exactly.
// ---------------------------------------------------------------------------

class _DraggableFeedback extends StatelessWidget {
  const _DraggableFeedback({required this.tileKey, required this.child});

  final GlobalKey tileKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = tileKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(160, 160);

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Opacity(opacity: 0.85, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insertion line data + painter
// ---------------------------------------------------------------------------

class _InsertionLineInfo {
  const _InsertionLineInfo({required this.start, required this.end});
  final Offset start;
  final Offset end;
}

class _InsertionLinePainter extends CustomPainter {
  const _InsertionLinePainter({required this.info, required this.color});

  final _InsertionLineInfo info;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(info.start, info.end, linePaint);

    // Notion-style dot caps at each end of the line.
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(info.start, 4, dotPaint);
    canvas.drawCircle(info.end, 4, dotPaint);
  }

  @override
  bool shouldRepaint(_InsertionLinePainter old) =>
      old.info.start != info.start ||
      old.info.end != info.end ||
      old.color != color;
}
