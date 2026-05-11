import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/home_calendar.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/journal_entry_view.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/make_entry_cta.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/streak_pill.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_picker_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = HomeViewModel(journalRepository: deps.journalRepository);
      _viewModel!.addListener(_onViewModelChanged);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openEditor(HomeViewModel vm) async {
    final path = Routes.journalEntryFor(vm.selectedDate);
    debugPrint('[HomeScreen] opening editor at $path');
    await context.push(path);
    if (!mounted) return;
    // Sweep on editor-pop catches the "user cleared all blocks on a past
    // day" case immediately. Cheap — entries are few.
    await AppDependencies.of(context).journalRepository
        .sweepEmptyPastEntries();
    if (!mounted) return;
    vm.reload();
  }

  Future<void> _onMakeEntry(HomeViewModel vm) async {
    final deps = AppDependencies.of(context);
    final layouts = deps.layoutRepository.getAll();
    final picked = await showLayoutPickerSheet(context, layouts: layouts);
    if (picked == null || !mounted) return;
    vm.createEntryWithLayout(picked);
    if (!mounted) return;
    await _openEditor(vm);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const SizedBox.shrink();

    final streak = vm.streak;
    final showPill = streak.current > 0 || streak.longest > 0;

    return SafeArea(
      child: Column(
        children: [
          if (showPill)
            StreakPill(
              streak: streak,
              onTap: () => context.go(Routes.journalEntries),
            ),
          HomeCalendar(viewModel: vm),
          Expanded(
            child: vm.currentEntry == null
                ? MakeEntryCta(onTap: () => _onMakeEntry(vm))
                : JournalEntryView(
                    entry: vm.currentEntry,
                    onTap: () => _openEditor(vm),
                  ),
          ),
        ],
      ),
    );
  }
}
