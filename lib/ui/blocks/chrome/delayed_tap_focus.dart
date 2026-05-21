import 'package:flutter/material.dart';

/// Conditionally wraps a text-input child so its first tap is **delayed
/// by `kDoubleTapTimeout`** to give the framework a chance to resolve
/// a double-tap before the keyboard rises.
///
/// In our combined gesture model (single-tap edits, double-tap opens
/// the expanded route), a user who double-taps a text block would
/// otherwise see the keyboard flash up between the first and second
/// tap — the field's natural `TapGestureRecognizer` wins the first
/// tap immediately. This wrapper consumes pre-focus taps via a
/// `GestureDetector(onTap, onDoubleTap)`; Flutter's arena waits the
/// double-tap timeout, then fires `onTap` (programmatic focus) only
/// if no second tap arrived. On double tap, [onDoubleTap] fires
/// instead — usually the host's "push the expanded route" callback.
///
/// After the field is focused the wrapper drops out so the inner
/// TextField receives taps natively (cursor positioning, selection
/// drag, etc. all work as expected). Listening to the `FocusNode`
/// triggers the rebuild.
class DelayedTapFocus extends StatefulWidget {
  const DelayedTapFocus({
    super.key,
    required this.focusNode,
    required this.child,
    this.onDoubleTap,
  });

  final FocusNode focusNode;
  final Widget child;

  /// Optional double-tap handler. When the user double-taps the
  /// (unfocused) field, the framework fires this instead of
  /// `requestFocus`. Pass the host's "push expanded route" callback.
  final VoidCallback? onDoubleTap;

  @override
  State<DelayedTapFocus> createState() => _DelayedTapFocusState();
}

class _DelayedTapFocusState extends State<DelayedTapFocus> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant DelayedTapFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.focusNode.hasFocus) {
      // Already focused — let taps reach the field natively so the
      // user can position the cursor / drag a selection.
      return widget.child;
    }
    // Pre-focus: outer GestureDetector with both callbacks creates
    // the ~300 ms arena disambiguation. Single tap → programmatic
    // focus. Double tap → host's onDoubleTap (route push).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.focusNode.requestFocus,
      onDoubleTap: widget.onDoubleTap,
      child: AbsorbPointer(child: widget.child),
    );
  }
}
