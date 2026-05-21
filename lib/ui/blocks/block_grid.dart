import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';

// ---------------------------------------------------------------------------
// BlockGrid — Notion-style drag-to-reorder with Hero-ready tiles.
//
// Layout invariants:
//  • Grid is never mutated during drag (no ghost tiles, no reflow).
//  • A single DragTarget wraps the area; an insertion-line overlay shows
//    the drop point.
//  • Tile RenderBoxes stay axis-aligned — the rotation/offset in
//    `BlockChrome` are visual only, so the insertion-index math is safe.
//
// Motion layered on top:
//  • Dragging tile scales to 1.03 with stronger shadow (via `BlockChrome`).
//  • Newly-added tiles fade + scale in (flutter_animate, keyed by block id).
//  • Deleted tiles animate out via an overlay "ghost" rendered above the
//    grid using the tile's last known bounds; ghosts are cleaned up after
//    their animation finishes.
//  • Motion is INDEPENDENT of the `themeSettings.postItModeEnabled`
//    theming flag — post-it is pure visuals only (see
//    [chrome/block_chrome.dart](chrome/block_chrome.dart) docstring).
//
// Hero:
//  • Each tile's content is wrapped in `Hero(tag: 'block-${data.id}')`
//    so the `ExpandedBlockRoute` can morph between this in-grid tile
//    and the full-screen view. Drag feedback and delete ghosts do NOT
//    wrap in Hero (they're transient same-route widgets and would
//    collide on tag uniqueness).
// ---------------------------------------------------------------------------

/// Hero tag used by both the in-grid tile (source) and the
/// `ExpandedBlockRoute` (destination). Centralised so both call sites
/// stay in lock-step.
String blockHeroTag(String blockId) => 'block-$blockId';

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
    this.scrollable = true,
    this.onBlockTap,
    this.editingBlockId,
    this.onRequestBlockEdit,
    this.onRequestExitEdit,
  });

  final List<JournalBlockData> blocks;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onBlockChanged;
  final ValueChanged<DateTime>? onJumpToDate;
  final Widget Function(JournalBlockData block, int index)? cardTrailing;
  final void Function(int from, int to)? onReorder;
  final void Function(JournalBlockData block, String id)? onBlockTap;
  final EdgeInsets padding;
  final bool scrollable;
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  /// Id of the block currently in in-place edit mode, or null when no
  /// tile is being edited. Drives the `PostItBlock` scale + outline
  /// affordance and the inner widget's interactive state.
  final String? editingBlockId;

  /// Fires when the user double-taps a tile whose [BlockType] opts into
  /// the new edit-mode flow (`BlockTypeDisplay.usesEditMode`). The
  /// hosting screen decides whether to push an expanded-block route or
  /// just flip `editingBlockId` for in-place editing.
  ///
  /// For block types where `usesEditMode == false` (photo / location /
  /// memory / quote / weather-api), the grid does NOT attach the
  /// double-tap detector and those tiles keep their existing
  /// single-tap behavior.
  final ValueChanged<JournalBlockData>? onRequestBlockEdit;

  /// Fires when an in-place carousel auto-collapses after 1.5 s. The
  /// host clears `_editingBlockId` so the outline disappears in
  /// lock-step.
  final VoidCallback? onRequestExitEdit;

  @override
  State<BlockGrid> createState() => _BlockGridState();
}

class _BlockGridState extends State<BlockGrid> {
  int? _insertionIndex;
  int? _draggingIndex;
  List<GlobalKey> _tileKeys = const [];
  final GlobalKey _gridKey = GlobalKey();

  // Ids and last-known-rects for tiles that just got removed — rendered
  // in an overlay so we can animate them out after they leave the grid.
  final List<_PendingDelete> _pendingDeletes = [];

  bool get _reorderable => widget.onReorder != null;

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

    // Detect removals before we replace _tileKeys: snapshot the rect of
    // any disappearing block so the overlay ghost can position itself.
    final oldIds = {for (final b in old.blocks) b.id};
    final newIds = {for (final b in widget.blocks) b.id};
    final removed = oldIds.difference(newIds);
    if (removed.isNotEmpty) {
      for (var i = 0; i < old.blocks.length; i++) {
        final block = old.blocks[i];
        if (!removed.contains(block.id)) continue;
        final rect = _tileRect(i, keys: _tileKeys);
        if (rect == null) continue;
        _pendingDeletes.add(
          _PendingDelete(block: block, rect: rect, mountedAt: DateTime.now()),
        );
      }
    }

