import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/journal/view_model/main_journal_view_model.dart';

/// Horizontal pager over the user's entries (sorted ascending). The
/// page index is kept in sync with the view-model's `selectedDate`:
///
/// * Calendar selection → screen calls `vm.setSelectedDate` → this
///   widget animates to the corresponding page.
/// * Swipe → page change → `onPageChanged` calls `vm.setSelectedDate`
///   so the calendar follows.
///
/// Pages render the existing `BlockGrid`. The screen decides which
/// mode (editable / readOnly) to apply per page based on the entry's
/// date vs today.
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
  });

  final MainJournalViewModel viewModel;
  final BlockMode Function(JournalEntry entry) modeFor;

  @override
  State<JournalPager> createState() => _JournalPagerState();
}

class _JournalPagerState extends State<JournalPager> {
  late PageController _controller;
  int _activeIndex = 0;
  final Set<String> _lockedBlockIds = <String>{};

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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.viewModel.entries;
    if (entries.isEmpty) return const SizedBox.shrink();
    final pagerLocked = _lockedBlockIds.isNotEmpty;
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
        if (entry.widgets.isEmpty) {
          return _EmptyBlocksMessage();
        }
        return BlockGrid(
          blocks: entry.widgets,
          mode: mode,
          onBlockChanged: mode == BlockMode.editable
              ? widget.viewModel.updateBlock
              : null,
          onJumpToDate: (date) => widget.viewModel.setSelectedDate(date),
          onInteractionLockChanged: mode == BlockMode.editable
              ? _onLockChanged
              : null,
        );
      },
    );
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
