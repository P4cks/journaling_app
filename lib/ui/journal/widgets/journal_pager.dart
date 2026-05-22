import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/entry_section.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_section/text_section_widget.dart';
import 'package:journaling_app_rewrite/ui/journal/view_model/main_journal_view_model.dart';

/// Horizontal pager over the user's entries (sorted ascending). The
/// page index is kept in sync with the view-model's `selectedDate`:
///
/// * Calendar selection → screen calls `vm.setSelectedDate` → this
///   widget animates to the corresponding page.
/// * Swipe → page change → `onPageChanged` calls `vm.setSelectedDate`
///   so the calendar follows.
///
/// Each page renders the entry's sections vertically: text sections
/// flow as full-width `TextSectionWidget`s, block-grid sections render
/// as non-scrolling `BlockGrid`s. The whole stack scrolls together in
/// a single outer scroll view.
///
/// Nested `PageView` carousels in mood/weather blocks would normally
/// fight this pager for horizontal drags. The blocks report their
/// "expanded" state via `onInteractionLockChanged`; while the lock-set
/// is non-empty this pager switches to `NeverScrollableScrollPhysics`
/// so the inner carousel wins.
class JournalPager extends StatefulWidget {
  const JournalPager({
    super.key,
    required this.viewModel,
    required this.modeFor,
    this.externalLock = false,
    this.editingBlockId,
    this.onRequestBlockEdit,
    this.onRequestTextSectionEdit,
    this.onRequestExitEdit,
  });

  final MainJournalViewModel viewModel;
  final BlockMode Function(JournalEntry entry) modeFor;

  /// When true, the pager disables its horizontal swipe physics even
  /// if no inner carousel is expanded. Used by the screen to lock the
  /// pager while a TextField (block or title) is being edited — the
  /// AppBar collapses to a Done button in the same state, so the only
  /// way out of edit mode is the Done tap.
  final bool externalLock;

  /// Id of the block currently in in-place edit mode (when the
  /// "expand on edit" setting is OFF). Forwarded to every `BlockGrid`
  /// + `TextSectionWidget` so the matching widget can render the
  /// edit-mode affordance and become interactive.
  final String? editingBlockId;

  /// Fired when the user double-taps an editable grid (or feature)
  /// block. The hosting screen routes it to push the expanded route or
  /// set `editingBlockId` for in-place editing.
  final ValueChanged<JournalBlockData>? onRequestBlockEdit;

  /// Fired when the user double-taps a full-width text section. Same
  /// dispatch contract as [onRequestBlockEdit] but the screen sets
  /// `isTextSection: true` on the route push so it lays out wider.
  final ValueChanged<JournalBlockData>? onRequestTextSectionEdit;

  /// Fired when a carousel auto-collapses after 1.5 s of inactivity
  /// in in-place edit mode. The host clears `_editingBlockId` so the
  /// outline disappears in lock-step.
  final VoidCallback? onRequestExitEdit;

  @override
  State<JournalPager> createState() => _JournalPagerState();
}

