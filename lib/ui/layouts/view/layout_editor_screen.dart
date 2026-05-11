import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/layouts/view_model/layout_editor_view_model.dart';

class LayoutEditorScreen extends StatefulWidget {
  const LayoutEditorScreen({super.key, required this.layoutId});

  final String? layoutId;

  @override
  State<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends State<LayoutEditorScreen> {
  LayoutEditorViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = LayoutEditorViewModel(
        repository: deps.layoutRepository,
        layoutId: widget.layoutId,
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

  Future<void> _save() async {
    final vm = _viewModel;
    if (vm == null || !vm.canSave) return;
    await vm.save();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _showAddBlockSheet() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<BlockType>(
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
                    'Add block',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final type in BlockType.values)
                ListTile(
                  leading: Icon(type.icon),
                  title: Text(type.label),
                  onTap: () => Navigator.of(sheetContext).pop(type),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      _viewModel?.addBlock(selected);
    }
  }

  List<JournalBlockData> _slotsAsBlockData() {
    final vm = _viewModel!;
    return [
      for (final slot in vm.slots)
        JournalBlockData.create(id: slot.id, type: slot.type),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold();

    final slots = vm.slots;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isNew ? 'New Layout' : 'Edit Layout'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: vm.canSave ? _save : null,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: vm.nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Blocks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: slots.isEmpty
                  ? Center(
                      child: Text(
                        'No blocks yet. Tap "Add block" to start.',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).disabledColor,
                                ),
                      ),
                    )
                  : BlockGrid(
                      blocks: _slotsAsBlockData(),
                      mode: BlockMode.readOnly,
                      onReorder: vm.moveSlot,
                      cardTrailing: (block, index) => IconButton(
                        tooltip: 'Remove',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => vm.removeSlot(block.id),
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showAddBlockSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add block'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
