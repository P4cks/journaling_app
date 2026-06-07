import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/icon_emoji_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/custom_block_editor_view_model.dart';

/// Create / edit a `CustomCarouselDefinition`. Mirrors
/// `LayoutEditorScreen`'s draft + Cancel/Discard/Save-on-leave pattern.
///
/// `definitionId == null` → new definition. Otherwise the screen
/// hydrates the existing one for editing.
class CustomBlockEditorScreen extends StatefulWidget {
  const CustomBlockEditorScreen({super.key, this.definitionId});

  final String? definitionId;

  @override
  State<CustomBlockEditorScreen> createState() =>
      _CustomBlockEditorScreenState();
}

class _CustomBlockEditorScreenState extends State<CustomBlockEditorScreen> {
  CustomBlockEditorViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = CustomBlockEditorViewModel(
        settings: deps.blockSettings,
        definitionId: widget.definitionId,
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
        content: const Text('Save your custom block before leaving?'),
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
          showToast(
            context,
            vm.titleError ?? vm.itemsError ?? 'Cannot save',
            kind: ToastKind.error,
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

  Future<void> _addItem() async {
    final vm = _viewModel;
    if (vm == null) return;
    final result = await showIconEmojiPicker(
      context,
      allowEmoji: true,
      title: 'Add item',
      icons: [
        for (final i in kCarouselIcons)
          PickerIcon(name: i.name, icon: i.icon, label: i.label),
      ],
    );
    switch (result) {
      case null:
        return;
      case PickerEmojiResult(:final emoji):
        vm.addItem(CarouselItem.emoji(emoji));
      case PickerIconResult(:final name):
        vm.addItem(CarouselItem.icon(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold(body: SizedBox.shrink());
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vm.isNew ? 'New custom block' : 'Edit custom block'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Title',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: vm.titleController,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              decoration: InputDecoration(
                hintText: 'e.g. Energy',
                border: const OutlineInputBorder(),
                errorText: vm.titleError,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Items',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'First item is the leftmost in the carousel. Drag to reorder.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (vm.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No items yet. Add at least two to save.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.disabledColor,
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: vm.items.length,
                onReorder: vm.moveItem,
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  return _ItemRow(
                    key: ValueKey('${item.kind.name}:${item.value}:$index'),
                    item: item,
                    index: index,
                    onRemove: () => vm.removeItemAt(index),
                  );
                },
              ),
            if (vm.itemsError != null) ...[
              const SizedBox(height: 4),
              Text(
                vm.itemsError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: AppIcon(HugeIcons.strokeRoundedAdd01),
              label: const Text('Add item'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
  });

  final CarouselItem item;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = switch (item.kind) {
      CarouselItemKind.emoji => Text(
        item.value,
        style: const TextStyle(fontSize: 28),
      ),
      CarouselItemKind.icon => AppIcon(
        carouselIconFor(item.value)?.icon ?? HugeIcons.strokeRoundedQuestion,
        size: 28,
      ),
    };
    final label = switch (item.kind) {
      CarouselItemKind.emoji => item.value,
      CarouselItemKind.icon => carouselIconFor(item.value)?.label ?? item.value,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: SizedBox(width: 40, height: 40, child: Center(child: preview)),
        title: Text(label, style: theme.textTheme.bodyMedium),
        subtitle: Text(item.kind == CarouselItemKind.emoji ? 'Emoji' : 'Icon'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onRemove,
              icon: AppIcon(
                HugeIcons.strokeRoundedCancel01,
                color: theme.colorScheme.error,
              ),
              tooltip: 'Remove',
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AppIcon(HugeIcons.strokeRoundedMoreVertical),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

