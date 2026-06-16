import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';

/// Vertical list of theme tiles plus an Add-theme tile at the bottom
/// (GUS-27). Renders inside the Theme settings page's own scroll view,
/// so it is a non-scrolling `Column` (`shrinkWrap` semantics).
class PalettePicker extends StatelessWidget {
  const PalettePicker({
    super.key,
    required this.selectedId,
    required this.palettes,
    required this.onSelected,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.locked = false,
    this.onUnlock,
  });

  final String selectedId;
  final List<SurfacePalette> palettes;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<SurfacePalette> onEdit;
  final ValueChanged<SurfacePalette> onDelete;

  /// When true, theme *customization* is Pro-gated (GUS-26). The built-in
  /// Light/Dark defaults stay free and selectable so free users can still
  /// switch base brightness; only **custom** tiles and the Add-theme tile
  /// present the paywall via [onUnlock] and proceed on success.
  final bool locked;

  /// Presents the paywall and resolves `true` when the user is (now) Pro.
  /// Required to be non-null when [locked] is true.
  final Future<bool> Function()? onUnlock;

  /// Runs [action] directly when unlocked; otherwise presents the paywall
  /// and runs it only on a successful purchase.
  Future<void> _guard(VoidCallback action) async {
    if (!locked) {
      action();
      return;
    }
    final ok = await onUnlock?.call() ?? false;
    if (ok) action();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final palette in palettes) ...[
          Builder(
            builder: (context) {
              final selected = palette.id == selectedId;
              // Built-in defaults are always free; only custom tiles lock.
              final tileLocked = locked && palette.isCustom && !selected;
              return _PaletteTile(
                palette: palette,
                selected: selected,
                locked: tileLocked,
                outlineColor: scheme.outline,
                onTap: palette.isCustom
                    ? () => _guard(() => onSelected(palette.id))
                    : () => onSelected(palette.id),
                onEdit: palette.isCustom
                    ? () => _guard(() => onEdit(palette))
                    : null,
                onDelete: palette.isCustom
                    ? () => _guard(() => onDelete(palette))
                    : null,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        _AddThemeTile(locked: locked, onTap: () => _guard(onAdd)),
      ],
    );
  }
}

class _AddThemeTile extends StatelessWidget {
  const _AddThemeTile({required this.onTap, this.locked = false});

  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = locked ? scheme.onSurfaceVariant.withValues(alpha: 0.6) : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (locked)
              const ProLockBadge(compact: true)
            else
              AppIcon(HugeIcons.strokeRoundedPlusSignCircle, size: 18),
            const SizedBox(width: 8),
            Text(
              'Add theme',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: fg),
            ),
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
    this.locked = false,
  });

  final SurfacePalette palette;
  final bool selected;
  final bool locked;
  final Color outlineColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = palette.surface;
    final foreground = surface.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final canEdit = onEdit != null && onDelete != null;

    final tile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            const SizedBox(width: 6),
            _Dot(color: palette.defaultAccent),
            const SizedBox(width: 6),
            _Dot(color: palette.defaultTextColor ?? foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                palette.displayName,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (selected)
              AppIcon(
                HugeIcons.strokeRoundedCheckmarkCircle01,
                size: 18,
                color: scheme.primary,
              ),
            if (canEdit) ...[
              const SizedBox(width: 8),
              _TileIconButton(
                icon: HugeIcons.strokeRoundedPencil,
                color: foreground,
                onTap: onEdit!,
              ),
              _TileIconButton(
                icon: HugeIcons.strokeRoundedDelete02,
                color: foreground,
                onTap: onDelete!,
              ),
            ],
          ],
        ),
      ),
    );

    if (!locked) return tile;
    return Stack(
      children: [
        Opacity(opacity: 0.45, child: tile),
        const Positioned(top: 8, right: 8, child: ProLockBadge(compact: true)),
      ],
    );
  }
}

class _TileIconButton extends StatelessWidget {
  const _TileIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final HugeIconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AppIcon(icon, size: 18, color: color),
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
