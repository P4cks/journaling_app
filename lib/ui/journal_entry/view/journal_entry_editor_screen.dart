import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/home/widgets/journal_entry_view.dart'
    show journalEntryHeroTag;
import 'package:journaling_app_rewrite/ui/journal_entry/view_model/journal_entry_editor_view_model.dart';

class JournalEntryEditorScreen extends StatefulWidget {
  const JournalEntryEditorScreen({super.key, required this.date});

  final DateTime date;

  @override
  State<JournalEntryEditorScreen> createState() =>
      _JournalEntryEditorScreenState();
}

class _JournalEntryEditorScreenState extends State<JournalEntryEditorScreen> {
  JournalEntryEditorViewModel? _viewModel;
  bool _isEditing = false;

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

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
      debugPrint('[EditorScreen] isEditing -> $_isEditing');
    });
  }

  Future<void> _showLayoutPicker() async {
    final vm = _viewModel;
    if (vm == null) return;
    FocusScope.of(context).unfocus();
    final layouts = vm.getAvailableLayouts();
    if (layouts.isEmpty) return;

    final selected = await showModalBottomSheet<JournalLayout>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose layout',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final layout in layouts)
                ListTile(
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: Text(layout.name),
                  subtitle: Text(
                    '${layout.blocks.length} '
                    'block${layout.blocks.length == 1 ? '' : 's'}',
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(layout),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

  String _formatTitle(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
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
        final blocks = vm.entry.widgets;
        final scheme = Theme.of(context).colorScheme;
        final mode = (editable && _isEditing)
            ? BlockMode.editable
            : BlockMode.readOnly;

        return Scaffold(
          appBar: AppBar(
            backgroundColor:
                (editable && _isEditing) ? scheme.primaryContainer : null,
            foregroundColor:
                (editable && _isEditing) ? scheme.onPrimaryContainer : null,
            title: Text(_formatTitle(widget.date)),
            actions: [
              if (editable)
                IconButton(
                  tooltip: 'Change layout',
                  onPressed: _showLayoutPicker,
                  icon: const Icon(Icons.dashboard_outlined),
                ),
              if (editable)
                IconButton(
                  tooltip: _isEditing ? 'Done editing' : 'Edit',
                  onPressed: _toggleEditing,
                  icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
                )
              else
                const Tooltip(
                  message: 'Past entries are read-only',
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.lock_outline_rounded),
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
                  child: blocks.isEmpty
                      ? Center(
                          child: Text(
                            'No blocks for this day yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
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
