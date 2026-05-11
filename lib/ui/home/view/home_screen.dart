import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/home_calendar.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/journal_entry_view.dart';

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
    vm.reload();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        children: [
          HomeCalendar(viewModel: vm),
          Expanded(
            child: JournalEntryView(
              entry: vm.currentEntry,
              onTap: () => _openEditor(vm),
            ),
          ),
        ],
      ),
    );
  }
}
