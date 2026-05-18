import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';

/// Shared [TextEditingController] lifecycle for State classes whose
/// widget renders a single [TextBlockContent]-backed block.
///
/// The 1×1 [TextBlockWidget] and the full-width [TextSectionWidget]
/// render differently but persist through the same `{"text": "..."}`
/// JSON shape and share an identical controller lifecycle. This mixin
/// owns construction, swap-on-`data.id`-change, dispose, and the
/// outbound emit that wraps a new string into a fresh
/// [JournalBlockData] via the parent's `onChanged` callback.
///
/// Subclasses provide [data] and [onChanged] — typically by delegating
/// to `widget.data` / `widget.onChanged`.
mixin TextContentControllerMixin<T extends StatefulWidget> on State<T> {
  late final TextEditingController controller;
  late String _lastDataId;

  JournalBlockData get data;
  ValueChanged<JournalBlockData>? get onChanged;

  @override
  void initState() {
    super.initState();
    final content = TextBlockContent.fromMap(data.content);
    controller = TextEditingController(text: content.text);
    _lastDataId = data.id;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync the controller only when the underlying block changed
    // identity (the user swiped to a different entry). Per-keystroke
    // edits round-trip through `emitText` and would race the caret if
    // we copied content back here.
    if (data.id != _lastDataId) {
      final content = TextBlockContent.fromMap(data.content);
      controller.text = content.text;
      _lastDataId = data.id;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void emitText(String value) {
    final updated = data.copyWith(
      content: TextBlockContent(text: value).toMap(),
    );
    onChanged?.call(updated);
  }
}
