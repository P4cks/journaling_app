import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_grid.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_render_context.dart';
import 'package:journaling_app_rewrite/ui/blocks/photo_block/photo_block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_section/text_section_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Translucent overlay route that morphs an in-grid block into a
/// full-screen 1:1 expanded view via [Hero]. The Hero tag matches the
/// in-grid source via [blockHeroTag].
///
/// **Layout** — always square, max ~92 % of screen width. Top-aligned
/// when the keyboard is up (so the block stays visible above the
/// keyboard), centered otherwise.
///
/// **Initial state — [BlockEditState.display].** The block opens
/// read-only-ish:
/// - Text / prompt / todo: rendered as text (no focus, no keyboard).
/// - Carousels (mood / weather / customCarousel): the picker is
///   immediately interactive — that's the only thing the route exists
///   to do for them.
/// - Photo, memory: tap-to-fire-action — the inner widget shows the
///   image / snapshot; tapping it opens the action sheet / jumps.
/// - Location: long-press inside the bigger map drops a pin.
///
/// **Engaging text blocks**: tapping the body inside the route
/// promotes the inner state to [BlockEditState.editing] — the field
/// focuses and the keyboard rises.
///
/// **Two-step dismiss** (keyboard blocks only):
///   `display` ──tap backdrop──> `Navigator.pop`
///   `editing` ──tap backdrop──> `display` (unfocus + re-center)
///   `display` ──tap backdrop──> `Navigator.pop`
///
/// Other blocks dismiss with a single backdrop tap. A developer-only
/// "Done" button shows when `DebugSettings.showExpandedBlockDoneButton`
/// is true.
class ExpandedBlockRoute extends PageRoute<void> {
  ExpandedBlockRoute({
    required this.data,
    required this.onChanged,
    this.onJumpToDate,
    this.isTextSection = false,
  });

  final JournalBlockData data;
  final ValueChanged<JournalBlockData>? onChanged;

  /// For memory blocks: jump to the source entry. Wired so the
  /// expanded memory tap inside the route can navigate.
  final ValueChanged<DateTime>? onJumpToDate;

  /// True when the source is a full-width `SectionKind.text` section.
  /// Renders the text directly on the blur — no card chrome — per the
  /// design rule "text section in expanded mode has no rectangular
  /// background".
  final bool isTextSection;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Dismiss expanded block';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ExpandedBlockBody(
      data: data,
      onChanged: onChanged,
      onJumpToDate: onJumpToDate,
      animation: animation,
      isTextSection: isTextSection,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The body reads `animation.value` directly to drive backdrop
    // blur strength. Hero handles the source → destination flight on
    // its own.
    return child;
  }
}

class _ExpandedBlockBody extends StatefulWidget {
  const _ExpandedBlockBody({
    required this.data,
    required this.onChanged,
    required this.onJumpToDate,
    required this.animation,
    required this.isTextSection,
  });

  final JournalBlockData data;
  final ValueChanged<JournalBlockData>? onChanged;
  final ValueChanged<DateTime>? onJumpToDate;
  final Animation<double> animation;
  final bool isTextSection;

  @override
  State<_ExpandedBlockBody> createState() => _ExpandedBlockBodyState();
}

class _ExpandedBlockBodyState extends State<_ExpandedBlockBody> {
  /// Local copy of the block data — updated on every emit from the
  /// inner body so carousel picks / typed text show in the route's
  /// own widgets without waiting for the host VM's rebuild to flow
  /// back. Also forwarded to `widget.onChanged` so the VM persists.
  late JournalBlockData _data;

  /// Whether the inner content is in editing state.
  /// - Text blocks: false initially, flips to true on first content
  ///   tap (display → editing per the two-step model).
  /// - Carousels: true from mount (picker is the whole point).
  /// - Action blocks: stays false; tap fires the action via
  ///   [_fireActionBlock].
  /// - Location: false (the map is its own interactive surface).
  bool _innerEditing = false;

