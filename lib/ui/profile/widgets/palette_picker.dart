import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PalettePicker extends StatelessWidget {
  const PalettePicker({
    super.key,
    required this.selectedId,
    required this.palettes,
    required this.onSelected,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String selectedId;
  final List<SurfacePalette> palettes;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<SurfacePalette> onEdit;
  final ValueChanged<SurfacePalette> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: palettes.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == palettes.length) {
            return _AddThemeTile(onTap: onAdd);
          }
          final palette = palettes[index];
          return _PaletteTile(
            palette: palette,
            selected: palette.id == selectedId,
            outlineColor: scheme.outline,
            onTap: () => onSelected(palette.id),
            onEdit: palette.isCustom ? () => onEdit(palette) : null,
            onDelete: palette.isCustom ? () => onDelete(palette) : null,
          );
        },
      ),
    );
  }
}

class _AddThemeTile extends StatelessWidget {
  const _AddThemeTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon(PhosphorIconsDuotone.plusCircle, size: 18),
            const SizedBox(width: 8),
            Text('Add theme', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.outlineColor,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final SurfacePalette palette;
  final bool selected;
  final Color outlineColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = palette.surfaceFor(
      isDark ? Brightness.dark : Brightness.light,
    );
    final foreground = surface.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final canEdit = onEdit != null && onDelete != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : outlineColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Dot(color: palette.defaultSecondary),
                const SizedBox(width: 4),
                _Dot(color: palette.defaultAccent),
                const SizedBox(width: 4),
                _Dot(color: palette.defaultTextColor ?? foreground),
                const Spacer(),
                if (selected)
                  AppIcon(
                    PhosphorIconsFill.checkCircle,
                    size: 18,
                    color: scheme.primary,
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    palette.displayName,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 12),
                  _TileIconButton(
                    icon: PhosphorIconsDuotone.pencilSimple,
                    color: foreground,
                    onTap: onEdit!,
                  ),
                  _TileIconButton(
                    icon: PhosphorIconsDuotone.trash,
                    color: foreground,
                    onTap: onDelete!,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TileIconButton extends StatelessWidget {
  const _TileIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AppIcon(icon, size: 18, color: color, secondaryColor: color),
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
        border: Border.all(color: const Color(0x33000000), width: 1),
      ),
    );
  }
}
