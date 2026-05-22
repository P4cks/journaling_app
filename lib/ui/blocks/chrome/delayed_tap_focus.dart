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
/// After the field is focused the gesture handlers fall back to
/// `null` and the inner `AbsorbPointer` flips to `absorbing: false`,
/// so the TextField receives taps natively (cursor positioning,
/// selection drag, etc. all work as expected). Critically the widget
/// **structure** stays identical across the focused / unfocused flip
/// — only the props change — so Flutter's element reconciliation
/// preserves the inner TextField across the rebuild. Earlier
/// iterations returned `widget.child` directly when focused, which
/// changed the parent chain and unmounted the TextField → dismissed
/// the keyboard the moment focus was acquired. The structural-stability
/// invariant is what fixed that.
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
    final hasFocus = widget.focusNode.hasFocus;
    // Keep the widget structure identical across the focused/unfocused
    // flip — only the gesture callbacks and the AbsorbPointer flag
    // change. If the structure changed (e.g. returning `widget.child`
    // directly when focused), Flutter's element reconciliation would
    // unmount and remount the inner TextField, dismissing the
    // keyboard the moment focus is acquired.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasFocus ? null : widget.focusNode.requestFocus,
      onDoubleTap: hasFocus ? null : widget.onDoubleTap,
      child: AbsorbPointer(
        // When focused, let taps pass through so the TextField can
        // position the caret / drag a selection natively. When
        // unfocused, swallow them so the outer GestureDetector's
        // arena resolution decides single vs double tap.
        absorbing: !hasFocus,
        child: widget.child,
      ),
    );
  }
}
