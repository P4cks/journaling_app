import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/header_section/header_section_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_section/text_section_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';
import 'package:journaling_app_rewrite/ui/layouts/view_model/layout_editor_view_model.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/add_block_sheet.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/add_section_sheet.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_icon_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_name_title.dart';

/// Build a preview `JournalBlockData` for a layout-editor slot. For
/// built-in types we delegate to `BlockTypeDisplay.sampleData`; for
/// `customCarousel` slots we thread the slot's `definitionId` (and
/// pre-select the first item, if any) so the preview resolves the
/// real definition's title + items instead of falling through to the
/// "Deleted block" placeholder.
///
/// Visuals are seeded from the slot id (`Random(slot.id.hashCode)`)
/// against the live post-it palette so the editor mirrors what
/// materialized entries look like — same rotation / offset / colour
/// the user will get when they create an entry from the layout. The
/// seed is deterministic, so visuals stay stable across rebuilds
/// (rebuilds happen on every keystroke in the name field). When
/// post-it mode is off, `BlockChrome` ignores the rotation/offset/
/// colour fields anyway, so passing visuals is harmless.
JournalBlockData _slotPreviewData(
  BlockSlot slot,
  BlockSettings settings,
  ThemeSettings theme,
) {
  final visuals = BlockVisuals.random(
    Random(slot.id.hashCode),
    theme.postItPalette,
  );
  if (slot.type != BlockType.customCarousel) {
    return slot.type.sampleData(id: slot.id).copyWith(visuals: visuals);
  }
  final defId = slot.definitionId;
  if (defId == null) {
    return slot.type.sampleData(id: slot.id).copyWith(visuals: visuals);
  }
  final def = settings.findCustomCarousel(defId);
  final sample = (def == null || def.items.isEmpty) ? null : def.items.first;
  return JournalBlockData.create(
    id: slot.id,
    type: slot.type,
    content: CustomCarouselBlockContent(
      definitionId: defId,
      selected: sample,
    ).toMap(),
    visuals: visuals,
  );
}

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
  SubscriptionRepository? _subscriptions;

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
      _subscriptions = deps.subscriptionRepository;
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
        if (vm.nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Add a name to save')));
          return false;
        }
        if (vm.nameConflict) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A layout with this name already exists'),
            ),
          );
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
    final vm = _viewModel;
    final subs = _subscriptions;
    if (vm == null || subs == null) return;
    FocusScope.of(context).unfocus();
    // Free users cap a blockOnly layout at `kFreeMaxBlocksPerLayout`
    // blocks; the (N+1)th add presents the paywall (BACKLOG #92).
    if (!subs.isPro &&
        vm.sections.first.slots.length >= kFreeMaxBlocksPerLayout) {
      if (!await requirePro(subs, context: context)) return;
      if (!mounted) return;
    }
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
    final blockOnlyLocked =
        vm.kind == LayoutKind.blockOnly &&
        !(_subscriptions?.isPro ?? false) &&
        vm.sections.first.slots.length >= kFreeMaxBlocksPerLayout;
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
                tooltip: blockOnlyLocked
                    ? 'Pro — unlimited blocks'
                    : 'Add block',
                onPressed: _addBlockBlockOnly,
                icon: blockOnlyLocked
                    ? Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppIcon(
                            HugeIcons.strokeRoundedPlusSign,
                            color: Theme.of(context).disabledColor,
                          ),
                          const Positioned(
                            top: -4,
                            right: -4,
                            child: ProLockBadge(compact: true),
                          ),
                        ],
                      )
                    : AppIcon(HugeIcons.strokeRoundedPlusSign),
              ),
            IconButton(
              tooltip: 'Change icon',
              onPressed: _pickIcon,
              icon: AppIcon(layoutIconFor(vm.iconName).icon),
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
    final deps = AppDependencies.of(context);
    final settings = deps.blockSettings;
    final theme = deps.themeSettings;
    final slots = vm.sections.first.slots;
    final hint = ProLimitHint(
      used: slots.length,
      max: kFreeMaxBlocksPerLayout,
      noun: 'blocks',
      subscriptions: deps.subscriptionRepository,
    );
    final Widget content = slots.isEmpty
        ? Center(
            child: Text(
              'No blocks yet. Tap + to add a block.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          )
        : BlockGrid(
            blocks: [
              for (final slot in slots)
                _slotPreviewData(slot, settings, theme),
            ],
            mode: BlockMode.readOnly,
            onReorder: (from, to) {
              // `BlockGrid` already adjusts the target index for the post-
              // remove list, so the VM call here is just `from -> to` with
              // no further translation. Replacing the slot id by index
              // matches `MainJournalViewModel.reorderBlockInSection`.
              vm.moveSlot(from, to);
            },
            onBlockTap: (block, index) async {
              final picked = await showAddBlockSheet(context);
              if (picked != null) {
                vm.replaceSlotType(block.id, picked);
              }
            },
            cardTrailing: (block, index) => IconButton(
              tooltip: 'Remove',
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: AppIcon(
                HugeIcons.strokeRoundedCancel01,
                color: scheme.onSurfaceVariant,
              ),
              onPressed: () => vm.removeSlot(block.id),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsets.only(top: 8), child: hint),
        Expanded(child: content),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Body — fixedFourPlusText: locked structure, only type-swaps allowed.
// ---------------------------------------------------------------------------

class _FixedFourPlusTextBody extends StatelessWidget {
  const _FixedFourPlusTextBody({required this.vm});
  final LayoutEditorViewModel vm;

  Future<void> _addBlock(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddBlockSheet(context);
    if (picked == null) return;
    vm.addBlockInFixedFour(picked);
  }

  Future<void> _swapType(BuildContext context, String slotId) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddBlockSheet(context);
    if (picked == null) return;
    vm.replaceSlotType(slotId, picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deps = AppDependencies.of(context);
    final settings = deps.blockSettings;
    final theme = deps.themeSettings;
    final blockGridSection = vm.sections.firstWhere(
      (s) => s.kind == SectionKind.blockGrid,
    );
    final slots = blockGridSection.slots;
    final sectionId = blockGridSection.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Same BlockGrid the custom layout uses, capped at 4 via
          // `maxBlocks`. Drag-drop, Add-block, and remove-X all flow
          // through the grid so the editor matches a materialized
          // entry visually (post-it visuals are seeded by
          // `_slotPreviewData`).
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BlockGrid(
              blocks: [
                for (final slot in slots)
                  _slotPreviewData(slot, settings, theme),
              ],
              mode: BlockMode.readOnly,
              scrollable: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              maxBlocks: LayoutEditorViewModel.fixedFourCapacity,
              onAddBlock: () => _addBlock(context),
              onReorder: (from, to) =>
                  vm.moveSlotInSection(sectionId, from, to),
              onBlockTap: (block, _) => _swapType(context, block.id),
              cardTrailing: (block, _) => IconButton(
                tooltip: 'Remove',
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: AppIcon(
                  HugeIcons.strokeRoundedCancel01,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => vm.removeFixedFourSlot(block.id),
              ),
            ),
          ),
          // Text section preview — uses the same `TextSectionWidget`
          // the materialized entry will render in `BlockMode.readOnly`
          // with empty content. That surfaces the "No text yet"
          // placeholder verbatim, so the editor mirrors the entry's
          // empty-state.
          _TextSectionPreview(),
        ],
      ),
    );
  }
}

class _FilledCell extends StatelessWidget {
  const _FilledCell({
    required this.slot,
    required this.onSwapType,
    required this.onRemove,
  });

  final BlockSlot slot;
  final VoidCallback onSwapType;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final deps = AppDependencies.of(context);
    final preview = _slotPreviewData(
      slot,
      deps.blockSettings,
      deps.themeSettings,
    );
    return GestureDetector(
      onTap: onSwapType,
      child: BlockChrome(
        visuals: preview.visuals,
        topRight: IconButton(
          tooltip: 'Remove',
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(),
          icon: AppIcon(
            HugeIcons.strokeRoundedCancel01,
            color: scheme.onSurfaceVariant,
          ),
          onPressed: onRemove,
        ),
        child: AbsorbPointer(
          child: BlockWidget(
            key: ValueKey(slot.id),
            data: preview,
            mode: BlockMode.readOnly,
          ),
        ),
      ),
    );
  }
}