    if (widget.blocks.length != _tileKeys.length) {
      _tileKeys = _buildKeys(widget.blocks.length);
    }
  }

  Rect? _tileRect(int index, {List<GlobalKey>? keys}) {
    final keyList = keys ?? _tileKeys;
    if (index < 0 || index >= keyList.length) return null;
    final tileBox =
        keyList[index].currentContext?.findRenderObject() as RenderBox?;
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (tileBox == null || gridBox == null) return null;
    final topLeft = tileBox.localToGlobal(Offset.zero, ancestor: gridBox);
    return topLeft & tileBox.size;
  }

  int _computeInsertionIndex(Offset globalPos) {
    final gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return widget.blocks.length;

    final local = gridBox.globalToLocal(globalPos);
    final n = widget.blocks.length;
    if (n == 0) return 0;

    final centres = List<Offset?>.generate(n, (i) => _tileRect(i)?.center);

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

    final rowY = centres[closestIdx]?.dy ?? 0;
    const rowEpsilon = 4.0;
    final rowIndices = <int>[
      for (var i = 0; i < n; i++)
        if (centres[i] != null && (centres[i]!.dy - rowY).abs() < rowEpsilon) i,
    ];

    double bestDx = double.infinity;
    int nearest = closestIdx;
    for (final i in rowIndices) {
      final dx = (centres[i]!.dx - local.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        nearest = i;
      }
    }

    final cx = centres[nearest]?.dx ?? local.dx;
    return local.dx < cx ? nearest : nearest + 1;
  }

  void _onDragStarted(int index) {
    setState(() {
      _draggingIndex = index;
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
    setState(() {
      _insertionIndex = null;
      _draggingIndex = null;
    });
  }

  void _onAccept(int from) {
    final insertAt = _insertionIndex ?? widget.blocks.length;
    setState(() {
      _insertionIndex = null;
      _draggingIndex = null;
    });
    final to = insertAt > from ? insertAt - 1 : insertAt;
    if (from != to) widget.onReorder!(from, to);
  }

  _InsertionLineInfo? _insertionLineInfo() {
    final idx = _insertionIndex;
    if (idx == null) return null;
    final n = widget.blocks.length;
    if (n == 0) return null;

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

    if (idx > 0) {
      final prevRect = _tileRect(idx - 1);
      if (prevRect != null &&
          (prevRect.center.dy - targetRect.center.dy).abs() < 4) {
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

    return _InsertionLineInfo(
      start: Offset(targetRect.left - 5, targetRect.top),
      end: Offset(targetRect.left - 5, targetRect.bottom),
    );
  }

  static const double _crossAxisSpacing = 12;

  @override
  Widget build(BuildContext context) {
    final lineInfo = _reorderable ? _insertionLineInfo() : null;

    final staggered = Padding(
      padding: widget.padding,
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: _crossAxisSpacing,
        children: _buildTiles(),
      ),
    );
    final Widget gridContent = widget.scrollable
        ? SingleChildScrollView(child: staggered)
        : staggered;

    final Widget body;
    if (_reorderable) {
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

      body = Stack(
        key: _gridKey,
        children: [
          dragTarget,
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
          ..._buildGhosts(),
        ],
      );
    } else {
      body = Stack(
        key: _gridKey,
        children: [
          gridContent,
          ..._buildGhosts(),
        ],
      );
    }

    return body;
  }

  List<Widget> _buildTiles() {
    return [
      for (var i = 0; i < widget.blocks.length; i++) _buildTile(i),
    ];
  }

  Widget _buildTile(int index) {
    final block = widget.blocks[index];
    final isDragging = _draggingIndex == index;
    final usesEditMode = block.type.usesEditMode;

    final canDoubleTap =
        usesEditMode &&
        widget.onRequestBlockEdit != null &&
        widget.mode == BlockMode.editable;
    final inner = BlockWidget(
      key: ValueKey('content-${block.id}'),
      data: block,
      mode: widget.mode,
      onChanged: widget.onBlockChanged,
      onJumpToDate: widget.onJumpToDate,
      onInteractionLockChanged: widget.onInteractionLockChanged,
      onDoubleTap: canDoubleTap
          ? () => widget.onRequestBlockEdit!(block)
          : null,
    );

    // Hero source. Tag matches the destination wrapped by
    // `ExpandedBlockRoute`. Material wrapper is REQUIRED — during a
    // Hero flight the widget is rendered in the root Overlay,
    // OUTSIDE the journal screen's Material(surfaceContainerLow).
    // Without a Material ancestor inside the Hero, TextField /
    // InkWell descendants throw "No Material widget found"
    // mid-flight (and show the yellow-underline debug render).
    Widget card = Hero(
      tag: blockHeroTag(block.id),
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: widget.onBlockTap == null
              ? null
              : () => widget.onBlockTap!(block, block.id),
          child: BlockChrome(
            visuals: block.visuals,
            isDragging: isDragging,
            topRight: widget.cardTrailing?.call(block, index),
            child: inner,
          ),
        ),
      ),
    );

    // No outer gesture wrapper. Each block widget owns its own
    // `GestureDetector(onTap, onDoubleTap)` — single tap fires the
    // block's engage action after `kDoubleTapTimeout`, double tap
    // fires the `onDoubleTap` callback we passed via `BlockWidget`.
    // Uniform behaviour across all block types: no flash on double
    // tap.

    // Mount animation: scale 0.9 → 1.0 + fade. Runs once on mount,
    // keyed by block.id so re-orders don't replay it. Independent of
    // post-it theming — the animation is a structural affordance, not
    // a theme decoration.
    final tileWidget = Animate(
      key: ValueKey('animate-${block.id}'),
      effects: const [
        FadeEffect(
          duration: Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
        ScaleEffect(
          begin: Offset(0.9, 0.9),
          end: Offset(1.0, 1.0),
          duration: Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
        ),
      ],
      child: card,
    );

    Widget content = tileWidget;

    if (_reorderable) {
      final feedback = _DraggableFeedback(
        tileKey: _tileKeys[index],
        child: BlockChrome(
          visuals: block.visuals,
          isDragging: true,
          child: BlockWidget(data: block, mode: BlockMode.readOnly),
        ),
      );

      content = LongPressDraggable<int>(
        data: index,
        onDragStarted: () => _onDragStarted(index),
        onDragEnd: (_) => _onDragEnd(),
        onDraggableCanceled: (_, _) => _onDragEnd(),
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.35, child: tileWidget),
        child: tileWidget,
      );
    }

    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1,
      key: _tileKeys[index],
      child: content,
    );
  }

  // ---------------------------------------------------------------------
  // Delete overlay ghosts — rendered above the grid in the same Stack so
  // they can animate out at the tile's last known position even after
  // the source list has dropped them.
  // ---------------------------------------------------------------------

  List<Widget> _buildGhosts() {
    if (_pendingDeletes.isEmpty) return const [];
    return [
      for (final pending in List<_PendingDelete>.from(_pendingDeletes))
        Positioned(
          left: pending.rect.left,
          top: pending.rect.top,
          width: pending.rect.width,
          height: pending.rect.height,
          child: IgnorePointer(
            child: Animate(
              key: ValueKey('delete-${pending.block.id}'),
              onComplete: (_) {
                if (!mounted) return;
                setState(() {
                  _pendingDeletes.removeWhere((p) => p == pending);
                });
              },
              effects: const [
                FadeEffect(
                  begin: 1,
                  end: 0,
                  duration: Duration(milliseconds: 320),
                  curve: Curves.easeIn,
                ),
                ScaleEffect(
                  begin: Offset(1.0, 1.0),
                  end: Offset(0.7, 0.7),
                  duration: Duration(milliseconds: 320),
                  curve: Curves.easeIn,
                ),
                RotateEffect(
                  begin: 0,
                  end: 0.04,
                  duration: Duration(milliseconds: 320),
                  curve: Curves.easeIn,
                ),
                MoveEffect(
                  begin: Offset.zero,
                  end: Offset(0, 16),
                  duration: Duration(milliseconds: 320),
                  curve: Curves.easeIn,
                ),
              ],
              child: BlockChrome(
                visuals: pending.block.visuals,
                child: BlockWidget(
                  data: pending.block,
                  mode: BlockMode.readOnly,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _PendingDelete {
  _PendingDelete({
    required this.block,
    required this.rect,
    required this.mountedAt,
  });

  final JournalBlockData block;
  final Rect rect;
  final DateTime mountedAt;
}

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
        child: child,
      ),
    );
  }
}

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
