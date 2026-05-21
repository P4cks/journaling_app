import 'package:flutter/widgets.dart';

/// Raw-pointer double-tap detector that does NOT compete in the
/// gesture arena.
///
/// Why: we want **both** behaviors active on a block tile —
///   - single tap → inner widget responds (focus TextField, expand
///     carousel, open photo picker, …) with zero latency
///   - double tap → the host opens the expanded route
///
/// Stacking a `GestureDetector(onDoubleTap: …)` over the tile would
/// drop the single tap into the arena alongside the inner widget's
/// `TapGestureRecognizer`. The framework then waits the full
/// `kDoubleTapTimeout` (~300 ms) before resolving, so every single
/// tap feels laggy.
///
/// `Listener` is a pure event observer — `onPointerDown` fires
/// alongside any gesture recognition without participating. We
/// remember the timestamp of the previous down event and fire
/// [onDoubleTap] when a second one lands within
/// [Duration(milliseconds: 300)]. The inner widget meanwhile has
/// already handled the first tap normally.
class DoubleTapListener extends StatefulWidget {
  const DoubleTapListener({
    super.key,
    required this.child,
    required this.onDoubleTap,
    this.maxGap = const Duration(milliseconds: 300),
    this.maxDistance = 20.0,
  });

  final Widget child;
  final VoidCallback onDoubleTap;

  /// Maximum gap between the two `onPointerDown` events that still
  /// counts as a double-tap. Matches Flutter's `kDoubleTapTimeout`.
  final Duration maxGap;

  /// Maximum movement between the two taps that still counts as a
  /// double-tap (a small slop tolerance for thumb position).
  final double maxDistance;

  @override
  State<DoubleTapListener> createState() => _DoubleTapListenerState();
}

class _DoubleTapListenerState extends State<DoubleTapListener> {
  DateTime? _lastDownAt;
  Offset? _lastDownAtPos;

  void _onPointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final pos = event.position;
    final last = _lastDownAt;
    final lastPos = _lastDownAtPos;
    if (last != null &&
        lastPos != null &&
        now.difference(last) <= widget.maxGap &&
        (pos - lastPos).distance <= widget.maxDistance) {
      // Reset before invoking so a triple-tap doesn't double-fire.
      _lastDownAt = null;
      _lastDownAtPos = null;
      widget.onDoubleTap();
      return;
    }
    _lastDownAt = now;
    _lastDownAtPos = pos;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: widget.child,
    );
  }
}
