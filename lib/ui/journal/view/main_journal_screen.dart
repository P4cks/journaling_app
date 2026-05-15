import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
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
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

class _MainJournalScreenState extends State<MainJournalScreen> {
  MainJournalViewModel? _viewModel;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

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
    _viewModel?.removeListener(_onChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onMakeEntry() async {
    final vm = _viewModel;
    if (vm == null) return;
    FocusScope.of(context).unfocus();
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
    FocusScope.of(context).unfocus();
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

  void _openStatistics() {
    FocusScope.of(context).unfocus();
    context.push(Routes.statistics);
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

        return Scaffold(
          appBar: AppBar(
            title: JournalTitle(
              date: selectedDate,
              title: entry?.title,
              editable: editable,
              hasEntry: hasEntry,
              onChanged: vm.updateTitle,
            ),
            actions: [
              if (editable && hasEntry)
                IconButton(
                  tooltip: 'Change layout',
                  onPressed: _showChangeLayoutSheet,
                  icon: const AppIcon(PhosphorIconsDuotone.squaresFour),
                )
              else if (!editable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Tooltip(
                    message: 'Past entries are read-only',
                    child: AppIcon(
                      PhosphorIconsDuotone.lock,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Statistics',
                onPressed: _openStatistics,
                icon: const AppIcon(PhosphorIconsDuotone.chartBar),
              ),
              const ProfileMenuButton(),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Material(
              color: scheme.surfaceContainerLow,
              child: SizedBox.expand(
                child: hasEntry
                    ? JournalPager(
                        viewModel: vm,
                        modeFor: (e) =>
                            _modeFor(e, unlockAllDays: debug.unlockAllDays),
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