  bool get _isKeyboardBlock => _data.type.usesKeyboardOnEdit;
  bool get _isCarousel =>
      _data.type == BlockType.moodTracker ||
      _data.type == BlockType.weatherManual ||
      _data.type == BlockType.customCarousel;
  bool get _isActionBlock => _data.type.isActionBlock;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    if (_isCarousel) {
      _innerEditing = true;
    }
  }

  void _onInnerChanged(JournalBlockData updated) {
    if (mounted && updated != _data) {
      setState(() => _data = updated);
    }
    widget.onChanged?.call(updated);
  }

  Future<void> _onContentTap() async {
    if (_isActionBlock) {
      await _fireActionBlock();
      return;
    }
    if (_isKeyboardBlock || widget.isTextSection) {
      if (!_innerEditing) {
        setState(() => _innerEditing = true);
      }
    }
  }

  Future<void> _fireActionBlock() async {
    switch (_data.type) {
      case BlockType.photoBlock:
        await firePhotoBlockAction(context, _data, _onInnerChanged);
        break;
      // Memory navigation lives behind its own "Navigate to that day"
      // button inside the body (see MemoryBlockWidget). The body
      // itself doesn't fire on tap.
      default:
        break;
    }
  }

  void _onBackdropTap() {
    if ((_isKeyboardBlock || widget.isTextSection) && _innerEditing) {
      // Step 1 of 2: unfocus → keyboard slides out → re-center.
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _innerEditing = false);
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mediaSize = MediaQuery.sizeOf(context);
    final debug = AppDependencies.of(context).debugSettings;
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Square block size — held constant across keyboard up/down so
    // the block doesn't rescale when the user taps to edit. When the
    // keyboard rises we just shift the alignment to top so the block
    // stays visible above the keyboard; the side length doesn't
    // change.
    //
    // The height budget uses the FULL safe-area height (ignoring
    // viewInsets) — that way `maxSide` is the same value before and
    // after the keyboard appears. With `Align(topCenter)` the box
    // sits at the top; the keyboard overlays the now-empty space
    // below it.
    final fullHeight =
        mediaSize.height - MediaQuery.paddingOf(context).vertical;
    final maxByHeight = fullHeight * 0.55;
    final maxByWidth = mediaSize.width * 0.92;
    final maxSide = maxByHeight < maxByWidth ? maxByHeight : maxByWidth;

    // Top-align when the keyboard is up so the block sits above it;
    // center otherwise.
    final alignment =
        keyboardUp ? Alignment.topCenter : Alignment.center;
    final topPad = keyboardUp
        ? MediaQuery.paddingOf(context).top + 24.0
        : 0.0;

    final Widget heroChild = widget.isTextSection
        ? _ExpandedTextSection(
            data: _data,
            onChanged: _onInnerChanged,
            editing: _innerEditing,
          )
        : _ExpandedBlockCard(
            data: _data,
            innerEditing: _innerEditing,
            onChanged: _onInnerChanged,
            onJumpToDate: widget.onJumpToDate,
          );

    final centered = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.isTextSection ? mediaSize.width - 16 : maxSide,
        maxHeight: maxSide,
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Hero(
          tag: blockHeroTag(_data.id),
          child: Material(
            // Transparent Material so TextField / InkWell descendants
            // find a Material ancestor — PostItBlock / BlockChrome
            // uses a plain Container, not Material.
            type: MaterialType.transparency,
            child: heroChild,
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final t = widget.animation.value.clamp(0.0, 1.0);
        final sigma = 14.0 * t;
        return Stack(
          children: [
            // Blurred backdrop. Tap handler runs the two-step dismiss
            // state machine for keyboard blocks; single-tap dismiss
            // for everything else.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBackdropTap,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: ColoredBox(
                    color: scheme.surface.withValues(alpha: 0.18 * t),
                  ),
                ),
              ),
            ),
            // Expanded block content. Outer GestureDetector uses
            // `deferToChild` so inner interactive widgets (carousel
            // PageView, map gestures) win their own taps; we only
            // catch taps that fall through.
            Padding(
              padding: EdgeInsets.only(top: topPad, bottom: 16),
              child: Align(
                alignment: alignment,
                child: Opacity(
                  opacity: t,
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onTap: _onContentTap,
                    child: centered,
                  ),
                ),
              ),
            ),
            if (debug.showExpandedBlockDoneButton)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                right: 8,
                child: Opacity(
                  opacity: t,
                  child: Material(
                    color: scheme.surface,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          'Done',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Standard expanded card — `BlockChrome` wrapping the block widget,
/// scaled inside a 1:1 box. Reads `host: expanded` so the chrome
/// suppresses the outline (the Hero + blurred backdrop are the
/// affordance).
class _ExpandedBlockCard extends StatelessWidget {
  const _ExpandedBlockCard({
    required this.data,
    required this.innerEditing,
    required this.onChanged,
    required this.onJumpToDate,
  });

  final JournalBlockData data;
  final bool innerEditing;
  final ValueChanged<JournalBlockData> onChanged;
  final ValueChanged<DateTime>? onJumpToDate;

  @override
  Widget build(BuildContext context) {
    return BlockChrome(
      visuals: data.visuals,
      host: BlockHostKind.expanded,
      isEditing: innerEditing,
      child: BlockWidget(
        data: data,
        mode: BlockMode.editable,
        onChanged: onChanged,
        onJumpToDate: onJumpToDate,
        editing: innerEditing,
        expanded: true,
      ),
    );
  }
}

/// Expanded text section — text directly on the blurred backdrop, no
/// rectangular card chrome. Passes `expanded: true` so the section
/// renders with `expands: true` (fills the constraints), top-left
/// alignment, and no outline.
class _ExpandedTextSection extends StatelessWidget {
  const _ExpandedTextSection({
    required this.data,
    required this.onChanged,
    required this.editing,
  });

  final JournalBlockData data;
  final ValueChanged<JournalBlockData> onChanged;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: TextSectionWidget(
        data: data,
        mode: BlockMode.editable,
        onChanged: onChanged,
        editing: editing,
        expanded: true,
      ),
    );
  }
}
