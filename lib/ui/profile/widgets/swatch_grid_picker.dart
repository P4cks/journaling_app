import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
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
                    selected: _isClose(_hsl.toColor(), c),
                    onTap: () => _setColor(c),
                  ),
              ],
            ),
            if (widget.allowFreePick) ...[
              const SizedBox(height: 16),
              _LabelSlider(
                label: 'Hue',
                value: _hsl.hue,
                min: 0,
                max: 360,
                onChanged: (v) => setState(() => _hsl = _hsl.withHue(v)),
              ),
              _LabelSlider(
                label: 'Saturation',
                value: _hsl.saturation,
                min: 0,
                max: 1,
                onChanged: (v) => setState(
                  () => _hsl = _hsl.withSaturation(v),
                ),
              ),
              _LabelSlider(
                label: 'Lightness',
                value: _hsl.lightness,
                min: 0,
                max: 1,
                onChanged: (v) => setState(
                  () => _hsl = _hsl.withLightness(v),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(SwatchResult.reset()),
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            SwatchResult.color(_current),
          ),
          child: const Text('Apply'),
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
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
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

class _LabelSlider extends StatelessWidget {
  const _LabelSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
