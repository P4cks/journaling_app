import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

/// Shared [TextEditingController] + [FocusNode] lifecycle for State
/// classes whose widget renders a single [TextBlockContent]-backed
/// block.
///
/// The 1×1 [TextBlockWidget] and the full-width [TextSectionWidget]
/// render differently but persist through the same `{"text": "..."}`
/// JSON shape and share an identical controller lifecycle. This mixin
/// owns construction, swap-on-`data.id`-change, dispose, the outbound
/// emit that wraps a new string into a fresh [JournalBlockData] via the
/// parent's `onChanged` callback, and the focus node that the
/// double-tap edit-mode flow uses to programmatically focus the field.
///
/// Subclasses provide [data] and [onChanged] — typically by delegating
/// to `widget.data` / `widget.onChanged`. Subclasses that participate
/// in the double-tap edit-mode flow also override [editing] to forward
/// `widget.editing`; the mixin calls [requestFocus] on the focus node
/// each time `editing` flips from false to true.
mixin TextContentControllerMixin<T extends StatefulWidget> on State<T> {
  late final TextEditingController controller;
  late final FocusNode focusNode;
  late String _lastDataId;
  bool _wasEditing = false;

  JournalBlockData get data;
  ValueChanged<JournalBlockData>? get onChanged;

  /// Override to forward `widget.editing` (or whatever signal the
  /// hosting widget uses). When this flips from false to true the
  /// mixin requests focus on [focusNode]; when it flips to false it
  /// unfocuses. Default `false` keeps the mixin inert for callers that
  /// don't opt in.
  bool get editing => false;

  @override
  void initState() {
    super.initState();
    final content = TextBlockContent.fromMap(data.content);
    controller = TextEditingController(text: content.text);
    focusNode = FocusNode();
    _lastDataId = data.id;
    _wasEditing = editing;
    // Don't auto-focus on initial mount. In normal mode (single-tap
    // engage) the user is the one who taps the field — no
    // programmatic focus required. In the expanded route the body
    // mounts with `editing: false` (display state) and the user taps
    // inside the route to flip to true; auto-focus is handled by the
    // false → true transition in [didUpdateWidget].
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final content = TextBlockContent.fromMap(data.content);
    if (data.id != _lastDataId) {
      // User swiped to a different entry — replace controller content
      // wholesale.
      controller.text = content.text;
      _lastDataId = data.id;
    } else if (controller.text != content.text) {
      // Same block but the persisted text diverged from this
      // controller's view (typically because an external editor — e.g.
      // the expanded-block route mirror — emitted an update). Per-
      // keystroke edits from THIS controller can't trip this branch
      // because the parent rebuild that flows back here arrives with
      // `data.text == controller.text`. Reposition the caret at the
      // end so an external paste/full-replace doesn't strand it
      // beyond the new length.
      controller.value = TextEditingValue(
        text: content.text,
        selection: TextSelection.collapsed(offset: content.text.length),
      );
    }
    // React to edit-mode toggles. Wrapped in a post-frame callback
    // because the parent's setState that flipped `editing` may still be
    // tearing the tree down (e.g. AbsorbPointer flipping from absorbing
    // to passing) — requesting focus mid-build is unsafe.
    final nowEditing = editing;
    if (nowEditing != _wasEditing) {
      _wasEditing = nowEditing;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (nowEditing) {
          focusNode.requestFocus();
        } else if (focusNode.hasFocus) {
          focusNode.unfocus();
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void emitText(String value) {
    final updated = data.copyWith(
      content: TextBlockContent(text: value).toMap(),
    );
    onChanged?.call(updated);
  }
}
