import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/settings_nav_tile.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/settings_section.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/swatch_grid_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/theme/color_hex.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
              children: [
                SettingsNavTile(
                  icon: HugeIcons.strokeRoundedPaintBrush01,
                  title: 'Theme',
                  route: Routes.themeSettings,
                ),
              ],
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
                  icon: HugeIcons.strokeRoundedDashboardSquareSetting,
                  title: 'Manage Layout',
                  route: Routes.layouts,
                ),
              ],
            ),
            SettingsSection(
              label: "Blocks",
              children: [
                SettingsNavTile(
                  icon: HugeIcons.strokeRoundedBlockGame,
                  title: 'Manage Blocks',
                  route: Routes.blockSettings,
                ),
              ],
            ),
            SettingsSection(
              label: "Subscription",
              children: [
                ListenableBuilder(
                  listenable: AppDependencies.of(
                    context,
                  ).subscriptionRepository,
                  builder: (context, _) {
                    final isPro = AppDependencies.of(
                      context,
                    ).subscriptionRepository.isPro;
                    return SettingsNavTile(
                      icon: HugeIcons.strokeRoundedCrown,
                      title: isPro ? 'Manage subscription' : 'Upgrade to Pro',
                      route: Routes.subscription,
                    );
                  },
                ),
              ],
            ),
            // BETA-ONLY: surfaces "Unlock all days" outside the
            // kDebugMode-gated Debug section so beta testers can reach
            // it in release builds. Remove this whole section before
            // the 1.0 launch.
            SettingsSection(
              label: "Beta testing",
              children: [
                SwitchListTile(
                  secondary: AppIcon(HugeIcons.strokeRoundedSquareUnlock01),
                  title: const Text('Unlock all days'),
                  subtitle: const Text(
                    'Select and edit any past or future day',
                  ),
                  value: debug.unlockAllDays,
                  onChanged: debug.setUnlockAllDays,
                ),
              ],
            ),
            if (kDebugMode)
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
                      secondary: AppIcon(
                        HugeIcons.strokeRoundedCheckmarkCircle02,
                      ),
                      title: const Text('Show Done on expanded blocks'),
                      subtitle: const Text(
                        'Developer affordance — expanded blocks normally dismiss by tapping the backdrop.',
                      ),
                      value: debug.showExpandedBlockDoneButton,
                      onChanged: debug.setShowExpandedBlockDoneButton,
                    ),
                    ListenableBuilder(
                      listenable: deps.subscriptionRepository,
                      builder: (context, _) {
                        final subs = deps.subscriptionRepository;
                        return SwitchListTile(
                          secondary: AppIcon(HugeIcons.strokeRoundedCrown),
                          title: const Text('Simulate free account'),
                          subtitle: const Text(
                            'Ignore your Pro entitlement to test the free '
                            'experience. Does not cancel or affect your real '
                            'subscription.',
                          ),
                          value: subs.debugForceFree,
                          onChanged: subs.setDebugForceFree,
                        );
                      },
                    ),
                    Builder(
                      builder: (context) {
                        final errorColor = Theme.of(context).colorScheme.error;
                        final primaryColor = Theme.of(
                          context,
                        ).colorScheme.primary;
                        return Column(
                          children: [
                            ListTile(
                              leading: AppIcon(
                                HugeIcons.strokeRoundedDatabaseAdd,
                                color: primaryColor,
                              ),
                              title: const Text('Generate sample entries'),
                              subtitle: const Text(
                                'Fill ~400 past days with random moods + text '
                                'to populate the statistics charts.',
                              ),
                              onTap: () => _generateSampleEntries(context),
                            ),
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
                            ListTile(
                              leading: AppIcon(
                                HugeIcons.strokeRoundedGift,
                                color: primaryColor,
                              ),
                              title: const Text('Reset streak reward'),
                              subtitle: const Text(
                                'Clear the claimed reward so the 7-day '
                                'milestone is claimable again.',
                              ),
                              onTap: () => _resetStreakReward(context),
                            ),
                            ListTile(
                              leading: AppIcon(
                                HugeIcons.strokeRoundedRefresh,
                                color: errorColor,
                              ),
                              title: Text(
                                'Reset everything',
                                style: TextStyle(color: errorColor),
                              ),
                              subtitle: const Text(
                                'Wipe all entries + layouts and reset the '
                                'streak reward. Cannot be undone.',
                              ),
                              onTap: () => _confirmAndResetEverything(context),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            const _VersionFooter(),
          ],
        ),
      ),
    );
  }
}

