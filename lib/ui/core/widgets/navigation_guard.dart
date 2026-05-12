import 'dart:async';

/// A handler that decides whether a navigation away from the currently-
/// active screen is allowed. Returns `true` to allow the navigation,
/// `false` to block it (e.g. user picked "Cancel" in a save-or-discard
/// dialog).
typedef LeaveGuardHandler = Future<bool> Function();

/// Single-slot registry for an async "may I leave?" handler.
///
/// Screens with unsaved state register a handler in `didChangeDependencies`
/// and clear it in `dispose`. The bottom-nav shell calls [canLeave] before
/// switching branches via `goBranch`. `PopScope` handles the back-button
/// path on its own — the guard is specifically for the cases `PopScope`
/// can't see, primarily tab switches in `StatefulShellRoute`.
///
/// One handler at a time is enough — only one editor with unsaved state is
/// mounted in this app at any given moment. Registering a second handler
/// just replaces the first (last-write-wins).
class NavigationGuard {
  LeaveGuardHandler? _handler;

  void register(LeaveGuardHandler? handler) {
    _handler = handler;
  }

  Future<bool> canLeave() async {
    final handler = _handler;
    if (handler == null) return true;
    return handler();
  }
}
