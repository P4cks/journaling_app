import 'package:flutter/material.dart';

import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Visual style of an [AppButton].
///
/// All three share the same pill shape and borderless silhouette — only the
/// fill / foreground colours differ:
/// - [secondary] (default): `colorScheme.secondary` fill, `onSurface`
///   foreground. The app's standard button.
/// - [primary]: `colorScheme.primary` fill, `onPrimary` foreground — solid
///   call-to-action emphasis.
/// - [text]: transparent fill, `onSurface` foreground — low-emphasis actions
///   (dialog "Cancel", inline "Retry", etc.).
enum AppButtonVariant { secondary, primary, text }

/// The app's single button primitive. Wraps [FilledButton] so ripple, focus,
/// pressed and disabled states come for free, then layers on the house style:
/// a 100%-rounded ([StadiumBorder]) pill with **no border**, an optional
/// prefix [icon] slot, and (by default) the secondary fill with the font
/// colour on top.
///
/// The prefix/trailing icons are rendered through [AppIcon] **without an
/// explicit colour**, so they inherit the button's resolved foreground (and
/// its disabled dimming) from the surrounding `IconTheme` — i.e. the icon
/// always matches the label/font colour.
///
/// Use [variant] to pick the emphasis, or [backgroundColor] / [foregroundColor]
/// to override the resolved colours for one-off cases (e.g. an error-tinted
/// "Sign out" or a greyed-out disabled affordance). A null [onPressed] renders
/// the button disabled.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.secondary,
    this.expand = false,
    this.busy = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Button caption.
  final String label;

  /// Tap handler. Null disables the button (label + icons dim automatically).
  final VoidCallback? onPressed;

  /// Optional leading icon, drawn before the label in the foreground colour.
  final HugeIconData? icon;

  /// Optional trailing icon, drawn after the label in the foreground colour.
  final HugeIconData? trailingIcon;

  /// Emphasis / colour role. Defaults to [AppButtonVariant.secondary].
  final AppButtonVariant variant;

  /// When true the button stretches to fill its horizontal constraints.
  final bool expand;

  /// When true the prefix slot shows a spinner instead of [icon] and the
  /// button is disabled (taps ignored) for the duration of the work.
  final bool busy;

  /// Overrides the variant's background colour.
  final Color? backgroundColor;

  /// Overrides the variant's foreground colour (label + icons).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color background, Color foreground) = switch (variant) {
      AppButtonVariant.secondary => (
        backgroundColor ?? scheme.secondary,
        foregroundColor ?? scheme.onSurface,
      ),
      AppButtonVariant.primary => (
        backgroundColor ?? scheme.primary,
        foregroundColor ?? scheme.onPrimary,
      ),
      AppButtonVariant.text => (
        backgroundColor ?? Colors.transparent,
        foregroundColor ?? scheme.onSurface,
      ),
    };

    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      // Keep the text variant fill-less even when disabled (otherwise the
      // disabled default paints a faint pill behind the label).
      disabledBackgroundColor: variant == AppButtonVariant.text
          ? Colors.transparent
          : null,
      elevation: 0,
      shape: const StadiumBorder(),
    );

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          AppIcon(icon!, size: 18),
          const SizedBox(width: 8),
        ],
        // Not wrapped in Flexible/Expanded: those need bounded width, which
        // an unbounded Row (e.g. inside a Wrap or another min-size Row) does
        // not provide and would throw. The label sizes to content; it
        // ellipsizes only when the parent already constrains the width.
        Text(label, overflow: TextOverflow.ellipsis),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          AppIcon(trailingIcon!, size: 18),
        ],
      ],
    );

    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: style,
      child: child,
    );
  }
}
