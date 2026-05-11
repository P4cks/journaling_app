import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/palette_picker.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/swatch_grid_picker.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/theme_mode_selector.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final debug = deps.debugSettings;
    final theme = deps.themeSettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          _SectionHeader(label: 'Appearance'),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ThemeModeSelector(
                      value: theme.themeMode,
                      onChanged: theme.setThemeMode,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Surface palette',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  PalettePicker(
                    selectedId: theme.paletteId,
                    onSelected: theme.setPaletteId,
                  ),
                ],
              ),
            ),
          ),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => _ColorTile(
              label: 'Secondary color',
              subtitle: '30% of the theme — surfaces, chips, accents',
              current: theme.effectiveSecondary,
              isOverridden: theme.secondaryOverride != null,
              onTap: () async {
                final result = await showSwatchPicker(
                  context,
                  title: 'Pick secondary',
                  initial: theme.effectiveSecondary,
                );
                if (result == null) return;
                if (result.isReset) {
                  await theme.setSecondaryOverride(null);
                } else if (result.color != null) {
                  await theme.setSecondaryOverride(result.color);
                }
              },
            ),
          ),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => _ColorTile(
              label: 'Accent color',
              subtitle: '10% of the theme — highlights and active states',
              current: theme.effectiveAccent,
              isOverridden: theme.accentOverride != null,
              onTap: () async {
                final result = await showSwatchPicker(
                  context,
                  title: 'Pick accent',
                  initial: theme.effectiveAccent,
                );
                if (result == null) return;
                if (result.isReset) {
                  await theme.setAccentOverride(null);
                } else if (result.color != null) {
                  await theme.setAccentOverride(result.color);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const AppIcon(PhosphorIconsDuotone.squaresFour),
            title: const Text('Layouts'),
            subtitle: const Text('Manage journal entry templates'),
            trailing: const AppIcon(PhosphorIconsDuotone.caretRight),
            onTap: () => context.push(Routes.layouts),
          ),
          const Divider(),
          _SectionHeader(label: 'Debug'),
          ListenableBuilder(
            listenable: debug,
            builder: (context, _) => SwitchListTile(
              secondary: const AppIcon(PhosphorIconsDuotone.lockKeyOpen),
              title: const Text('Unlock all days'),
              subtitle: const Text(
                'Select and edit any past or future day',
              ),
              value: debug.unlockAllDays,
              onChanged: debug.setUnlockAllDays,
            ),
          ),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) {
              final scheme = Theme.of(context).colorScheme;
              final overrideColor = theme.debugSurfaceOverride;
              return ListTile(
                leading: const AppIcon(PhosphorIconsDuotone.paintBucket),
                title: const Text('Override surface color'),
                subtitle: Text(
                  overrideColor == null
                      ? 'Using palette default'
                      : 'Overridden — clear to restore',
                ),
                trailing: _ColorChip(
                  color: overrideColor ?? scheme.surface,
                  outlined: overrideColor == null,
                ),
                onTap: () async {
                  final result = await showSwatchPicker(
                    context,
                    title: 'Override surface',
                    initial: overrideColor ?? scheme.surface,
                    allowFreePick: true,
                  );
                  if (result == null) return;
                  if (result.isReset) {
                    await theme.setDebugSurfaceOverride(null);
                  } else if (result.color != null) {
                    await theme.setDebugSurfaceOverride(result.color);
                  }
                },
              );
            },
          ),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => ListTile(
              leading: const AppIcon(PhosphorIconsDuotone.eyedropper),
              title: const Text('Free-pick secondary (HSL)'),
              subtitle: const Text('Bypass curated swatches'),
              trailing: _ColorChip(color: theme.effectiveSecondary),
              onTap: () async {
                final result = await showSwatchPicker(
                  context,
                  title: 'Free-pick secondary',
                  initial: theme.effectiveSecondary,
                  allowFreePick: true,
                );
                if (result == null) return;
                if (result.isReset) {
                  await theme.setSecondaryOverride(null);
                } else if (result.color != null) {
                  await theme.setSecondaryOverride(result.color);
                }
              },
            ),
          ),
          ListenableBuilder(
            listenable: theme,
            builder: (context, _) => ListTile(
              leading: const AppIcon(PhosphorIconsDuotone.eyedropper),
              title: const Text('Free-pick accent (HSL)'),
              subtitle: const Text('Bypass curated swatches'),
              trailing: _ColorChip(color: theme.effectiveAccent),
              onTap: () async {
                final result = await showSwatchPicker(
                  context,
                  title: 'Free-pick accent',
                  initial: theme.effectiveAccent,
                  allowFreePick: true,
                );
                if (result == null) return;
                if (result.isReset) {
                  await theme.setAccentOverride(null);
                } else if (result.color != null) {
                  await theme.setAccentOverride(result.color);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.label,
    required this.subtitle,
    required this.current,
    required this.isOverridden,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color current;
  final bool isOverridden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const AppIcon(PhosphorIconsDuotone.palette),
      title: Text(label),
      subtitle: Text(
        isOverridden ? '$subtitle · custom' : subtitle,
      ),
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
