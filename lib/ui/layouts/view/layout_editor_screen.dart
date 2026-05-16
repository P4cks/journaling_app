import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';
import 'package:journaling_app_rewrite/ui/layouts/view_model/layout_editor_view_model.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/add_block_sheet.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/add_section_sheet.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_icon_picker.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_name_title.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LayoutEditorScreen extends StatefulWidget {
  const LayoutEditorScreen({
    super.key,
    required this.layoutId,
    this.initialKind,
  });

  final String? layoutId;
  final LayoutKind? initialKind;

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
        initialKind: widget.initialKind,
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

  Future<void> _addBlockBlockOnly() async {
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

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: LayoutNameTitle(controller: vm.nameController),
          actions: [
            if (vm.kind == LayoutKind.blockOnly)
              IconButton(
                tooltip: 'Add block',
                onPressed: _addBlockBlockOnly,
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
          child: switch (vm.kind) {
            LayoutKind.blockOnly => _BlockOnlyBody(vm: vm),
            LayoutKind.fixedFourPlusText => _FixedFourPlusTextBody(vm: vm),
            LayoutKind.custom => _CustomBody(vm: vm),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — blockOnly: matches the previous editor exactly.
// ---------------------------------------------------------------------------

class _BlockOnlyBody extends StatelessWidget {
  const _BlockOnlyBody({required this.vm});
  final LayoutEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slots = vm.sections.first.slots;
    if (slots.isEmpty) {
      return Center(
        child: Text(
          'No blocks yet. Tap + to add a block.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }
    return BlockGrid(
      blocks: [for (final slot in slots) slot.type.sampleData(id: slot.id)],
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
    );
  }
}

// ---------------------------------------------------------------------------
// Body — fixedFourPlusText: locked structure, only type-swaps allowed.
// ---------------------------------------------------------------------------

class _FixedFourPlusTextBody extends StatelessWidget {
  const _FixedFourPlusTextBody({required this.vm});
  final LayoutEditorViewModel vm;

  Future<void> _swapType(BuildContext context, String slotId) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddBlockSheet(context);
    if (picked == null) return;
    vm.replaceSlotType(slotId, picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockGridSection = vm.sections.firstWhere(
      (s) => s.kind == SectionKind.blockGrid,
    );
    final blocks = [
      for (final slot in blockGridSection.slots)
        slot.type.sampleData(id: slot.id),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2×2 grid — tap a tile to swap the block type.
          BlockGrid(
            blocks: blocks,
            mode: BlockMode.readOnly,
            scrollable: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            cardTrailing: (block, index) => IconButton(
              tooltip: 'Change type',
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              icon: const AppIcon(PhosphorIconsBold.pencilSimple),
              onPressed: () => _swapType(context, block.id),
            ),
          ),
          const SizedBox(height: 16),
          // Text section preview — content lives in the entry, not the layout.
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Text section',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Each entry created from this layout gets a full-width text area here.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — custom: section list + add-section tap zone.
// ---------------------------------------------------------------------------

class _CustomBody extends StatelessWidget {
  const _CustomBody({required this.vm});
  final LayoutEditorViewModel vm;

  Future<void> _addSection(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddSectionSheet(context);
    if (picked == null) return;
    vm.addSection(picked.kind, rows: picked.rows);
  }

  Future<bool> _confirmRemove(BuildContext context, String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove $label?'),
        content: Text('The $label will be removed from this layout.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final sections = vm.sections;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No sections yet. Tap below to add one.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            for (var i = 0; i < sections.length; i++)
              _SectionCard(
                vm: vm,
                index: i,
                onConfirmRemove: (label) => _confirmRemove(context, label),
              ),
          const SizedBox(height: 12),
          _AddSectionTapZone(onTap: () => _addSection(context)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.vm,
    required this.index,
    required this.onConfirmRemove,
  });

  final LayoutEditorViewModel vm;
  final int index;
  final Future<bool> Function(String label) onConfirmRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final section = vm.sections[index];
    final isFirst = index == 0;
    final isLast = index == vm.sections.length - 1;
    final isBlockGrid = section.kind == SectionKind.blockGrid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isBlockGrid
                        ? 'Block grid · ${section.rows ?? 1} row${section.rows == 1 ? '' : 's'}'
                        : 'Text section',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: isFirst ? null : () => vm.moveSection(index, index - 1),
                  icon: const AppIcon(PhosphorIconsBold.arrowUp),
                ),
                IconButton(
                  tooltip: 'Move down',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: isLast ? null : () => vm.moveSection(index, index + 1),
                  icon: const AppIcon(PhosphorIconsBold.arrowDown),
                ),
                IconButton(
                  tooltip: 'Remove section',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final label = isBlockGrid ? 'block grid' : 'text section';
                    final ok = await onConfirmRemove(label);
                    if (!ok) return;
                    vm.removeSection(section.id);
                  },
                  icon: AppIcon(
                    PhosphorIconsBold.trash,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          if (isBlockGrid) _BlockGridSectionBody(vm: vm, sectionIndex: index),
          if (!isBlockGrid)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _TextSectionPreview(),
            ),
        ],
      ),
    );
  }
}

class _BlockGridSectionBody extends StatelessWidget {
  const _BlockGridSectionBody({required this.vm, required this.sectionIndex});

  final LayoutEditorViewModel vm;
  final int sectionIndex;

  Future<void> _addBlock(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddBlockSheet(context);
    if (picked == null) return;
    vm.addBlockInSection(vm.sections[sectionIndex].id, picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final section = vm.sections[sectionIndex];
    final sectionId = section.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rows segmented control
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Text(
                'Rows',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                ],
                selected: {section.rows ?? 1},
                onSelectionChanged: (sel) =>
                    vm.setSectionRows(sectionId, sel.first),
              ),
            ],
          ),
        ),
        // Slots
        if (section.slots.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextButton.icon(
              onPressed: () => _addBlock(context),
              icon: const AppIcon(PhosphorIconsBold.plus, size: 16),
              label: const Text('Add block'),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlockGrid(
                  blocks: [
                    for (final slot in section.slots)
                      slot.type.sampleData(id: slot.id),
                  ],
                  mode: BlockMode.readOnly,
                  scrollable: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  onReorder: (from, to) =>
                      vm.moveSlotInSection(sectionId, from, to),
                  cardTrailing: (block, index) => IconButton(
                    tooltip: 'Remove',
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    icon: AppIcon(
                      PhosphorIconsBold.x,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        vm.removeSlotInSection(sectionId, block.id),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addBlock(context),
                      icon: const AppIcon(PhosphorIconsBold.plus, size: 16),
                      label: const Text('Add block'),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TextSectionPreview extends StatelessWidget {
  const _TextSectionPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Each entry gets a full-width text area in this section.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.disabledColor,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _AddSectionTapZone extends StatelessWidget {
  const _AddSectionTapZone({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(PhosphorIconsBold.plus, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Add section',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

