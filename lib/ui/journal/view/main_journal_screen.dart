import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/expanded/expanded_block_route.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/journal/view_model/main_journal_view_model.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/calendar_bottom_bar.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/journal_pager.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/journal_title.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/make_entry_cta.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/no_entry_read_only.dart';
import 'package:journaling_app_rewrite/ui/journal/widgets/profile_menu_button.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_picker_sheet.dart';

/// The merged main screen. Hosts the AppBar (editable title + date
/// subtitle + Change-layout / Entries / Profile actions), the swipe
/// pager over existing entries, the empty-day CTA / read-only states,
/// and the sticky calendar bar at the bottom.
class MainJournalScreen extends StatefulWidget {
  const MainJournalScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<MainJournalScreen> createState() => _MainJournalScreenState();
}

class _MainJournalScreenState extends State<MainJournalScreen>
    with WidgetsBindingObserver {
  MainJournalViewModel? _viewModel;

  /// True when the on-screen keyboard is up. Drives the "modal editing"
  /// AppBar (only a Done button) and locks the journal pager swipe.
  /// Updated from [didChangeMetrics] because [MediaQuery.viewInsetsOf]
  /// inside the Scaffold's body returns zero — Scaffold's
  /// `resizeToAvoidBottomInset` consumes the bottom insets before they
  /// reach descendants.
  bool _editing = false;

  /// True while the expanded-block route is on the navigator stack. The
  /// route's inner TextField raises the keyboard, but we don't want
  /// `_editing` to flip and collapse the (hidden) AppBar to Done —
  /// because as the route closes, the keyboard takes ~250 ms to slide
  /// down while the route fades out in 220 ms, leaving the AppBar's
  /// Done button briefly visible during the gap. Suppressing
  /// [didChangeMetrics]'s keyboard tracking for the route's lifetime
  /// avoids the flash.
  bool _expandedRouteOpen = false;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = MainJournalViewModel(
        journalRepository: deps.journalRepository,
        layoutRepository: deps.layoutRepository,
        initialDate: widget.initialDate,
      );
      _viewModel!.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel?.removeListener(_onChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // The expanded route owns the keyboard while it's up — don't let
    // its TextField focus flip our AppBar to Done (which would then
    // briefly flash as the route closes; see [_expandedRouteOpen]).
    if (_expandedRouteOpen) return;
    final bottomInsets = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    final keyboardUp = bottomInsets > 0;
    if (keyboardUp != _editing) {
      setState(() => _editing = keyboardUp);
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onDone() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Called from the journal pager when the user **double-taps** an
  /// editable block. Single tap is handled inline by each block
  /// widget (focuses the TextField, expands the carousel, etc.) — see
  /// [DoubleTapListener] for why both gestures coexist without arena
  /// conflicts.
  ///
  /// Pushes [ExpandedBlockRoute]. Edit state lives inside the route.
  /// The text-section variant sets `isTextSection: true` so the route
  /// renders the section text directly on the blur (no card chrome).
  void _requestBlockEdit(JournalBlockData block, {bool isTextSection = false}) {
    final vm = _viewModel;
    // The single tap that preceded this double tap may have already
    // focused a field — unfocus so the keyboard isn't dangling when
    // the route opens (the route's own field is unfocused initially
    // by design; user taps inside to start editing there).
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _expandedRouteOpen = true);
    Navigator.of(context)
        .push(
          ExpandedBlockRoute(
            data: block,
            onChanged: vm?.updateBlock,
            onJumpToDate: vm?.setSelectedDate,
            isTextSection: isTextSection,
          ),
        )
        .whenComplete(() {
          if (!mounted) return;
          // Drop the lock and re-sync `_editing` to the actual
          // keyboard state (it stayed frozen while the route was up).
          final bottomInsets = WidgetsBinding
              .instance
              .platformDispatcher
              .views
              .first
              .viewInsets
              .bottom;
          setState(() {
            _expandedRouteOpen = false;
            _editing = bottomInsets > 0;
          });
        });
  }

  Future<void> _onMakeEntry() async {
    final vm = _viewModel;
    if (vm == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showLayoutPickerSheet(
      context,
      layouts: vm.getAvailableLayouts(),
    );
    if (picked == null || !mounted) return;
    vm.createWithLayout(picked);
  }

  /// Destructive — replaces the current entry's blocks. Always confirm.
  Future<void> _showChangeLayoutSheet() async {
    final vm = _viewModel;
    if (vm == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showLayoutPickerSheet(
      context,
      layouts: vm.getAvailableLayouts(),
    );
    if (selected == null || !mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply layout?'),
        content: Text(
          'This will replace the current blocks with "${selected.name}". '
          'Existing content for this day will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) vm.applyLayout(selected);
  }

  Future<void> _openStatistics() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(Routes.statistics);
    if (mounted) FocusManager.instance.primaryFocus?.unfocus();
  }

  BlockMode _modeFor(JournalEntry entry, {required bool unlockAllDays}) {
    final editable = _isToday(entry.date) || unlockAllDays;
    return editable ? BlockMode.editable : BlockMode.readOnly;
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold();

    final debug = AppDependencies.of(context).debugSettings;

    return ListenableBuilder(
      listenable: debug,
      builder: (context, _) {
        final selectedDate = vm.selectedDate;
        final entry = vm.currentEntry;
        final hasEntry = entry != null;
        final editable = _isToday(selectedDate) || debug.unlockAllDays;
        final scheme = Theme.of(context).colorScheme;

        // While the keyboard is up the AppBar collapses to a single
        // Done action and the pager swipe is disabled — so editing a
        // block (or the title) can't accidentally navigate away.
        final List<Widget> appBarActions = _editing
            ? [
                TextButton(
                  onPressed: _onDone,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.primary,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Done'),
                ),
                const SizedBox(width: 4),
              ]
            : [
                if (editable && hasEntry)
                  IconButton(
                    tooltip: 'Change layout',
                    onPressed: _showChangeLayoutSheet,
                    icon: AppIcon(HugeIcons.strokeRoundedGrid),
                  )
                else if (!editable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Tooltip(
                      message: 'Past entries are read-only',
                      child: AppIcon(
                        HugeIcons.strokeRoundedLock,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                IconButton(
                  tooltip: 'Statistics',
                  onPressed: _openStatistics,
                  icon: AppIcon(HugeIcons.strokeRoundedChartBarLine),
                ),
                const ProfileMenuButton(),
              ];

        return Scaffold(
          appBar: AppBar(
            title: JournalTitle(
              date: selectedDate,
              title: entry?.title,
              editable: editable,
              hasEntry: hasEntry,
              onChanged: vm.updateTitle,
            ),
            actions: appBarActions,
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _editing
                ? null
                : () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Material(
              color: scheme.surfaceContainerLow,
              child: SizedBox.expand(
                child: hasEntry
                    ? JournalPager(
                        viewModel: vm,
                        modeFor: (e) =>
                            _modeFor(e, unlockAllDays: debug.unlockAllDays),
                        externalLock: _editing,
                        onRequestBlockEdit: (block) => _requestBlockEdit(block),
                        onRequestTextSectionEdit: (block) =>
                            _requestBlockEdit(block, isTextSection: true),
                        onReorderBlockInSection: vm.reorderBlockInSection,
                      )
                    : (editable
                          ? MakeEntryCta(onTap: _onMakeEntry)
                          : const NoEntryReadOnly()),
              ),
            ),
          ),
          bottomNavigationBar: CalendarBottomBar(
            selectedDate: selectedDate,
            entriesByDay: vm.entriesByDay,
            onDateSelected: vm.setSelectedDate,
          ),
        );
      },
    );
  }
}
