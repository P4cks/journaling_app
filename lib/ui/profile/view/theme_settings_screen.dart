import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/palette_picker.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/swatch_grid_picker.dart';
import 'package:journaling_app_rewrite/ui/theme/app_theme.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';

/// Dedicated theming page (GUS-27). Top: a live mock-journal-entry
/// preview rendered with the selected theme. Below: a vertical theme
/// list (built-in Light/Dark defaults + custom themes) with add/edit/
/// delete, Pro-gated for free users (built-ins stay free).
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final theme = deps.themeSettings;
    final subscriptions = deps.subscriptionRepository;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: ListenableBuilder(
        listenable: Listenable.merge([theme, subscriptions]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeaderPlain(label: 'Preview'),
            const SizedBox(height: 12),
            ThemeMockPreview(palette: theme.palette),
            const SizedBox(height: 24),
            const SectionHeaderPlain(label: 'Theme'),
            const SizedBox(height: 12),
            PalettePicker(
              selectedId: theme.paletteId,
              palettes: theme.palettes,
              onSelected: theme.setPaletteId,
              onAdd: () => _addPalette(context, theme),
              onEdit: (palette) => _editPalette(context, theme, palette),
              onDelete: (palette) => theme.deleteCustomPalette(palette.id),
              locked: !subscriptions.isPro,
              onUnlock: () => requirePro(subscriptions, context: context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPalette(BuildContext context, ThemeSettings theme) async {
    final palette = await showThemeEditorSheet(
      context,
      title: 'Add theme',
      initial: theme.customPaletteTemplate(),
    );
    if (palette == null) return;
    await theme.addCustomPalette(palette);
  }

  Future<void> _editPalette(
    BuildContext context,
    ThemeSettings theme,
    SurfacePalette palette,
  ) async {
    final updated = await showThemeEditorSheet(
      context,
      title: 'Edit theme',
      initial: palette,
    );
    if (updated == null) return;
    await theme.updateCustomPalette(updated);
  }
}

/// Thin wrapper so the page can reuse the accent-tinted section header
/// without the `SettingsSection`'s row padding + divider chrome.
class SectionHeaderPlain extends StatelessWidget {
  const SectionHeaderPlain({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => SectionHeader(label: label);
}

/// A miniature mock journal entry rendered with the candidate [palette]'s
/// `ThemeData`, so theme changes are visible immediately (GUS-27). Fully
/// self-contained — no repositories — so it renders the candidate theme
/// directly via a nested `Theme`.
class ThemeMockPreview extends StatelessWidget {
  const ThemeMockPreview({super.key, required this.palette});

  final SurfacePalette palette;

  @override
  Widget build(BuildContext context) {
    final data = buildAppTheme(palette);
    final scheme = data.colorScheme;
    return Theme(
      data: data,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date header row.
            Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedCalendar03,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today',
                  style: data.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppIcon(
                  HugeIcons.strokeRoundedMoreHorizontal,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Text block card.
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Morning pages',
                    style: data.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _GreekLine(color: scheme.onSurfaceVariant, widthFactor: 1.0),
                  const SizedBox(height: 6),
                  _GreekLine(color: scheme.onSurfaceVariant, widthFactor: 0.85),
                  const SizedBox(height: 6),
                  _GreekLine(color: scheme.onSurfaceVariant, widthFactor: 0.6),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Mood / post-it block row.
            Row(
              children: [
                Expanded(
                  child: _MiniBlock(
                    color: scheme.primaryContainer,
                    onColor: scheme.onPrimaryContainer,
                    label: 'Happy',
                    glyph: '🙂',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniBlock(
                    color: scheme.secondaryContainer,
                    onColor: scheme.onSecondaryContainer,
                    label: 'Calm',
                    glyph: '🌿',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniBlock(
                    color: scheme.tertiaryContainer,
                    onColor: scheme.onTertiaryContainer,
                    label: 'Note',
                    glyph: '📌',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GreekLine extends StatelessWidget {
  const _GreekLine({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _MiniBlock extends StatelessWidget {
  const _MiniBlock({
    required this.color,
    required this.onColor,
    required this.label,
    required this.glyph,
  });

  final Color color;
  final Color onColor;
  final String label;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Text(glyph, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: onColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Half-sheet add/edit UI for a custom theme. Edits name, brightness,
/// surface, secondary, accent, and text colour, returning a
/// `SurfacePalette` for `ThemeSettings` to persist (GUS-27).
Future<SurfacePalette?> showThemeEditorSheet(
  BuildContext context, {
  required String title,
  required SurfacePalette initial,
}) {
  return showModalBottomSheet<SurfacePalette>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) =>
        _ThemeEditorSheet(title: title, initial: initial),
  );
}

class _ThemeEditorSheet extends StatefulWidget {
  const _ThemeEditorSheet({required this.title, required this.initial});

  final String title;
  final SurfacePalette initial;

  @override
  State<_ThemeEditorSheet> createState() => _ThemeEditorSheetState();
}

class _ThemeEditorSheetState extends State<_ThemeEditorSheet> {
  late final TextEditingController _nameController;
  late Brightness _brightness;
  late Color _surface;
  late Color _secondary;
  late Color _accent;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.displayName);
    _brightness = widget.initial.brightness;
    _surface = widget.initial.surface;
    _secondary = widget.initial.defaultSecondary;
    _accent = widget.initial.defaultAccent;
    _textColor = widget.initial.defaultTextColor ?? const Color(0xFFFFFFFF);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleMedium),
                ),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Theme name',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<Brightness>(
                segments: [
                  ButtonSegment(
                    value: Brightness.light,
                    label: const Text('Light'),
                    icon: AppIcon(HugeIcons.strokeRoundedSun01),
                  ),
                  ButtonSegment(
                    value: Brightness.dark,
                    label: const Text('Dark'),
                    icon: AppIcon(HugeIcons.strokeRoundedMoon),
                  ),
                ],
                selected: {_brightness},
                onSelectionChanged: (s) =>
                    setState(() => _brightness = s.first),
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: 16),
            _ThemePreview(
              surface: _surface,
              secondary: _secondary,
              accent: _accent,
              textColor: _textColor,
            ),
            const SizedBox(height: 8),
            _ColorTile(
              icon: HugeIcons.strokeRoundedPaintBrush01,
              label: 'Surface tint',
              subtitle: 'Base color for app surfaces',
              current: _surface,
              onTap: () => _pickColor(
                title: 'Pick surface tint',
                initial: _surface,
                onPicked: (color) => _surface = color,
              ),
            ),
            _ColorTile(
              icon: HugeIcons.strokeRoundedColorPicker,
              label: 'Secondary color',
              subtitle: '30% of the theme — surfaces, chips, accents',
              current: _secondary,
              onTap: () => _pickColor(
                title: 'Pick secondary',
                initial: _secondary,
                onPicked: (color) => _secondary = color,
              ),
            ),
            _ColorTile(
              icon: HugeIcons.strokeRoundedSparkles,
              label: 'Accent color',
              subtitle: '10% of the theme — highlights and active states',
              current: _accent,
              onTap: () => _pickColor(
                title: 'Pick accent',
                initial: _accent,
                onPicked: (color) => _accent = color,
              ),
            ),
            _ColorTile(
              icon: HugeIcons.strokeRoundedTextFont,
              label: 'Text color',
              subtitle: 'Primary font color for this theme',
              current: _textColor,
              onTap: () => _pickColor(
                title: 'Pick text color',
                initial: _textColor,
                onPicked: (color) => _textColor = color,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickColor({
    required String title,
    required Color initial,
    required ValueChanged<Color> onPicked,
  }) async {
    final result = await showSwatchPicker(
      context,
      title: title,
      initial: initial,
      allowFreePick: true,
    );
    if (result?.color == null) return;
    setState(() => onPicked(result!.color!));
  }

  void _save() {
    final name = _nameController.text.trim();
    Navigator.of(context).pop(
      widget.initial.copyWith(
        displayName: name.isEmpty ? 'New theme' : name,
        seed: _accent,
        brightness: _brightness,
        surface: _surface,
        defaultSecondary: _secondary,
        defaultAccent: _accent,
        defaultTextColor: _textColor,
        isCustom: true,
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.surface,
    required this.secondary,
    required this.accent,
    required this.textColor,
  });

  final Color surface;
  final Color secondary;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _ColorChip(color: secondary),
          const SizedBox(width: 8),
          _ColorChip(color: accent),
        ],
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.current,
    required this.onTap,
  });

  final HugeIconData icon;
  final String label;
  final String subtitle;
  final Color current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(icon),
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: _ColorChip(color: current),
      onTap: onTap,
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant),
      ),
    );
  }
}
