import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/settings_nav_tile.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/settings_section.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/palette_picker.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/swatch_grid_picker.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/theme_mode_selector.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:journaling_app_rewrite/ui/theme/surface_palette.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final debug = deps.debugSettings;
    final theme = deps.themeSettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: debug,
        builder: (context, _) => ListView(
          children: [
            SettingsSection(
              label: "Appearance",
              children: [_AppearanceSettingsContent(theme: theme)],
            ),
            SettingsSection(
              label: "Post-it style",
              children: [
                ListenableBuilder(
                  listenable: theme,
                  builder: (context, _) => _PostItStyleSection(theme: theme),
                ),
              ],
            ),
            SettingsSection(
              label: "Journal templates",
              children: [
                SettingsNavTile(
                  icon: HugeIcons.strokeRoundedGrid,
                  title: 'Manage templates',
                  route: Routes.layouts,
                ),
              ],
            ),
            SettingsSection(
              label: "Blocks",
              children: [
                SettingsNavTile(
                  icon: HugeIcons.strokeRoundedFilterHorizontal,
                  title: 'Configure blocks',
                  route: Routes.blockSettings,
                ),
                SwitchListTile(
                  secondary: AppIcon(HugeIcons.strokeRoundedMaximize01),
                  title: const Text('Expand block when editing'),
                  subtitle: const Text(
                    'Double-tap a block to open it over a blurred journal entry.',
                  ),
                  value: debug.expandBlockOnEdit,
                  onChanged: debug.setExpandBlockOnEdit,
                ),
              ],
            ),
            SettingsSection(
              label: "Debug",
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 30),
                  child: SwitchListTile(
                    secondary: AppIcon(HugeIcons.strokeRoundedBug01),
                    title: const Text('Show debug menu'),
                    value: debug.debugMenuVisible,
                    onChanged: debug.setDebugMenuVisible,
                  ),
                ),
                if (debug.debugMenuVisible) ...[
                  SwitchListTile(
                    secondary: AppIcon(HugeIcons.strokeRoundedSquareUnlock01),
                    title: const Text('Unlock all days'),
                    subtitle: const Text(
                      'Select and edit any past or future day',
                    ),
                    value: debug.unlockAllDays,
                    onChanged: debug.setUnlockAllDays,
                  ),
                  SwitchListTile(
                    secondary: AppIcon(HugeIcons.strokeRoundedCheckmarkCircle02),
                    title: const Text('Show Done on expanded blocks'),
                    subtitle: const Text(
                      'Developer affordance — expanded blocks normally dismiss by tapping the backdrop.',
                    ),
                    value: debug.showExpandedBlockDoneButton,
                    onChanged: debug.setShowExpandedBlockDoneButton,
                  ),
                  _DebugColorPickerTile(
                    theme: theme,
                    icon: HugeIcons.strokeRoundedPaintBucket,
                    title: 'Override surface color',
                    dialogTitle: 'Override surface',
                    colorBuilder: (context) =>
                        theme.debugSurfaceOverride ??
                        Theme.of(context).colorScheme.surface,
                    subtitleBuilder: () => theme.debugSurfaceOverride == null
                        ? 'Using palette default'
                        : 'Overridden — clear to restore',
                    outlinedBuilder: () => theme.debugSurfaceOverride == null,
                    onChange: theme.setDebugSurfaceOverride,
                  ),
                  _DebugColorPickerTile(
                    theme: theme,
                    icon: HugeIcons.strokeRoundedColorPicker,
                    title: 'Free-pick secondary (HSL)',
                    dialogTitle: 'Free-pick secondary',
                    colorBuilder: (_) => theme.effectiveSecondary,
                    subtitleBuilder: () => 'Bypass curated swatches',
                    onChange: theme.setSecondaryOverride,
                  ),
                  _DebugColorPickerTile(
                    theme: theme,
                    icon: HugeIcons.strokeRoundedColorPicker,
                    title: 'Free-pick accent (HSL)',
                    dialogTitle: 'Free-pick accent',
                    colorBuilder: (_) => theme.effectiveAccent,
                    subtitleBuilder: () => 'Bypass curated swatches',
                    onChange: theme.setAccentOverride,
                  ),
                  Builder(
                    builder: (context) {
                      final errorColor = Theme.of(context).colorScheme.error;
                      return Column(
                        children: [
                          ListTile(
                            leading: AppIcon(
                              HugeIcons.strokeRoundedDelete02,
                              color: errorColor,
                            ),
                            title: Text(
                              'Delete all entries',
                              style: TextStyle(color: errorColor),
                            ),
                            subtitle: const Text(
                              'Wipe every journal entry. Cannot be undone.',
                            ),
                            onTap: () => _confirmAndDeleteAllEntries(context),
                          ),
                          ListTile(
                            leading: AppIcon(
                              HugeIcons.strokeRoundedDelete02,
                              color: errorColor,
                            ),
                            title: Text(
                              'Delete all layouts',
                              style: TextStyle(color: errorColor),
                            ),
                            subtitle: const Text(
                              'Wipe every layout. A fresh default is recreated.',
                            ),
                            onTap: () => _confirmAndDeleteAllLayouts(context),
                          ),
                        ],
                      );
                    },
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

/// Renders the live theme controls for the Settings appearance section.
///
/// The [theme] input is the app-wide settings notifier. This widget returns a
/// vertical set of controls and rebuilds when the theme mode, selected palette,
/// or custom-palette list changes.
class _AppearanceSettingsContent extends StatelessWidget {
  const _AppearanceSettingsContent({required this.theme});

  final ThemeSettings theme;

  /// Opens the theme editor with a blank custom-palette template.
  ///
  /// [context] supplies the modal route. The output is a completed future after
  /// either canceling or persisting the new palette.
  Future<void> _addPalette(BuildContext context) async {
    final palette = await showThemeEditorSheet(
      context,
      title: 'Add theme',
      initial: theme.customPaletteTemplate(),
    );
    if (palette == null) return;
    await theme.addCustomPalette(palette);
  }

  /// Opens the theme editor for an existing custom palette.
  ///
  /// [context] supplies the modal route, and [palette] is the palette being
  /// edited. The output is a completed future after canceling or saving the
  /// updated palette.
  Future<void> _editPalette(
    BuildContext context,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ThemeModeSelector(
              value: theme.themeMode,
              onChanged: theme.setThemeMode,
            ),
          ),
          const SizedBox(height: 16),
          Text('Theme', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          PalettePicker(
            selectedId: theme.paletteId,
            palettes: theme.palettes,
            onSelected: theme.setPaletteId,
            onAdd: () => _addPalette(context),
            onEdit: (palette) => _editPalette(context, palette),
            onDelete: (palette) => theme.deleteCustomPalette(palette.id),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final errorColor = Theme.of(context).colorScheme.error;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: errorColor),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

Future<void> _confirmAndDeleteAllEntries(BuildContext context) async {
  final ok = await _confirmDestructive(
    context,
    title: 'Delete all entries?',
    message:
        'This deletes every journal entry. This cannot be undone. Layouts and settings are kept.',
    confirmLabel: 'Delete entries',
  );
  if (!ok || !context.mounted) return;
  final deleted = await AppDependencies.of(
    context,
  ).journalRepository.deleteAllEntries();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        deleted == 0
            ? 'No entries to delete'
            : 'Deleted $deleted entr${deleted == 1 ? 'y' : 'ies'}',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> _confirmAndDeleteAllLayouts(BuildContext context) async {
  final ok = await _confirmDestructive(
    context,
    title: 'Delete all layouts?',
    message:
        'This deletes every layout. A fresh "Default" layout is recreated immediately so you can keep journaling. Entries are not affected.',
    confirmLabel: 'Delete layouts',
  );
  if (!ok || !context.mounted) return;
  final deleted = await AppDependencies.of(
    context,
  ).layoutRepository.deleteAllLayouts();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        deleted == 0
            ? 'No layouts to delete'
            : 'Deleted $deleted layout${deleted == 1 ? '' : 's'}; default restored',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _PostItStyleSection extends StatelessWidget {
  const _PostItStyleSection({required this.theme});

  final ThemeSettings theme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = theme.postItModeEnabled;
    final palette = theme.postItPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: AppIcon(HugeIcons.strokeRoundedNote),
          title: const Text('Playful post-it style'),
          subtitle: const Text(
            'Slight rotation, offset, and color on each block.',
          ),
          value: enabled,
          onChanged: theme.setPostItModeEnabled,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Block colors',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AnimatedOpacity(
            opacity: enabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !enabled,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < palette.length; i++)
                    _PostItSwatch(
                      hex: palette[i],
                      onRemove: () => theme.removePostItColorAt(i),
                    ),
                  _AddPostItSwatch(
                    onPick: () async {
                      final result = await showSwatchPicker(
                        context,
                        title: 'Add post-it color',
                        initial: scheme.surfaceContainerHigh,
                        allowFreePick: true,
                      );
                      if (result == null || result.isReset) return;
                      final picked = result.color;
                      if (picked != null) {
                        await theme.addPostItColor(picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (palette.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'No colors yet — blocks will use the default surface color.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _PostItSwatch extends StatelessWidget {
  const _PostItSwatch({required this.hex, required this.onRemove});

  final String hex;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hex) ?? Theme.of(context).colorScheme.surface;
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: InkResponse(
            onTap: onRemove,
            radius: 16,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.4),
                ),
              ),
              child: AppIcon(
                HugeIcons.strokeRoundedCancel01,
                size: 12,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPostItSwatch extends StatelessWidget {
  const _AddPostItSwatch({required this.onPick});

  final Future<void> Function() onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onPick,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.6),
            style: BorderStyle.solid,
          ),
        ),
        alignment: Alignment.center,
        child: AppIcon(HugeIcons.strokeRoundedPlusSign, size: 18, color: scheme.onSurface),
      ),
    );
  }
}

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
  late Color _surface;
  late Color _secondary;
  late Color _accent;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.displayName);
    _surface = widget.initial.surfaceFor(Brightness.dark);
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
      initialChildSize: 0.56,
      minChildSize: 0.45,
      maxChildSize: 0.9,
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
              isOverridden: true,
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
              isOverridden: true,
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
              isOverridden: true,
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
              isOverridden: true,
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
        darkSurface: _surface,
        lightSurface: _surface,
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
    required this.isOverridden,
    required this.onTap,
  });

  final HugeIconData icon;
  final String label;
  final String subtitle;
  final Color current;
  final bool isOverridden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppIcon(icon),
      title: Text(label),
      subtitle: Text(isOverridden ? '$subtitle · custom' : subtitle),
      trailing: _ColorChip(color: current),
      onTap: onTap,
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.color, this.outlined = false});

  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: outlined ? scheme.outline : scheme.outlineVariant,
          width: outlined ? 2 : 1,
        ),
      ),
    );
  }
}

