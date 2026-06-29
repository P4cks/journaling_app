import 'package:flutter/material.dart';

/// Lays out [AlertDialog] action buttons **inline** — on a single row aligned
/// to the end — instead of Material's default `OverflowBar`, which stacks the
/// app's wide filled-pill [AppButton]s vertically as soon as their natural
/// widths don't fit on one line (GUS-83).
///
/// Two things keep the inline row both compact and robust:
///
/// 1. A local [Theme] tightens the metrics of every button variant (smaller
///    horizontal padding, [VisualDensity.compact],
///    [MaterialTapTargetSize.shrinkWrap]) so two or three pill buttons fit
///    across a default ~280px dialog. The buttons keep their **natural** width
///    (no [Expanded]/[Flexible]), so a button is never squeezed narrower than
///    its label — which previously made the label overflow *inside* the pill.
/// 2. A [Wrap] (not a [Row]) holds the buttons: if even compact buttons can't
///    fit — e.g. three long labels on a very narrow screen — it gracefully
///    drops to a second line instead of throwing a `RenderFlex` overflow.
///
/// Pass this as the **single** child of `AlertDialog.actions`:
///
/// ```dart
/// actions: [
///   AppDialogActions(children: [cancelButton, saveButton]),
/// ],
/// ```
class AppDialogActions extends StatelessWidget {
  const AppDialogActions({super.key, required this.children, this.spacing = 8});

  /// The action buttons, laid out left-to-right and aligned to the end.
  final List<Widget> children;

  /// Gap between adjacent buttons (and between rows, if they wrap).
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Compact metrics shared by every button variant so several filled-pill
    // buttons fit on one row inside a default-width AlertDialog. Applied via a
    // local Theme so it reaches AppButton (a FilledButton under the hood) as
    // well as any raw TextButton/FilledButton/ElevatedButton passed in.
    const padding = EdgeInsets.symmetric(horizontal: 12);
    const density = VisualDensity.compact;
    const tap = MaterialTapTargetSize.shrinkWrap;

    final filled = FilledButton.styleFrom(
      padding: padding,
      visualDensity: density,
      tapTargetSize: tap,
    );
    final text = TextButton.styleFrom(
      padding: padding,
      visualDensity: density,
      tapTargetSize: tap,
    );
    final elevated = ElevatedButton.styleFrom(
      padding: padding,
      visualDensity: density,
      tapTargetSize: tap,
    );

    return Theme(
      data: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: filled.merge(base.filledButtonTheme.style),
        ),
        textButtonTheme: TextButtonThemeData(
          style: text.merge(base.textButtonTheme.style),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: elevated.merge(base.elevatedButtonTheme.style),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: spacing,
        runSpacing: spacing,
        children: children,
      ),
    );
  }
}