class _JournalPagerState extends State<JournalPager> {
  late PageController _controller;
  int _activeIndex = 0;
  final Set<String> _lockedBlockIds = <String>{};
  bool _lockRebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    _activeIndex =
        widget.viewModel.pageIndexForDate(widget.viewModel.selectedDate) ?? 0;
    _controller = PageController(initialPage: _activeIndex);
  }

  @override
  void didUpdateWidget(covariant JournalPager old) {
    super.didUpdateWidget(old);
    _pruneLocksForCurrentEntry();
    final target = widget.viewModel.pageIndexForDate(
      widget.viewModel.selectedDate,
    );
    if (target != null && target != _activeIndex) {
      _activeIndex = target;
      // Defer until after build to avoid re-entrant setState during
      // notifyListeners.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        _controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLockChanged(String blockId, bool locked) {
    if (!mounted) return;
    final wasLocked = _lockedBlockIds.isNotEmpty;
    if (locked) {
      _lockedBlockIds.add(blockId);
    } else {
      _lockedBlockIds.remove(blockId);
    }
    final isLocked = _lockedBlockIds.isNotEmpty;
    if (wasLocked != isLocked) {
      _scheduleLockRebuild();
    }
  }

  void _scheduleLockRebuild() {
    if (_lockRebuildScheduled) return;
    _lockRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lockRebuildScheduled = false;
      setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _pruneLocksForCurrentEntry() {
    if (_lockedBlockIds.isEmpty) return;
    final target = widget.viewModel.pageIndexForDate(
      widget.viewModel.selectedDate,
    );
    if (target == null) {
      _lockedBlockIds.clear();
      return;
    }

    final visibleBlockIds = <String>{
      for (final section in widget.viewModel.entries[target].sections)
        for (final block in section.blocks) block.id,
    };
    _lockedBlockIds.removeWhere((id) => !visibleBlockIds.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.viewModel.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    final pagerLocked = _lockedBlockIds.isNotEmpty || widget.externalLock;
    return PageView.builder(
      controller: _controller,
      itemCount: entries.length,
      physics: pagerLocked ? const NeverScrollableScrollPhysics() : null,
      onPageChanged: (index) {
        _activeIndex = index;
        widget.viewModel.setSelectedDate(entries[index].date);
      },
      itemBuilder: (context, index) {
        final entry = entries[index];
        final mode = widget.modeFor(entry);
        if (entry.sections.isEmpty) {
          return _EmptyBlocksMessage();
        }
        return _SectionsBody(
          sections: entry.sections,
          mode: mode,
          onBlockChanged: mode == BlockMode.editable
              ? widget.viewModel.updateBlock
              : null,
          onJumpToDate: (date) => widget.viewModel.setSelectedDate(date),
          onLockChanged: mode == BlockMode.editable ? _onLockChanged : null,
          editingBlockId: widget.editingBlockId,
          onRequestBlockEdit: mode == BlockMode.editable
              ? widget.onRequestBlockEdit
              : null,
          onRequestTextSectionEdit: mode == BlockMode.editable
              ? widget.onRequestTextSectionEdit
              : null,
          onRequestExitEdit: mode == BlockMode.editable
              ? widget.onRequestExitEdit
              : null,
        );
      },
    );
  }
}

class _SectionsBody extends StatelessWidget {
  const _SectionsBody({
    required this.sections,
    required this.mode,
    required this.onJumpToDate,
    this.onBlockChanged,
    this.onLockChanged,
    this.editingBlockId,
    this.onRequestBlockEdit,
    this.onRequestTextSectionEdit,
    this.onRequestExitEdit,
  });

  final List<EntrySection> sections;
  final BlockMode mode;
  final ValueChanged<DateTime> onJumpToDate;
  final ValueChanged<JournalBlockData>? onBlockChanged;
  final void Function(String, bool)? onLockChanged;
  final String? editingBlockId;
  final ValueChanged<JournalBlockData>? onRequestBlockEdit;
  final ValueChanged<JournalBlockData>? onRequestTextSectionEdit;
  final VoidCallback? onRequestExitEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final section in sections) _buildSection(section)],
      ),
    );
  }

  Widget _buildSection(EntrySection section) {
    switch (section.kind) {
      case SectionKind.text:
        // Text sections are materialized as exactly one textBlock; if
        // somehow malformed, fall back to a placeholder.
        if (section.blocks.isEmpty) return const SizedBox.shrink();
        final block = section.blocks.first;
        // Hero-wraps the section so the expanded route can morph from
        // here. Material is required for the Hero flight (see
        // BlockGrid's Hero comment). Double-tap is wired by the text
        // section widget itself via `DelayedTapFocus`.
        return Hero(
          tag: blockHeroTag(block.id),
          child: Material(
            type: MaterialType.transparency,
            child: TextSectionWidget(
              key: ValueKey(section.id),
              data: block,
              mode: mode,
              onChanged: onBlockChanged,
              onDoubleTap: mode == BlockMode.editable
                  ? () => onRequestTextSectionEdit?.call(block)
                  : null,
            ),
          ),
        );
      case SectionKind.blockGrid:
        // Suppress empty block-grid sections so a layout that materialized
        // with zero blocks (e.g. a kind-B layout saved with no filled
        // slots) doesn't leave awkward padding in the entry.
        if (section.blocks.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: BlockGrid(
            key: ValueKey(section.id),
            blocks: section.blocks,
            mode: mode,
            scrollable: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onBlockChanged: onBlockChanged,
            onJumpToDate: onJumpToDate,
            onInteractionLockChanged: onLockChanged,
            editingBlockId: editingBlockId,
            onRequestBlockEdit: onRequestBlockEdit,
            onRequestExitEdit: onRequestExitEdit,
          ),
        );
      case SectionKind.featureBlock:
        // A single 2×2 block — full body width, square aspect ratio.
        // Suppress empty feature sections (no template) so nothing
        // renders in entries created before the slot was filled.
        if (section.blocks.isEmpty) return const SizedBox.shrink();
        final block = section.blocks.first;
        final canDoubleTap =
            mode == BlockMode.editable &&
            onRequestBlockEdit != null &&
            block.type.usesEditMode;
        final feature = AspectRatio(
          aspectRatio: 1,
          child: Hero(
            tag: blockHeroTag(block.id),
            child: Material(
              // Hero-flight Material ancestor (see block_grid.dart).
              type: MaterialType.transparency,
              child: BlockChrome(
                visuals: block.visuals,
                child: BlockWidget(
                  key: ValueKey(section.id),
                  data: block,
                  mode: mode,
                  onChanged: onBlockChanged,
                  onJumpToDate: onJumpToDate,
                  onInteractionLockChanged: onLockChanged,
                  onDoubleTap: canDoubleTap
                      ? () => onRequestBlockEdit!(block)
                      : null,
                ),
              ),
            ),
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: feature,
        );
    }
  }
}

class _EmptyBlocksMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No blocks for this day yet',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.disabledColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