class _EmptyAddBlockCell extends StatelessWidget {
  const _EmptyAddBlockCell({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = onTap == null;
    final color = disabled ? theme.disabledColor : scheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(HugeIcons.strokeRoundedPlusSign, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              'Add block',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    final subscriptions = AppDependencies.of(context).subscriptionRepository;
    // Free users cap a custom layout at `kFreeMaxSectionsCustom` sections;
    // the (N+1)th add presents the paywall. (GUS-32)
    if (!subscriptions.isPro &&
        vm.sections.length >= kFreeMaxSectionsCustom) {
      if (!await requirePro(subscriptions, context: context)) return;
      if (!context.mounted) return;
    }
    final picked = await showAddSectionSheet(
      context,
      subscriptions: subscriptions,
    );
    if (picked == null) return;
    vm.addSection(picked);
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
          ProLimitHint(
            used: sections.length,
            max: kFreeMaxSectionsCustom,
            noun: 'sections',
            subscriptions: AppDependencies.of(context).subscriptionRepository,
          ),
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
    final (String header, String removeLabel) = switch (section.kind) {
      SectionKind.blockGrid => ('Block grid', 'block grid'),
      SectionKind.text => ('Text section', 'text section'),
      SectionKind.featureBlock => ('Feature block', 'feature block'),
      SectionKind.header => ('Header', 'header'),
      SectionKind.divider => ('Divider', 'divider'),
      SectionKind.blockTextBody => ('Block + text', 'block + text'),
    };

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
                    header,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Move up',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: isFirst
                      ? null
                      : () => vm.moveSection(index, index - 1),
                  icon: AppIcon(HugeIcons.strokeRoundedArrowUp01),
                ),
                IconButton(
                  tooltip: 'Move down',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: isLast
                      ? null
                      : () => vm.moveSection(index, index + 1),
                  icon: AppIcon(HugeIcons.strokeRoundedArrowDown01),
                ),
                IconButton(
                  tooltip: 'Remove section',
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final ok = await onConfirmRemove(removeLabel);
                    if (!ok) return;
                    vm.removeSection(section.id);
                  },
                  icon: AppIcon(
                    HugeIcons.strokeRoundedDelete02,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          switch (section.kind) {
            SectionKind.blockGrid => _BlockGridSectionBody(
              vm: vm,
              sectionIndex: index,
            ),
            SectionKind.text => const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: _TextSectionPreview(),
            ),
            SectionKind.featureBlock => _FeatureBlockSectionBody(
              vm: vm,
              sectionIndex: index,
            ),
            SectionKind.header => const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
              child: _HeaderSectionPreview(),
            ),
            SectionKind.divider => const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Divider(height: 1),
            ),
            SectionKind.blockTextBody => _BlockTextSectionBody(
              vm: vm,
              sectionIndex: index,
            ),
          },
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
    final scheme = Theme.of(context).colorScheme;
    final deps = AppDependencies.of(context);
    final settings = deps.blockSettings;
    final theme = deps.themeSettings;
    final section = vm.sections[sectionIndex];
    final sectionId = section.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      child: BlockGrid(
        blocks: [
          for (final slot in section.slots)
            _slotPreviewData(slot, settings, theme),
        ],
        mode: BlockMode.readOnly,
        scrollable: false,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        onAddBlock: () => _addBlock(context),
        onReorder: (from, to) => vm.moveSlotInSection(sectionId, from, to),
        onBlockTap: (block, _) async {
          final picked = await showAddBlockSheet(context);
          if (picked != null) {
            vm.replaceSlotType(block.id, picked);
          }
        },
        cardTrailing: (block, _) => IconButton(
          tooltip: 'Remove',
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          icon: AppIcon(
            HugeIcons.strokeRoundedCancel01,
            color: scheme.onSurfaceVariant,
          ),
          onPressed: () => vm.removeSlotInSection(sectionId, block.id),
        ),
      ),
    );
  }
}

