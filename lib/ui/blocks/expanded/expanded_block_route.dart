import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/blocks/post_it_block.dart';
import 'package:journaling_app_rewrite/ui/blocks/text_section/text_section_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Overlay route that shows one block expanded over a blurred backdrop
/// of the underlying journal entry.
///
/// `opaque: false` keeps the previous route painted, so a
/// [BackdropFilter] blurs it. The route dismisses by tapping the
/// blurred backdrop (saves are per-keystroke — content is already
/// current) or by pressing the system back. A developer-only "Done"
/// button can be enabled via [DebugSettings.showExpandedBlockDoneButton].
class ExpandedBlockRoute extends PageRoute<void> {
  ExpandedBlockRoute({
    required this.data,
    required this.onChanged,
    this.isTextSection = false,
  });

  final JournalBlockData data;
  final ValueChanged<JournalBlockData>? onChanged;

  /// True when the source is a full-width [SectionKind.text] section
  /// rather than a 1×1 grid block. Renders [TextSectionWidget] at full
  /// width instead of the [PostItBlock] card.
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
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ExpandedBlockBody(
      data: data,
      onChanged: onChanged,
      animation: animation,
      isTextSection: isTextSection,
      isKeyboardBlock: data.type.usesKeyboardOnEdit,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // The body reads `animation.value` directly to drive its blur
    // strength + inner scale/opacity, so no outer transition wrapper.
    return child;
  }
}

class _ExpandedBlockBody extends StatefulWidget {
  const _ExpandedBlockBody({
    required this.data,
    required this.onChanged,
    required this.animation,
    required this.isTextSection,
    required this.isKeyboardBlock,
  });

  final JournalBlockData data;
  final ValueChanged<JournalBlockData>? onChanged;
  final Animation<double> animation;
  final bool isTextSection;
  final bool isKeyboardBlock;

  @override
  State<_ExpandedBlockBody> createState() => _ExpandedBlockBodyState();
}

class _ExpandedBlockBodyState extends State<_ExpandedBlockBody> {
  late JournalBlockData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  /// Forwarding `onChanged`. Keeps `_data` in sync with whatever the
  /// inner block emits (carousel pick, text edit, etc.) so the rebuild
  /// shows the new selection (e.g. the centered carousel page scales
  /// up because `selected == option` now holds). Also forwards to the
  /// host's `onChanged` so the VM / Hive write happens as before.
  void _onInnerChanged(JournalBlockData updated) {
    if (mounted && updated != _data) {
      setState(() => _data = updated);
    }
    widget.onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mediaSize = MediaQuery.sizeOf(context);
    final debug = AppDependencies.of(context).debugSettings;

    final keyboardLike = widget.isKeyboardBlock || widget.isTextSection;
    final alignment = keyboardLike ? Alignment.topCenter : Alignment.center;
    final topPad = keyboardLike
        ? MediaQuery.paddingOf(context).top + 24.0
        : 0.0;
    final maxWidth = widget.isTextSection
        ? mediaSize.width - 16.0
        : mediaSize.width * 0.92;
    final maxHeight = keyboardLike
        ? mediaSize.height * 0.45
        : mediaSize.height * 0.6;

    // PostItBlock supplies a Container, not a Material — descendants
    // like TextField / InkWell / ListTile need a Material ancestor to
    // render correctly (otherwise: yellow-underlined unstyled text,
    // and "No Material widget found" exceptions for InkWell ripples).
    // The grid path gets this from MainJournalScreen's body Material;
    // the route doesn't, so we provide it here.
    final Widget expandedContent = widget.isTextSection
        ? Material(
            color: scheme.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: TextSectionWidget(
                data: _data,
                mode: BlockMode.editable,
                onChanged: _onInnerChanged,
                editing: true,
              ),
            ),
          )
        : AspectRatio(
            aspectRatio: widget.isKeyboardBlock ? 1.2 : 1.0,
            child: Material(
              type: MaterialType.transparency,
              child: PostItBlock(
                visuals: _data.visuals,
                isEditing: true,
                child: BlockWidget(
                  data: _data,
                  mode: BlockMode.editable,
                  onChanged: _onInnerChanged,
                  editing: true,
                ),
              ),
            ),
          );

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final t = widget.animation.value.clamp(0.0, 1.0);
        final sigma = 12.0 * t;
        return Stack(
          children: [
            // Blurred backdrop — tapping anywhere outside the centered
            // block dismisses the route.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: ColoredBox(
                    color: scheme.surface.withValues(alpha: 0.18 * t),
                  ),
                ),
              ),
            ),
            // Expanded block. Wrapped in a no-op GestureDetector so
            // taps on the block don't bubble up to the backdrop's
            // dismiss handler.
            SafeArea(
              top: !keyboardLike,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPad,
                  left: 16,
                  right: 16,
                ),
                child: Align(
                  alignment: alignment,
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.92 + (0.08 * t),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                          maxHeight: maxHeight,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: expandedContent,
                        ),
                      ),
                    ),
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
