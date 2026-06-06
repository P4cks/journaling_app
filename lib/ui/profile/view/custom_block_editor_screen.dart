import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
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

  Future<void> _addEmoji() async {
    final vm = _viewModel;
    if (vm == null) return;
    final emoji = await showDialog<String>(
      context: context,
      builder: (_) => const _AddEmojiDialog(),
    );
    if (emoji == null || emoji.isEmpty) return;
    vm.addItem(CarouselItem.emoji(emoji));
  }

  Future<void> _addIcon() async {
    final vm = _viewModel;
    if (vm == null) return;
    final iconName = await _showIconPicker(context);
    if (iconName == null) return;
    vm.addItem(CarouselItem.icon(iconName));
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addEmoji,
                    icon: AppIcon(HugeIcons.strokeRoundedSmile),
                    label: const Text('Add emoji'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addIcon,
                    icon: AppIcon(HugeIcons.strokeRoundedShapes),
                    label: const Text('Add icon'),
                  ),
                ),
              ],
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

class _AddEmojiDialog extends StatefulWidget {
  const _AddEmojiDialog();

  @override
  State<_AddEmojiDialog> createState() => _AddEmojiDialogState();
}

class _AddEmojiDialogState extends State<_AddEmojiDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Type or paste an emoji');
      return;
    }
    // No strict single-emoji enforcement — Dart can't easily count
    // grapheme clusters without a package, and most emoji input
    // (system keyboard / paste) yields exactly one anyway. Cap length
    // as a sanity bound against pasted essays.
    if (raw.length > 16) {
      setState(() => _error = 'Just one emoji, please');
      return;
    }
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add emoji'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 40),
        decoration: InputDecoration(
          hintText: '😀',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

/// Modal-sheet picker over the curated [kCarouselIcons]. Returns the
/// chosen icon's stable `name`, or `null` on dismiss. Layout mirrors
/// [showLayoutIconPicker](../../layouts/widgets/layout_icon_picker.dart)
/// — 56×56 tiles in a `Wrap`.
Future<String?> _showIconPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick an icon',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final icon in kCarouselIcons)
                    _PickerTile(
                      icon: icon,
                      onTap: () => Navigator.of(sheetContext).pop(icon.name),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.onTap});

  final CarouselIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: icon.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          alignment: Alignment.center,
          child: AppIcon(icon.icon, size: 28),
        ),
      ),
    );
  }
}
