import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

/// Where a block is being rendered.
///
/// The pair `(BlockHostKind, BlockEditState)` replaces the older
/// `BlockMode` + per-widget `editing` plumbing. Every concrete block
/// body switches on this pair (plus [BlockRenderContext.readOnly] for
/// past-day entries) to decide what to render.
enum BlockHostKind {
  /// Block is rendered inside a `BlockGrid` cell (or as a
  /// `SectionKind.text` / `SectionKind.featureBlock` section in the
  /// journal pager).
  grid,

  /// Block is rendered inside the full-screen `ExpandedBlockRoute`.
  expanded,
}

/// Whether the block content is inert-display or live-interactive.
///
/// Display means no controllers, no focus, no picker — just the
/// rendered content (text, emoji, image, map snapshot). Editing means
/// the inner widgets are wired up and reachable: `TextField`s with
/// controllers, carousels with `PageView`, photo "+ Add photo"
/// tappable, etc.
enum BlockEditState { display, editing }

/// Immutable bundle of everything a block body needs to render.
///
/// One parameter per body widget, instead of the previous explosion
/// of `mode` / `editing` / `onChanged` / `onJumpToDate` / `onInteractionLockChanged`
/// arguments at every call site.
@immutable
class BlockRenderContext {
  const BlockRenderContext({
    required this.data,
    required this.host,
    required this.state,
    this.readOnly = false,
    this.onChanged,
    this.onJumpToDate,
    this.onInteractionLockChanged,
    this.onRequestExitEdit,
  });

  /// The block's persisted data + visuals.
  final JournalBlockData data;

  /// Where this body is being rendered.
  final BlockHostKind host;

  /// Whether the body should render its interactive form or just
  /// display the content.
  final BlockEditState state;

  /// True when the parent journal entry is itself read-only (past day,
  /// no `unlockAllDays` debug). Concrete bodies should suppress every
  /// editing affordance when this is true, regardless of [state].
  final bool readOnly;

  /// Per-keystroke / per-pick save target. Carried through to
  /// `MainJournalViewModel.updateBlock`.
  final ValueChanged<JournalBlockData>? onChanged;

  /// For the memory block: jump to a past entry.
  final ValueChanged<DateTime>? onJumpToDate;

  /// For carousels: lock the outer pager while the inner PageView is
  /// expanded. Only meaningful in `host == grid` because expanded
  /// route blocks the pager underneath anyway.
  final void Function(String blockId, bool locked)? onInteractionLockChanged;

  /// For carousels in in-place editing: signal the host to drop
  /// `_editingBlockId` when the 1.5 s collapse timer fires. Lets the
  /// outline disappear in lock-step with the carousel collapsing.
  final VoidCallback? onRequestExitEdit;

  /// Convenience accessors.
  bool get isExpanded => host == BlockHostKind.expanded;
  bool get isGrid => host == BlockHostKind.grid;
  bool get isEditing => state == BlockEditState.editing && !readOnly;
  bool get isDisplay => !isEditing;

  /// Copy with a new render-state. The expanded route uses this to
  /// flip the inner body between display and editing without
  /// rebuilding the whole context.
  BlockRenderContext withState(BlockEditState newState) {
    if (newState == state) return this;
    return BlockRenderContext(
      data: data,
      host: host,
      state: newState,
      readOnly: readOnly,
      onChanged: onChanged,
      onJumpToDate: onJumpToDate,
      onInteractionLockChanged: onInteractionLockChanged,
      onRequestExitEdit: onRequestExitEdit,
    );
  }

  /// Copy with a new `data`. Used by the expanded route when the
  /// inner body emits an update — we forward to the host VM AND
  /// rebuild the route with the fresh data so live-state widgets
  /// (carousels, photos) reflect the pick.
  BlockRenderContext withData(JournalBlockData newData) {
    return BlockRenderContext(
      data: newData,
      host: host,
      state: state,
      readOnly: readOnly,
      onChanged: onChanged,
      onJumpToDate: onJumpToDate,
      onInteractionLockChanged: onInteractionLockChanged,
      onRequestExitEdit: onRequestExitEdit,
    );
  }
}
