import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/streak_stat_card.dart';
import 'package:journaling_app_rewrite/ui/statistics/view_model/statistics_view_model.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/entry_frequency_chart.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/mood_distribution_chart.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/mood_over_time_chart.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/stat_range_selector.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/stats_empty_state.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/streak_reward_card.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/summary_numbers_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsViewModel? _viewModel;
  SubscriptionRepository? _subscriptions;
  StreakRewardSettings? _rewards;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _subscriptions = deps.subscriptionRepository;
      _rewards = deps.streakRewardSettings;
      _viewModel = StatisticsViewModel(repository: deps.journalRepository);
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

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _subscriptions!,
              builder: (context, _) => StatRangeSelector(
                value: vm.range,
                onChanged: vm.setRange,
                subscriptions: _subscriptions!,
              ),
            ),
          ),
          if (vm.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: StatsEmptyState(),
            )
          else ...[
            SliverToBoxAdapter(
              child: SummaryNumbersCard(
                totalEntries: vm.totalEntries,
                totalWords: vm.totalWords,
                totalMoodEntries: vm.totalMoodEntries,
                currentStreak: vm.streak.current,
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(label: 'Streak')),
            SliverToBoxAdapter(child: StreakStatCard(streak: vm.streak)),
            SliverToBoxAdapter(
              child: ListenableBuilder(
                listenable: _rewards!,
                builder: (context, _) => StreakRewardCard(
                  streak: vm.streak,
                  rewards: _rewards!,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(label: 'Mood')),
            SliverToBoxAdapter(
              child: MoodDistributionChart(distribution: vm.moodDistribution),
            ),
            SliverToBoxAdapter(
              child: MoodOverTimeChart(points: vm.moodOverTime),
            ),
            const SliverToBoxAdapter(child: SectionHeader(label: 'Frequency')),
            SliverToBoxAdapter(
              child: EntryFrequencyChart(
                buckets: vm.entryFrequency,
                granularity: vm.entryFrequencyGranularity,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}
