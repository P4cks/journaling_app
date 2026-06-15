import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/wannado_item.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/wannado_editor_view_model.dart';

/// Create / edit a `WannadoDefinition` (a named "Wanna-do Carousel").
/// Mirrors `CustomBlockEditorScreen`'s draft + Cancel/Discard/Save-on-leave
/// pattern.
///
/// `definitionId == null` → new definition. Otherwise the screen
/// hydrates the existing one for editing. Items are free text (no
/// icon/emoji) — added/edited via a single-field text dialog.
class WannadoEditorScreen extends StatefulWidget {
  const WannadoEditorScreen({super.key, this.definitionId});

  final String? definitionId;

  @override
  State<WannadoEditorScreen> createState() => _WannadoEditorScreenState();
}

class _WannadoEditorScreenState extends State<WannadoEditorScreen> {
  WannadoEditorViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = WannadoEditorViewModel(
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
        content: const Text('Save your wanna-do carousel before leaving?'),
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
    final text = await _showItemDialog(context);
    if (text == null) return;
    vm.addItem(text);
  }

  Future<void> _editItem(int index, WannadoItem item) async {
    final vm = _viewModel;
    if (vm == null) return;
    final text = await _showItemDialog(context, initial: item.text);
    if (text == null) return;
    vm.updateItemAt(index, text);
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
          title: Text(
            vm.isNew ? 'New wanna-do carousel' : 'Edit wanna-do carousel',
          ),
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
                hintText: 'e.g. Travel dreams',
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
              'These rotate through the carousel one at a time. Drag to reorder.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (vm.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No items yet. Add at least one to save.',
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
                onReorderItem: vm.moveItem,
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  return _ItemRow(
                    key: ValueKey(item.id),
                    item: item,
                    index: index,
                    onEdit: () => _editItem(index, item),
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
    required this.onEdit,
    required this.onRemove,
  });

  final WannadoItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onEdit,
        title: Text(item.text, style: theme.textTheme.bodyMedium),
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

/// Single-field add/edit dialog for a wanna-do item. Returns the trimmed
/// text, or `null` on cancel / empty.
Future<String?> _showItemDialog(BuildContext context, {String? initial}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _WannadoItemDialog(initial: initial),
  );
  if (result == null || result.isEmpty) return null;
  return result;
}

/// The add/edit dialog content. **Stateful so it owns its
/// `TextEditingController`** and disposes it in its own `dispose()` —
/// disposing the controller synchronously right after `showDialog`
/// returns crashes the TextField as it rebuilds during the dialog's exit
/// animation (see the postmortem in block_settings_screen's old
/// `_WannadoEditDialog`).
class _WannadoItemDialog extends StatefulWidget {
  const _WannadoItemDialog({this.initial});

  final String? initial;

  @override
  State<_WannadoItemDialog> createState() => _WannadoItemDialogState();
}

class _WannadoItemDialogState extends State<_WannadoItemDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add wanna-do' : 'Edit wanna-do'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'e.g. See the northern lights',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
