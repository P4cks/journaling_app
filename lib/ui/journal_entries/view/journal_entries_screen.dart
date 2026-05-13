import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';
import 'package:journaling_app_rewrite/ui/core/streak_stat_card.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';
import 'package:journaling_app_rewrite/ui/journal_entries/view_model/journal_entries_view_model.dart';
import 'package:journaling_app_rewrite/ui/journal_entries/widgets/entry_list_tile.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  JournalEntriesViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = JournalEntriesViewModel(repository: deps.journalRepository);
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
      appBar: AppBar(title: const Text('Entries')),
      body: vm.isEmpty
          ? const _EmptyState()
          : _SectionedList(sections: vm.sections),
    );
  }
}

class _SectionedList extends StatelessWidget {
  const _SectionedList({required this.sections});
  final List<MonthSection> sections;

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SectionHeader(label: 'Streak')),
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: deps.journalRepository,
            builder: (context, _) => StreakStatCard(
              streak: computeStreak(deps.journalRepository.getAllEntries()),
            ),
          ),
        ),
        for (final section in sections) ...[
          SliverToBoxAdapter(child: _MonthHeader(section: section)),
          SliverList.builder(
            itemCount: section.entries.length,
            itemBuilder: (context, index) {
              final entry = section.entries[index];
              return EntryListTile(
                entry: entry,
                onTap: () => context.push(Routes.journalEntryFor(entry.date)),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.section});

  final MonthSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        formatMonthHeader(section.year, section.month),
        style: theme.textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              PhosphorIconsDuotone.bookOpen,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('No entries yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Make your first entry from the home screen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
