import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';

/// Modal bottom sheet that lets the user pick an icon for a layout.
///
/// Returns the chosen icon's `name` (a stable Phosphor identifier like
/// `"squaresFour"`), or `null` if the sheet was dismissed without
/// picking. The caller should treat a returned name of
/// [kDefaultLayoutIconName] the same as `null` if they want to persist
/// "no preference" — both render the same default glyph.
Future<String?> showLayoutIconPicker(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick an icon',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final icon in kLayoutIcons)
                    _IconTile(
                      icon: icon,
                      selected: icon.name == selected,
                      onTap: () =>
                          Navigator.of(sheetContext).pop(icon.name),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final LayoutIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: icon.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color:
                selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: AppIcon(
            selected ? icon.fill : icon.duotone,
            size: 28,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
