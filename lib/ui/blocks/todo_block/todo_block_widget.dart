import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/todo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class TodoBlockWidget extends StatefulWidget {
  const TodoBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// True when this block is the active edit target. Drops the inner
  /// AbsorbPointer so per-item TextFields, the toggle bubbles, the
  /// remove icons, and the "Add item" affordance become interactive.
  /// Outside of edit mode the whole rendered tree is pointer-absorbed
  /// — single-taps are inert, double-tap activates via the grid.
  final bool editing;

  /// True when the body is rendered inside the expanded route. Only
  /// matters for the "Add task" affordance — per the new uniform
  /// architecture, adding items is an "action" and actions live in
  /// the expanded mode only. In in-place edit mode (`editing == true
  /// && expanded == false`) the user can still toggle, edit, and
  /// remove existing items, but cannot add new ones.
  final bool expanded;

  @override
  State<TodoBlockWidget> createState() => _TodoBlockWidgetState();
}

class _TodoBlockWidgetState extends State<TodoBlockWidget> {
  // One TextEditingController per todo item, keyed by item id, so the
  // caret position survives per-keystroke saves (the parent rebuilds
  // with a new content map every keystroke).
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(TodoItem item) {
    final existing = _controllers[item.id];
    if (existing != null) {
      // Only overwrite the controller text when the model value changed
      // from somewhere other than this controller — i.e. when the
      // controller hasn't been the source of the current value.
      if (existing.text != item.text) {
        existing.value = TextEditingValue(
          text: item.text,
          selection: TextSelection.collapsed(offset: item.text.length),
        );
      }
      return existing;
    }
    final fresh = TextEditingController(text: item.text);
    _controllers[item.id] = fresh;
    return fresh;
  }

  void _emit(List<TodoItem> items) {
    widget.onChanged?.call(
      widget.data.copyWith(
        content: TodoBlockContent(items: items).toMap(),
      ),
    );
  }

  void _toggle(TodoBlockContent content, String id) {
    final next = [
      for (final item in content.items)
        item.id == id ? item.copyWith(done: !item.done) : item,
    ];
    _emit(next);
  }

  void _updateText(TodoBlockContent content, String id, String text) {
    final next = [
      for (final item in content.items)
        item.id == id ? item.copyWith(text: text) : item,
    ];
    _emit(next);
  }

  void _remove(TodoBlockContent content, String id) {
    final next = [
      for (final item in content.items)
        if (item.id != id) item,
    ];
    _controllers.remove(id)?.dispose();
    _emit(next);
  }

  void _add(TodoBlockContent content) {
    final next = [...content.items, TodoItem(id: _uuid.v4(), text: '')];
    _emit(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = TodoBlockContent.fromMap(widget.data.content);

    if (widget.mode == BlockMode.readOnly) {
      if (content.items.isEmpty) {
        return Text(
          'No todos',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.disabledColor,
          ),
        );
      }
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: content.items.length,
        itemBuilder: (context, i) {
          final item = content.items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckBubble(done: item.done, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text.isEmpty ? '—' : item.text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      decoration: item.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.done
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: content.items.length,
            itemBuilder: (context, i) {
              final item = content.items[i];
              return _TodoRow(
                key: ValueKey(item.id),
                item: item,
                controller: _controllerFor(item),
                onToggle: () => _toggle(content, item.id),
                onTextChanged: (value) =>
                    _updateText(content, item.id, value),
                onRemove: () => _remove(content, item.id),
              );
            },
          ),
        ),
        // "Add item" — always visible in editable mode. The combined
        // gesture model means single-tap on the row focuses the
        // TextField; tapping this button appends a fresh empty item.
        InkWell(
          onTap: () => _add(content),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedPlusSign,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add item',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.item,
    required this.controller,
    required this.onToggle,
    required this.onTextChanged,
    required this.onRemove,
  });

  final TodoItem item;
  final TextEditingController controller;
  final VoidCallback onToggle;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: _CheckBubble(done: item.done, size: 16),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onTextChanged,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: item.done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: item.done ? theme.colorScheme.onSurfaceVariant : null,
              ),
              decoration: const InputDecoration(
                hintText: 'Task',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AppIcon(
                HugeIcons.strokeRoundedCancel01,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  const _CheckBubble({required this.done, required this.size});

  final bool done;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: done ? scheme.primary : scheme.outline,
          width: 1.5,
        ),
      ),
      child: done
          ? Center(
              child: AppIcon(
                HugeIcons.strokeRoundedTick01,
                size: size * 0.65,
                color: scheme.onPrimary,
              ),
            )
          : null,
    );
  }
}
