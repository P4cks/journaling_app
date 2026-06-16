import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/wannado_item.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Vertical auto-rotating carousel for `SectionKind.wannado` sections
/// (GUS-8 / GUS-42 / GUS-45, PRO). **Pure display** — it renders one of
/// the user's `WannadoDefinition`s (a named list managed in Block
/// Settings), resolved by [definitionId], and rotates through that
/// definition's items one at a time on a timer. There is no per-item
/// done / check-off state: a wanna-do is an aspiration the list simply
/// surfaces, identical on every entry the section appears in.
///
/// Definitions live in the [BlockSettings] registry (persisted in the
/// settings box), so the widget grabs `blockSettings` from
/// [AppDependencies] and rebuilds via `ListenableBuilder` whenever the
/// registry changes — editing the definition's title/items in Block
/// Settings reflects in every section that references it immediately.
///
/// When [definitionId] is `null` (a legacy wannado section saved before
/// the definition-backed model) or names a definition that no longer
/// exists (deleted), the card renders a placeholder instead of crashing.
///
/// Rotation:
/// * **Auto** — a [Timer.periodic] advances one item every
///   [_rotateInterval] (paused while the list has 0–1 items, since
///   there's nothing to rotate).
/// * **Manual** — the section is a vertical `PageView`, so the user can
///   swipe up/down to move between items. A manual swipe resets the
///   auto-timer so it doesn't immediately yank the page away.
///
/// To loop seamlessly the `PageView` starts at a large virtual page and
/// the builder maps `index % items.length` back onto the real list.
class WannadoSectionWidget extends StatefulWidget {
  const WannadoSectionWidget({super.key, required this.definitionId});

  /// Id of the `WannadoDefinition` to render. `null` for legacy sections
  /// → placeholder.
  final String? definitionId;

  @override
  State<WannadoSectionWidget> createState() => _WannadoSectionWidgetState();
}

class _WannadoSectionWidgetState extends State<WannadoSectionWidget> {
  static const Duration _rotateInterval = Duration(seconds: 4);
  static const Duration _animDuration = Duration(milliseconds: 450);
  // Large base offset so the carousel can loop in both directions
  // without ever hitting an edge in practice.
  static const int _virtualBase = 10000;

  late final PageController _controller;
  Timer? _timer;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _virtualBase);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// (Re)arm the rotation timer for [count] items. No timer runs while
  /// there are 0–1 items (nothing to rotate between).
  void _syncTimer(int count) {
    if (count == _itemCount && _timer != null) return;
    _itemCount = count;
    _timer?.cancel();
    if (count <= 1) {
      _timer = null;
      return;
    }
    _timer = Timer.periodic(_rotateInterval, (_) => _advance());
  }

  void _advance() {
    if (!_controller.hasClients) return;
    final current = _controller.page?.round() ?? _virtualBase;
    _controller.animateToPage(
      current + 1,
      duration: _animDuration,
      curve: Curves.easeInOut,
    );
  }

  /// A manual swipe should not be immediately overridden by the auto
  /// timer — restart it so the user gets a full interval to read.
  void _onUserSwipe() {
    if (_itemCount > 1) {
      final count = _itemCount;
      _itemCount = -1; // force _syncTimer to re-arm
      _syncTimer(count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockSettings = AppDependencies.of(context).blockSettings;
    return ListenableBuilder(
      listenable: blockSettings,
      builder: (context, _) {
        final definitionId = widget.definitionId;
        final definition = definitionId == null
            ? null
            : blockSettings.findWannadoDefinition(definitionId);
        final items = definition?.items ?? const <WannadoItem>[];
        _syncTimer(items.length);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _WannadoCard(
            items: items,
            missing: definition == null,
            controller: _controller,
            virtualBase: _virtualBase,
            onUserSwipe: _onUserSwipe,
          ),
        );
      },
    );
  }
}

class _WannadoCard extends StatelessWidget {
  const _WannadoCard({
    required this.items,
    required this.missing,
    required this.controller,
    required this.virtualBase,
    required this.onUserSwipe,
  });

  final List<WannadoItem> items;

  /// True when the section's definition couldn't be resolved (legacy
  /// section with no id, or the definition was deleted) — distinct from a
  /// resolved-but-empty definition.
  final bool missing;
  final PageController controller;
  final int virtualBase;
  final VoidCallback onUserSwipe;

  static const double _height = 76;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget content;
    if (items.isEmpty) {
      content = Center(
        child: Text(
          missing
              ? 'Pick a wanna-do list for this section'
              : 'Add items to this wanna-do list in Block settings',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      content = NotificationListener<ScrollStartNotification>(
        onNotification: (notification) {
          if (notification.dragDetails != null) onUserSwipe();
          return false;
        },
        child: PageView.builder(
          controller: controller,
          scrollDirection: Axis.vertical,
          // Single item → no looping (would animate to the same item).
          physics: items.length <= 1
              ? const NeverScrollableScrollPhysics()
              : null,
          itemBuilder: (context, index) {
            final item = items[index % items.length];
            return _WannadoItemView(item: item);
          },
        ),
      );
    }

    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AppIcon(
            HugeIcons.strokeRoundedSparkles,
            size: 20,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _WannadoItemView extends StatelessWidget {
  const _WannadoItemView({required this.item});

  final WannadoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        item.text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