class _FeatureBlockSectionBody extends StatelessWidget {
  const _FeatureBlockSectionBody({
    required this.vm,
    required this.sectionIndex,
  });

  final LayoutEditorViewModel vm;
  final int sectionIndex;

  Future<void> _pickType(BuildContext context, {bool isSwap = false}) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddBlockSheet(
      context,
      allowedTypes: LayoutEditorViewModel.featureBlockAllowedTypes,
      title: isSwap ? 'Swap block' : 'Choose feature block',
    );
    if (picked == null) return;
    vm.setFeatureBlock(vm.sections[sectionIndex].id, picked);
  }

  @override
  Widget build(BuildContext context) {
    final section = vm.sections[sectionIndex];
    final sectionId = section.id;
    final slots = section.slots;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: AspectRatio(
        aspectRatio: 1,
        child: slots.isEmpty
            ? _EmptyAddBlockCell(onTap: () => _pickType(context))
            : _FilledCell(
                slot: slots.first,
                onSwapType: () => _pickType(context, isSwap: true),
                onRemove: () => vm.clearFeatureBlock(sectionId),
              ),
      ),
    );
  }
}

/// Editor body for a `blockTextBody` section: the float-block picker
/// (photo/memory, identical slot machinery to `_FeatureBlockSectionBody`)
/// laid out left of a read-only text preview, hinting the magazine
/// float arrangement a materialized entry will show.
class _BlockTextSectionBody extends StatelessWidget {
  const _BlockTextSectionBody({required this.vm, required this.sectionIndex});

