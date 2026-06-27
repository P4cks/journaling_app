import 'package:flutter/material.dart';

/// Lays out [AlertDialog] action buttons **inline** — side by side, equal
/// width — instead of letting Material's default [OverflowBar] stack them
/// vertically.
///
/// `AlertDialog.actions` are placed in an [OverflowBar], which only keeps
/// buttons on one row while their *natural* widths fit; the moment they don't,
/// it drops to one-button-per-line. The app's filled-pill [AppButton]s are
/// wide, so a two- or three-button dialog routinely overflowed and rendered as
/// a vertical stack (GUS-83). Splitting the available width equally guarantees
/// the buttons stay on a single row regardless of label length or screen size.
///
/// Pass this as the **single** child of `AlertDialog.actions` so the dialog's
/// own [OverflowBar] has exactly one child and nothing to overflow:
///
/// ```dart
/// actions: [
///   AppDialogActions(
///     children: [
///       AppButton(variant: AppButtonVariant.text, onPressed: ..., label: 'Cancel'),
///       AppButton(variant: AppButtonVariant.primary, onPressed: ..., label: 'Save'),
///     ],
///   ),
/// ],
/// ```
///
/// Each child is wrapped in an [Expanded], so buttons need not (and should not)
/// set `expand: true` themselves — the [Expanded] supplies the bounded width
/// and the button fills it.
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({super.key, required this.children, this.spacing = 8});

  /// The action buttons, laid out left-to-right with equal widths.
  final List<Widget> children;

  /// Horizontal gap between adjacent buttons.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final row = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) row.add(SizedBox(width: spacing));
      row.add(Expanded(child: children[i]));
    }
    return Row(children: row);
  }
}
