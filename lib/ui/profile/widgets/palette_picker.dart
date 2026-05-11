import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: EdgeInsets.zero,
      children: [
        for (final p in kSurfacePalettes)
          _PaletteSwatch(
            palette: p,
            selected: p.id == selectedId,
            onTap: () => onSelected(p.id),
            outlineColor: scheme.outline,
          ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
    required this.outlineColor,
  });

  final SurfacePalette palette;
  final bool selected;
  final VoidCallback onTap;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = palette.surfaceFor(
      isDark ? Brightness.dark : Brightness.light,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : outlineColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _Dot(color: palette.defaultSecondary),
            const SizedBox(width: 4),
            _Dot(color: palette.defaultAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                palette.displayName,
                style: TextStyle(
                  color: surface.computeLuminance() > 0.5
                      ? const Color(0xFF000000)
                      : const Color(0xFFFFFFFF),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              AppIcon(
                PhosphorIconsFill.checkCircle,
                size: 18,
                color: scheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0x33000000),
          width: 1,
        ),
      ),
    );
  }
}