  final LayoutEditorViewModel vm;
  final int sectionIndex;

  Future<void> _pickType(BuildContext context, {bool isSwap = false}) async {
    FocusScope.of(context).unfocus();
    final picked = await showAddBlockSheet(
      context,
      allowedTypes: LayoutEditorViewModel.featureBlockAllowedTypes,
      title: isSwap ? 'Swap block' : 'Choose block',
    );
    if (picked == null) return;
    vm.setFeatureBlock(vm.sections[sectionIndex].id, picked);
  }

  @override
  Widget build(BuildContext context) {
    final section = vm.sections[sectionIndex];
    final sectionId = section.id;
    final slots = section.slots;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: slots.isEmpty
                ? _EmptyAddBlockCell(onTap: () => _pickType(context))
                : _FilledCell(
                    slot: slots.first,
                    onSwapType: () => _pickType(context, isSwap: true),
                    onRemove: () => vm.clearFeatureBlock(sectionId),
                  ),
          ),
          const Expanded(child: _TextSectionPreview()),
        ],
      ),
    );
  }
}

/// Read-only preview of a text section — uses the same
/// `TextSectionWidget` the materialized entry renders. Backed by a
/// fresh empty `TextBlockContent` so the widget shows its
/// "No text yet" italic placeholder, mirroring an untouched entry.
class _TextSectionPreview extends StatelessWidget {
  const _TextSectionPreview();

  @override
  Widget build(BuildContext context) {
    return TextSectionWidget(
      data: JournalBlockData.create(
        id: 'layout-editor-text-preview',
        type: BlockType.textBlock,
        content: const TextBlockContent(text: '').toMap(),
      ),
      mode: BlockMode.readOnly,
    );
  }
}

class _HeaderSectionPreview extends StatelessWidget {
  const _HeaderSectionPreview();

  @override
  Widget build(BuildContext context) {
    return HeaderSectionWidget(
      data: JournalBlockData.create(
        id: 'layout-editor-header-preview',
        type: BlockType.textBlock,
        content: const TextBlockContent(text: '').toMap(),
      ),
      mode: BlockMode.readOnly,
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
              AppIcon(
                HugeIcons.strokeRoundedPlusSign,
                color: theme.colorScheme.primary,
              ),
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
