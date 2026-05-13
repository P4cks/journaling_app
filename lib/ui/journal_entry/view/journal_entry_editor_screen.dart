import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/journal_entry_view.dart'
    show journalEntryHeroTag;
import 'package:journaling_app_rewrite/ui/home/widgets/make_entry_cta.dart';
import 'package:journaling_app_rewrite/ui/journal_entry/view_model/journal_entry_editor_view_model.dart';
import 'package:journaling_app_rewrite/ui/journal_entry/widgets/editor_title.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_picker_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class JournalEntryEditorScreen extends StatefulWidget {
  const JournalEntryEditorScreen({super.key, required this.date});

  final DateTime date;

  @override
  State<JournalEntryEditorScreen> createState() =>
      _JournalEntryEditorScreenState();
}

class _JournalEntryEditorScreenState extends State<JournalEntryEditorScreen> {
  JournalEntryEditorViewModel? _viewModel;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isToday => _isSameDay(widget.date, DateTime.now());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = JournalEntryEditorViewModel(
        repository: deps.journalRepository,
        layoutRepository: deps.layoutRepository,
        date: widget.date,
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

  /// Editor's "Change layout" action — destructive (replaces existing
  /// blocks), so always confirms before applying.
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
    if (confirm == true && mounted) {
      vm.applyLayout(selected);
    }
  }

  /// Editor's CTA when reached via deep link to a date without an entry.
  /// Non-destructive — there's nothing to replace, so no confirm dialog.
  Future<void> _onMakeEntry() async {
    final vm = _viewModel;
    if (vm == null) return;
    final selected = await showLayoutPickerSheet(
      context,
      layouts: vm.getAvailableLayouts(),
    );
    if (selected == null || !mounted) return;
    vm.createWithLayout(selected);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold();

    final debug = AppDependencies.of(context).debugSettings;

    return ListenableBuilder(
      listenable: debug,
      builder: (context, _) {
        final editable = _isToday || debug.unlockAllDays;
        final entry = vm.entry;
        final hasEntry = entry != null;
        final blocks = entry?.widgets ?? const [];
        final scheme = Theme.of(context).colorScheme;
        // No more explicit edit-mode toggle: when the day is editable
        // (today or debug-unlocked) and an entry exists, blocks render
        // directly editable. Past days stay read-only.
        final mode = (editable && hasEntry)
            ? BlockMode.editable
            : BlockMode.readOnly;

        return Scaffold(
          appBar: AppBar(
            title: hasEntry
                ? EditorTitle(
                    title: entry.title,
                    date: widget.date,
                    editable: editable,
                    onChanged: vm.updateTitle,
                  )
                : Text(formatEntryDate(widget.date)),
            titleSpacing: hasEntry ? 0 : null,
            actions: [
              if (editable && hasEntry)
                IconButton(
                  tooltip: 'Change layout',
                  onPressed: _showChangeLayoutSheet,
                  icon: const AppIcon(PhosphorIconsDuotone.squaresFour),
                )
              else if (!editable)
                const Tooltip(
                  message: 'Past entries are read-only',
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: AppIcon(PhosphorIconsDuotone.lock),
                  ),
                ),
            ],
          ),
          body: Hero(
            tag: journalEntryHeroTag,
            child: Material(
              color: scheme.surfaceContainerLow,
              child: SizedBox.expand(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: !hasEntry
                      ? (editable
                            ? MakeEntryCta(onTap: _onMakeEntry)
                            : _NoEntryReadOnly())
                      : blocks.isEmpty
                      ? Center(
                          child: Text(
                            'No blocks for this day yet',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).disabledColor,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        )
                      : BlockGrid(
                          blocks: blocks,
                          mode: mode,
                          onBlockChanged: vm.updateBlock,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoEntryReadOnly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No entry was made on this day.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
