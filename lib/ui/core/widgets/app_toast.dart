import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Visual intent of a toast — drives the leading icon and its accent
/// colour (pulled from the theme `colorScheme`, never hard-coded).
enum ToastKind { info, success, error }

/// Shows a floating toast message. Replaces the app's scattered raw
/// `SnackBar`s (GUS-49): a themed, rounded pill that flies in from the
/// right edge, then auto-dismisses.
///
/// Built on `ScaffoldMessenger`/`SnackBar` so we keep native queueing,
/// swipe-to-dismiss and lifecycle handling; the right-to-left entrance is
/// a [SlideTransition] layered inside a transparent, zero-elevation
/// SnackBar whose visible body is [_ToastPill]. Any earlier toast is
/// cleared first so messages don't stack up behind each other.
void showToast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        // A touch more clearance from the bottom edge than the floating
        // SnackBar default (GUS-55).
        margin: const EdgeInsets.fromLTRB(15, 15, 15, 24),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        content: _ToastPill(message: message, kind: kind, duration: duration),
      ),
    );
}

/// Slide/fade out plays this long before the SnackBar's auto-dismissal so
/// the pill flies back out to the right under its own animation rather
/// than relying on the messenger's default downward exit.
const Duration _kToastExitDuration = Duration(milliseconds: 260);

class _ToastPill extends StatefulWidget {
  const _ToastPill({
    required this.message,
    required this.kind,
    required this.duration,
  });

  final String message;
  final ToastKind kind;
  final Duration duration;

  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: _kToastExitDuration,
  )..forward();

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  Timer? _exitTimer;

  @override
  void initState() {
    super.initState();
    // Reverse the entrance animation just before the messenger removes the
    // SnackBar, so the visible exit is our own slide-out-to-the-right.
    final lead = widget.duration - _kToastExitDuration;
    _exitTimer = Timer(lead.isNegative ? Duration.zero : lead, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  (HugeIconData, Color) _accent(ColorScheme scheme) {
    switch (widget.kind) {
      case ToastKind.success:
        return (HugeIcons.strokeRoundedCheckmarkCircle02, scheme.primary);
      case ToastKind.error:
        return (HugeIcons.strokeRoundedAlert02, scheme.error);
      case ToastKind.info:
        return (
          HugeIcons.strokeRoundedInformationCircle,
          scheme.onSurfaceVariant,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, accent) = _accent(scheme);

    return Align(
      alignment: Alignment.centerRight,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: scheme.surfaceContainerHighest,
            elevation: 0,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(icon, size: 18, color: accent),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
