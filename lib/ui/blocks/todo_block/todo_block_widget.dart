import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_content/todo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/delayed_tap_focus.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/tonal.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Max number of todo items per block (a count cap, not a char cap).
/// UI-enforced only — no Hive bump.
const int kTodoMaxItems = 8;

class TodoBlockWidget extends StatefulWidget {
  const TodoBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
    this.onDoubleTap,
    this.editing = false,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  /// Host's "push expanded route" callback. Each per-item TextField
  /// is wrapped in `DelayedTapFocus` and forwards this on double tap.
  /// One row's TextField can therefore push the route while the
  /// others sit unfocused.
  final VoidCallback? onDoubleTap;

  /// Legacy prop — currently unused. Kept on the API so the dispatcher
  /// (`BlockWidget`) doesn't have to special-case todo.
  final bool editing;

  /// True when rendered inside the expanded route. The item list becomes
  /// scrollable so every item is reachable; in the grid it stays clipped
  /// to the fixed 1×1 cell.
  final bool expanded;

  @override
  State<TodoBlockWidget> createState() => _TodoBlockWidgetState();
}

class _TodoBlockWidgetState extends State<TodoBlockWidget> {
  // One TextEditingController + FocusNode per todo item, keyed by item
  // id. Each row's `DelayedTapFocus` wrapper reads the FocusNode so it
  // can drop out of the way once the field is focused (allowing native
  // cursor positioning) and re-attach when focus is lost.
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
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

  FocusNode _focusNodeFor(String itemId) =>
      _focusNodes.putIfAbsent(itemId, FocusNode.new);

  void _emit(List<TodoItem> items) {
    widget.onChanged?.call(
      widget.data.copyWith(content: TodoBlockContent(items: items).toMap()),
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
    _focusNodes.remove(id)?.dispose();
    _emit(next);
  }

  void _add(TodoBlockContent content, int maxItems) {
    if (content.items.length >= maxItems) return;
    final next = [...content.items, TodoItem(id: _uuid.v4(), text: '')];
    _emit(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = TodoBlockContent.fromMap(widget.data.content);

    if (widget.mode == BlockMode.readOnly) {
      if (content.items.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No todos',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.disabledColor,
            ),
          ),
        );
      }
      // Column + ClipRect — no internal scroll. Items that don't fit
      // the 1×1 cell are clipped (chrome already antialiases the
      // rounded card, but ClipRect ensures the Column doesn't paint
      // outside the padded content area either).
      return Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in content.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CheckBubble(done: item.done, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.text.isEmpty ? '—' : item.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: item.done
                                ? blockInk(context).withValues(alpha: 0.5)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Padding lives in the block widget now (see chrome's comment).
    // Items + "Add item" render in a Column. In the grid the item list
    // is clipped to the fixed cell (ClipRect); in the expanded route it
    // scrolls so every item is reachable. The "Add item" InkWell sits
    // OUTSIDE that area so it stays visible at the bottom of the Column.
    final atItemCap = content.items.length >= kTodoMaxItems;
    // Use the chrome-injected tonal ink so the affordance stays on-hue on a
    // coloured card (was colorScheme.primary, which painted the global accent
    // on top of e.g. a blue block — GUS-86).
    final ink = blockInk(context);
    final addColor = atItemCap ? ink.withValues(alpha: 0.4) : ink;
    final itemsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in content.items)
          _TodoRow(
            key: ValueKey(item.id),
            item: item,
            controller: _controllerFor(item),
            focusNode: _focusNodeFor(item.id),
            onDoubleTap: widget.onDoubleTap,
            onToggle: () => _toggle(content, item.id),
            onTextChanged: (value) => _updateText(content, item.id, value),
            onRemove: () => _remove(content, item.id),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: widget.expanded
                ? SingleChildScrollView(child: itemsColumn)
                : ClipRect(child: itemsColumn),
          ),
          // "Add item" — disabled (greyed) once the item cap is hit.
          // The combined gesture model means single-tap on a row
          // focuses the TextField; tapping this button appends a
          // fresh empty item until the cap.
          Row(
            children: [
              InkWell(
                onTap: atItemCap ? null : () => _add(content, kTodoMaxItems),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        HugeIcons.strokeRoundedPlusSign,
                        size: 14,
                        color: addColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add item',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: addColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${content.items.length}/$kTodoMaxItems tasks',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: atItemCap
                      ? theme.colorScheme.error
                      : ink.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    super.key,
    required this.item,
    required this.controller,
    required this.focusNode,
    required this.onDoubleTap,
    required this.onToggle,
    required this.onTextChanged,
    required this.onRemove,
  });

  final TodoItem item;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onDoubleTap;
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
            child: DelayedTapFocus(
              focusNode: focusNode,
              onDoubleTap: onDoubleTap,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onTextChanged,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: item.done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: item.done
                      ? blockInk(context).withValues(alpha: 0.5)
                      : null,
                ),
                decoration: const InputDecoration(
                  hintText: 'Task',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
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
                color: blockInk(context).withValues(alpha: 0.55),
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
    // Track the chrome-injected tonal ink: a filled ink bubble when done (tick
    // in the ink's contrast colour), a muted ink ring when not (GUS-86).
    final ink = blockInk(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? ink : Colors.transparent,
        border: Border.all(
          color: done ? ink : ink.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: done
          ? Center(
              child: AppIcon(
                HugeIcons.strokeRoundedTick01,
                size: size * 0.65,
                color: contrastOn(ink),
              ),
            )
          : null,
    );
  }
}
