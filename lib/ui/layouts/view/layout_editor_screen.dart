import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/navigation_guard.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';
import 'package:journaling_app_rewrite/ui/layouts/view_model/layout_editor_view_model.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/add_block_sheet.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_icon_picker.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_name_title.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LayoutEditorScreen extends StatefulWidget {
  const LayoutEditorScreen({super.key, required this.layoutId});

  final String? layoutId;

  @override
  State<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends State<LayoutEditorScreen> {
  LayoutEditorViewModel? _viewModel;
  NavigationGuard? _guard;

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
      _guard = deps.navigationGuard..register(_onTabSwitchAttempt);
    }
  }

  @override
  void dispose() {
    _guard?.register(null);
    _viewModel?.removeListener(_onChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Resolves the dirty-state dialog when the user tries to leave the
  /// editor. Returns `true` when leaving is allowed (no dirty state, or
  /// user picked save/discard), `false` otherwise. Does NOT pop the
  /// editor — callers do that based on context (back button vs tab
  /// switch).
  Future<bool> _maybeSaveOnLeave() async {
    final vm = _viewModel;
    if (vm == null || !vm.isDirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save your changes to this layout before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    switch (choice) {
      case 'discard':
        return true;
      case 'save':
        if (!vm.canSave) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add a name to save')));
          return false;
        }
        await vm.save();
        return true;
      default:
        return false;
    }
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    final canLeave = await _maybeSaveOnLeave();
    if (!mounted || !canLeave) return;
    context.pop();
  }

  /// Tab-switch guard. The shell awaits this before calling `goBranch`.
  /// If the user picks save/discard, we also pop the editor so they
  /// don't return to a stale screen the next time they revisit this
  /// branch. If there's no dirty state, allow the switch and leave the
  /// editor mounted (so the user can tab back to mid-editing).
  Future<bool> _onTabSwitchAttempt() async {
    final vm = _viewModel;
    final wasDirty = vm != null && vm.isDirty;
    final canLeave = await _maybeSaveOnLeave();
    if (!canLeave) return false;
    if (wasDirty && mounted) context.pop();
    return true;
  }

  Future<void> _addBlock() async {
    FocusScope.of(context).unfocus();
    final selected = await showAddBlockSheet(context);
    if (selected != null) {
      _viewModel?.addBlock(selected);
    }
  }

  Future<void> _pickIcon() async {
    final vm = _viewModel;
    if (vm == null) return;
    FocusScope.of(context).unfocus();
    final picked = await showLayoutIconPicker(context, selected: vm.iconName);
    if (picked == null || !mounted) return;
    vm.setIconName(picked);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: LayoutNameTitle(controller: vm.nameController),
          actions: [
            IconButton(
              tooltip: 'Add block',
              onPressed: _addBlock,
              icon: const AppIcon(PhosphorIconsBold.plus),
            ),
            IconButton(
              tooltip: 'Change icon',
              onPressed: _pickIcon,
              icon: AppIcon(layoutIconFor(vm.iconName).duotone),
            ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: slots.isEmpty
              ? Center(
                  child: Text(
                    'No blocks yet. Tap + to add a block.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    icon: AppIcon(
                      PhosphorIconsBold.x,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => vm.removeSlot(block.id),
                  ),
                ),
        ),
      ),
    );
  }
}
