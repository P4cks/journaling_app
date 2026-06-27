import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dialog_actions.dart';

const _kSwatches = <Color>[
  Color(0xFFFFB86B), // amber
  Color(0xFFE6855F), // coral
  Color(0xFFEF6F8B), // rose
  Color(0xFFC679E0), // magenta
  Color(0xFF9B8CFF), // lavender
  Color(0xFF6FA8FF), // sky
  Color(0xFF7DD3FC), // cyan
  Color(0xFF6BD0BF), // mint
  Color(0xFF8EE1C5), // teal
  Color(0xFFB6D36B), // olive
  Color(0xFFE4B363), // honey
  Color(0xFFB0B6C2), // slate
];

/// Lightness steps used to generate the "more shades" row of the
/// currently-picked hue (Apple-style). Dark → light, left → right.
const _kShadeLightness = <double>[0.30, 0.42, 0.54, 0.66, 0.76, 0.85, 0.92];

/// Shows a swatch grid dialog. Returns the chosen color, or `null` if the
/// user reset / cancelled. The result is wrapped in a sentinel to
/// distinguish "reset to default" from "dismissed without changes":
///
/// - `SwatchResult.color(c)` — user picked a color
/// - `SwatchResult.reset()` — user chose Reset to default
/// - `null` — user dismissed
Future<SwatchResult?> showSwatchPicker(
  BuildContext context, {
  required String title,
  required Color? initial,
  bool allowFreePick = false,
}) {
  return showDialog<SwatchResult>(
    context: context,
    builder: (ctx) => _SwatchDialog(
      title: title,
      initial: initial,
      allowFreePick: allowFreePick,
    ),
  );
}

/// Three-valued outcome from [showSwatchPicker], used so callers can
/// distinguish "user picked a color", "user reset to the palette
/// default", and "user dismissed without committing." The picker's
/// `Future` resolves to `null` for dismiss, a [SwatchResult.color] for
/// a pick, and a [SwatchResult.reset] for an explicit reset.
///
/// Don't conflate the three: callers need all three branches to
/// preserve the difference between "leave the override alone" and
/// "clear the override". Settings tiles read this pattern as
/// `null → do nothing`, `isReset → setXxxOverride(null)`,
/// `color != null → setXxxOverride(color)`.
class SwatchResult {
  const SwatchResult._(this.color, this.isReset);
  factory SwatchResult.color(Color c) => SwatchResult._(c, false);
  factory SwatchResult.reset() => const SwatchResult._(null, true);

  final Color? color;
  final bool isReset;
}

class _SwatchDialog extends StatefulWidget {
  const _SwatchDialog({
    required this.title,
    required this.initial,
    required this.allowFreePick,
  });

  final String title;
  final Color? initial;
  final bool allowFreePick;

  @override
  State<_SwatchDialog> createState() => _SwatchDialogState();
}

class _SwatchDialogState extends State<_SwatchDialog> {
  late HSLColor _hsl;

  @override
  void initState() {
    super.initState();
    final start = widget.initial ?? _kSwatches.first;
    _hsl = HSLColor.fromColor(start);
  }

  Color get _current => _hsl.toColor();

  void _setColor(Color c) => setState(() => _hsl = HSLColor.fromColor(c));

  /// The "more shades" of the current hue: same hue + saturation, varying
  /// lightness. Saturation is floored so greys still produce a visible
  /// spread instead of a row of near-identical neutrals.
  List<Color> get _shades {
    final hue = _hsl.hue;
    final sat = _hsl.saturation < 0.15 ? 0.45 : _hsl.saturation;
    return [
      for (final l in _kShadeLightness)
        HSLColor.fromAHSL(1, hue, sat, l).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _current,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in _kSwatches)
                    _Swatch(
                      color: c,
                      selected: _isClose(_current, c),
                      onTap: () => _setColor(c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Shades',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _shades)
                    _Swatch(
                      color: c,
                      size: 30,
                      selected: _isClose(_current, c),
                      onTap: () => _setColor(c),
                    ),
                ],
              ),
              if (widget.allowFreePick) ...[
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text('Advanced'),
                    children: [
                      HueRingPicker(
                        pickerColor: _current,
                        onColorChanged: _setColor,
                        enableAlpha: false,
                        displayThumbColor: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AppDialogActions(
          children: [
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(SwatchResult.reset()),
              label: 'Reset',
            ),
            AppButton(
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(context).pop(),
              label: 'Cancel',
            ),
            AppButton(
              variant: AppButtonVariant.primary,
              onPressed: () =>
                  Navigator.of(context).pop(SwatchResult.color(_current)),
              label: 'Apply',
            ),
          ],
        ),
      ],
    );
  }

  bool _isClose(Color a, Color b) =>
      ((a.r - b.r).abs() < 0.01) &&
      ((a.g - b.g).abs() < 0.01) &&
      ((a.b - b.b).abs() < 0.01);
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    this.size = 36,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