/// App version indicator pinned to the bottom of the Settings list. Reads
/// the version + build number from the bundle via `package_info_plus`. In a
/// dev build (`kDebugMode`) a "DEBUG" tag is appended so QA can tell at a
/// glance which flavour they are running.
class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          if (info == null) return const SizedBox(height: 20);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Version ${info.version} (${info.buildNumber})',
                style: labelStyle,
              ),
              if (kDebugMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DEBUG',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
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
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          label: 'Cancel',
        ),
        AppButton(
          variant: AppButtonVariant.primary,
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          label: confirmLabel,
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
  showToast(
    context,
    deleted == 0
        ? 'No entries to delete'
        : 'Deleted $deleted entr${deleted == 1 ? 'y' : 'ies'}',
    kind: ToastKind.success,
  );
}

/// Debug action (GUS-35): populate the statistics charts with realistic
/// data. Generates randomized sample entries across the past ~400 days
/// (skipping days that already have an entry). Non-destructive.
Future<void> _generateSampleEntries(BuildContext context) async {
  final created = await AppDependencies.of(
    context,
  ).journalRepository.debugGenerateSampleEntries();
  if (!context.mounted) return;
  showToast(
    context,
    created == 0
        ? 'No entries created (those days already have entries)'
        : 'Generated $created sample entr${created == 1 ? 'y' : 'ies'}',
    kind: ToastKind.success,
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
  showToast(
    context,
    deleted == 0
        ? 'No layouts to delete'
        : 'Deleted $deleted layout${deleted == 1 ? '' : 's'}; default restored',
    kind: ToastKind.success,
  );
}

/// Debug action: clear the streak-reward state so the 7-day milestone
/// becomes claimable again (re-test the reward flow). Non-destructive to
/// journal content — only resets the reward's "claimed" derivation +
/// unlocked-item gating, so no confirm dialog.
Future<void> _resetStreakReward(BuildContext context) async {
  await AppDependencies.of(context).streakRewardSettings.reset();
  if (!context.mounted) return;
  showToast(
    context,
    'Streak reward reset — claim it again from Statistics',
    kind: ToastKind.success,
  );
}

/// Debug action: nuke all test data in one shot — every entry, every
/// layout (a fresh default is re-seeded), and the streak-reward state.
/// Destructive: behind a confirm dialog.
Future<void> _confirmAndResetEverything(BuildContext context) async {
  final ok = await _confirmDestructive(
    context,
    title: 'Reset everything?',
    message:
        'This deletes every journal entry and every layout (a fresh '
        '"Default" layout is recreated) and resets the streak reward. This '
        'cannot be undone.',
    confirmLabel: 'Reset everything',
  );
  if (!ok || !context.mounted) return;
  final deps = AppDependencies.of(context);
  final deletedEntries = await deps.journalRepository.deleteAllEntries();
  final deletedLayouts = await deps.layoutRepository.deleteAllLayouts();
  await deps.streakRewardSettings.reset();
  if (!context.mounted) return;
  showToast(
    context,
    'Reset: $deletedEntries entr${deletedEntries == 1 ? 'y' : 'ies'}, '
    '$deletedLayouts layout${deletedLayouts == 1 ? '' : 's'}, '
    'and the streak reward',
    kind: ToastKind.success,
  );
}

class _PostItStyleSection extends StatelessWidget {
  const _PostItStyleSection({required this.theme});

  final ThemeSettings theme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colorEnabled = theme.blockColorEnabled;
    final palette = theme.postItPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          secondary: AppIcon(HugeIcons.strokeRoundedRotate01),
          title: const Text('Block rotation'),
          subtitle: const Text('Tilt each block slightly.'),
          value: theme.blockRotationEnabled,
          onChanged: theme.setBlockRotationEnabled,
        ),
        SwitchListTile(
          secondary: AppIcon(HugeIcons.strokeRoundedMove),
          title: const Text('Block offset'),
          subtitle: const Text('Nudge each block off-center.'),
          value: theme.blockOffsetEnabled,
          onChanged: theme.setBlockOffsetEnabled,
        ),
        SwitchListTile(
          secondary: AppIcon(HugeIcons.strokeRoundedColorPicker),
          title: const Text('Block color'),
          subtitle: const Text('Tint each block with the palette below.'),
          value: colorEnabled,
          onChanged: theme.setBlockColorEnabled,
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
            opacity: colorEnabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !colorEnabled,
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
        child: AppIcon(
          HugeIcons.strokeRoundedPlusSign,
          size: 18,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