/// One row in the Debug section's color-picker stack.
///
/// Each tile subscribes to [ThemeSettings] independently (per the
/// per-section `ListenableBuilder` convention documented in
/// `profile/CLAUDE.md` — don't try to consolidate into a single
/// top-level builder), opens [showSwatchPicker] with `allowFreePick:
/// true` on tap, and routes the result through [onChange] so the
/// caller decides which override to flip.
///
/// [colorBuilder] runs inside the `ListenableBuilder` so it can read
/// both `theme` and `Theme.of(context)` — the override-surface tile
/// needs the latter for its palette fallback. [outlinedBuilder] is
/// optional; only the override-surface tile uses it (to distinguish
/// "no override set" from "override happens to equal the default").
class _DebugColorPickerTile extends StatelessWidget {
  const _DebugColorPickerTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.dialogTitle,
    required this.colorBuilder,
    required this.subtitleBuilder,
    required this.onChange,
    this.outlinedBuilder,
  });

  final ThemeSettings theme;
  final HugeIconData icon;
  final String title;
  final String dialogTitle;
  final Color Function(BuildContext) colorBuilder;
  final String Function() subtitleBuilder;
  final Future<void> Function(Color?) onChange;
  final bool Function()? outlinedBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final color = colorBuilder(context);
        final outlined = outlinedBuilder?.call() ?? false;
        return ListTile(
          leading: AppIcon(icon),
          title: Text(title),
          subtitle: Text(subtitleBuilder()),
          trailing: _ColorChip(color: color, outlined: outlined),
          onTap: () async {
            final result = await showSwatchPicker(
              context,
              title: dialogTitle,
              initial: color,
              allowFreePick: true,
            );
            if (result == null) return;
            if (result.isReset) {
              await onChange(null);
            } else if (result.color != null) {
              await onChange(result.color);
            }
          },
        );
      },
    );
  }
}
