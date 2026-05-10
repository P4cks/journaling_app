import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/home/view_model/home_view_model.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/home_calendar.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/journal_entry_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _viewModel = HomeViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: HomeCalendar(viewModel: _viewModel),
          ),
          Expanded(
            child: JournalEntryView(date: _viewModel.selectedDate),
          ),
        ],
      ),
    );
  }
}
