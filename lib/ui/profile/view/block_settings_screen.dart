import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/habit_definition.dart';
import 'package:journaling_app_rewrite/data/model/wannado_definition.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/icon_or_emoji.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/settings_section.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/prompt_block_settings.dart';

/// Block-type-global configuration screen.
///
/// All edits are kept as drafts in [BlockSettingsViewModel] and only
/// persisted via [_maybeSaveOnLeave] when the user tries to leave the
/// screen (back gesture, AppBar back, or any pop). Cancel / Discard /
/// Save mirrors the layout editor's pattern at
/// [LayoutEditorScreen](../../layouts/view/layout_editor_screen.dart).
class BlockSettingsScreen extends StatefulWidget {
  const BlockSettingsScreen({super.key});

  @override
  State<BlockSettingsScreen> createState() => _BlockSettingsScreenState();
}

class _BlockSettingsScreenState extends State<BlockSettingsScreen> {
  BlockSettingsViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = BlockSettingsViewModel(settings: deps.blockSettings);
      _viewModel!.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<bool> _maybeSaveOnLeave() async {
    final vm = _viewModel;
    if (vm == null || !vm.isDirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('Save your block settings before leaving?'),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            label: 'Cancel',
          ),
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            label: 'Discard',
          ),
          AppButton(
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            label: 'Save',
          ),
        ],
      ),
    );
    if (!mounted) return false;
    switch (choice) {
      case 'discard':
        return true;
      case 'save':
        if (!vm.canSave) {
          showToast(
            context,
            'Fix the highlighted fields before saving',
            kind: ToastKind.error,
          );
          return false;
        }
        await vm.save();
        return true;
      default:
        return false;
    }
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop) return;
    final canLeave = await _maybeSaveOnLeave();
    if (!mounted || !canLeave) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(title: const Text('Block settings')),
        body: ListView(
          children: [
            SettingsSection(
              label: 'Prompt Block',
              children: [PromptBlockSettings(vm: vm)],
            ),
            SettingsSection(
              label: 'Carousel Blocks',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show titles above carousels'),
                  subtitle: const Text(
                    'Applies to mood, weather, and custom carousels.',
                  ),
                  value: vm.carouselTitlesEnabled,
                  onChanged: vm.setCarouselTitlesEnabled,
                ),
                _CustomCarouselList(
                  settings: AppDependencies.of(context).blockSettings,
                  layoutRepository: AppDependencies.of(
                    context,
                  ).layoutRepository,
                  maybeSaveOnLeave: _maybeSaveOnLeave,
                ),
              ],
            ),
            SettingsSection(
              label: 'Habit Blocks',
              children: [
                _HabitList(
                  settings: AppDependencies.of(context).blockSettings,
                  maybeSaveOnLeave: _maybeSaveOnLeave,
                ),
              ],
            ),
            SettingsSection(
              label: 'Wanna-do Carousels',
              children: [
                _WannadoCarouselList(
                  settings: AppDependencies.of(context).blockSettings,
                  layoutRepository: AppDependencies.of(
                    context,
                  ).layoutRepository,
                  maybeSaveOnLeave: _maybeSaveOnLeave,
                ),
              ],
            ),
            SettingsSection(
              label: 'Memory Block',
              children: [
                _MemoryEligibleTypesPicker(
                  settings: AppDependencies.of(context).blockSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select for the block types that a memory block may snapshot
/// from. Writes directly to [BlockSettings] (not draft state) — the
/// `_CustomCarouselList` next door uses the same pattern. The list is
/// limited to block types whose snapshots actually render in
/// `MemoryBlockWidget._renderSnapshot`; widening it requires adding
/// matching render cases.
class _MemoryEligibleTypesPicker extends StatelessWidget {
  const _MemoryEligibleTypesPicker({required this.settings});

  final BlockSettings settings;

  /// Block types the user can opt into / out of. Mirrors the switch
  /// cases supported by `MemoryBlockWidget._renderSnapshot`.
  static const List<BlockType> _supportedTypes = [
    BlockType.textBlock,
    BlockType.moodTracker,
    BlockType.photoBlock,
    BlockType.promptBlock,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final selected = settings.memoryEligibleTypes;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Which past blocks can a memory snapshot from?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final type in _supportedTypes)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(type.label),
                value: selected.contains(type),
                onChanged: (checked) {
                  final next = {...selected};
                  if (checked == true) {
                    next.add(type);
                  } else {
                    next.remove(type);
                  }
                  settings.setMemoryEligibleTypes(next);
                },
                controlAffinity: ListTileControlAffinity.leading,
                secondary: AppIcon(type.icon),
              ),
          ],
        );
      },
    );
  }
}

/// Renders the user's custom carousel definitions (Edit / Delete per
/// row) plus an "Add custom block" button at the bottom.
///
/// Subscribes to [BlockSettings] directly via `ListenableBuilder` so
/// additions / edits / deletes done in the dedicated editor screen
/// surface here without re-pushing the Block-Settings route.
///
/// Lives inside the parent "Carousel Blocks" `SettingsSection`, so this
/// widget intentionally emits no `SettingsSection` chrome of its own —
/// just a stack of per-definition rows.
///
/// The Edit / "+ New" actions push the editor onto the navigation
/// stack. Before doing so we run the parent's [maybeSaveOnLeave]
/// because pushing past a dirty Block-Settings draft would otherwise
/// hide the unsaved fields under another route. Equivalent to the
/// AppBar back behaviour, kept consistent.
class _CustomCarouselList extends StatelessWidget {
  const _CustomCarouselList({
    required this.settings,
    required this.layoutRepository,
    required this.maybeSaveOnLeave,
  });

  final BlockSettings settings;
  final LayoutRepository layoutRepository;
  final Future<bool> Function() maybeSaveOnLeave;

  // The free-tier cap on *creating* a new custom block is enforced by the
  // [AddCustomBlockButton] (GUS-34/GUS-40); this just saves any dirty draft
  // and pushes. `id == null` → new, otherwise edit (never gated).
  Future<void> _navigateToEditor(BuildContext context, String? id) async {
    final canLeave = await maybeSaveOnLeave();
    if (!context.mounted || !canLeave) return;
    if (id == null) {
      await context.push(Routes.newCustomBlock);
    } else {
      await context.push(Routes.editCustomBlockFor(id));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomCarouselDefinition def,
  ) async {
    final uses = layoutRepository.countCustomCarouselUsage(def.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete custom block?'),
        content: Text(
          uses == 0
              ? '"${def.title}" is not used by any layout. This deletes the definition; existing entry picks (if any) will render a placeholder.'
              : '"${def.title}" is used by $uses layout${uses == 1 ? '' : 's'}. '
                    'Existing entries keep their pick but the slot will render a "Deleted block" placeholder from now on. '
                    'You can edit the affected layouts afterwards.',
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: 'Cancel',
          ),
          AppButton(
            variant: AppButtonVariant.inverted,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: 'Delete',
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await settings.deleteCustomCarousel(def.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final defs = settings.customCarousels;
        // Carousels + habits share one "custom block" budget against the
        // free-tier cap (GUS-40), so count both here.
        final customBlockCount = defs.length + settings.habits.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final def in defs)
              _CustomDefinitionRow(
                definition: def,
                onEdit: () => _navigateToEditor(context, def.id),
                onDelete: () => _confirmDelete(context, def),
              ),
            ProLimitHint(
              used: customBlockCount,
              max: kFreeMaxCustomBlocks,
              noun: 'custom blocks',
              subscriptions: AppDependencies.of(context).subscriptionRepository,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AddCustomBlockButton(
                  subscriptions: AppDependencies.of(
                    context,
                  ).subscriptionRepository,
                  currentCount: customBlockCount,
                  onAddAllowed: () => _navigateToEditor(context, null),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Renders the user's wanna-do carousel definitions (Edit / Delete per
/// row) plus an "Add wanna-do carousel" button at the bottom. Mirrors
/// `_CustomCarouselList` / `_HabitList`.
///
/// Subscribes to [BlockSettings] directly via `ListenableBuilder` so
/// additions / edits / deletes done in the dedicated editor screen
/// surface here without re-pushing the Block-Settings route.
///
/// **Gating.** The wanna-do *section* is fully Pro (gated in the layout
/// editor's add-section sheet). On top of that, free users may define at
/// most [kFreeMaxWannados] carousels — the add button greys + badges and
/// routes through the paywall past the cap (handled by
/// [AddCustomBlockButton]). The Edit / "+ New" actions push the editor
/// onto the navigation stack; before doing so we run the parent's
/// [maybeSaveOnLeave] so a dirty Block-Settings draft isn't buried.
class _WannadoCarouselList extends StatelessWidget {
  const _WannadoCarouselList({
    required this.settings,
    required this.layoutRepository,
    required this.maybeSaveOnLeave,
  });

  final BlockSettings settings;
  final LayoutRepository layoutRepository;
  final Future<bool> Function() maybeSaveOnLeave;

  Future<void> _navigateToEditor(BuildContext context, String? id) async {
    final canLeave = await maybeSaveOnLeave();
    if (!context.mounted || !canLeave) return;
    if (id == null) {
      await context.push(Routes.newWannado);
    } else {
      await context.push(Routes.editWannadoFor(id));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WannadoDefinition def,
  ) async {
    final uses = layoutRepository.countWannadoUsage(def.id);
    final label = def.title.isEmpty
        ? 'this wanna-do carousel'
        : '"${def.title}"';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete wanna-do carousel?'),
        content: Text(
          uses == 0
              ? 'Deletes $label. It is not used by any layout.'
              : 'Deletes $label, used by $uses layout${uses == 1 ? '' : 's'}. '
                    'Those sections (and existing entries) will render an '
                    'empty placeholder until you point them at another list.',
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: 'Cancel',
          ),
          AppButton(
            variant: AppButtonVariant.inverted,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: 'Delete',
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await settings.deleteWannadoDefinition(def.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final defs = settings.wannadoDefinitions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Named lists shown by Wanna-do carousel sections, rotating '
                'through one item at a time. Add a section from a layout to '
                'use one.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final def in defs)
              _WannadoDefinitionRow(
                definition: def,
                onEdit: () => _navigateToEditor(context, def.id),
                onDelete: () => _confirmDelete(context, def),
              ),
            ProLimitHint(
              used: defs.length,
              max: kFreeMaxWannados,
              noun: 'wanna-do carousels',
              subscriptions: AppDependencies.of(context).subscriptionRepository,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AddCustomBlockButton(
                  subscriptions: AppDependencies.of(
                    context,
                  ).subscriptionRepository,
                  currentCount: defs.length,
                  max: kFreeMaxWannados,
                  label: 'Add wanna-do carousel',
                  onAddAllowed: () => _navigateToEditor(context, null),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WannadoDefinitionRow extends StatelessWidget {
  const _WannadoDefinitionRow({
    required this.definition,
    required this.onEdit,
    required this.onDelete,
  });

  final WannadoDefinition definition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = definition.items.length;
    final label = definition.title.isEmpty ? 'Untitled' : definition.title;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count item${count == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  expand: true,
                  onPressed: onEdit,
                  icon: HugeIcons.strokeRoundedPencil,
                  label: 'Edit',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  expand: true,
                  variant: AppButtonVariant.inverted,
                  onPressed: onDelete,
                  icon: HugeIcons.strokeRoundedDelete02,
                  label: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders the user's habit definitions (Edit / Delete per row) plus an
/// "Add habit" button at the bottom. Habits are "custom blocks" too, so
/// the free-tier creation cap counts carousels + habits together against
/// `kFreeMaxCustomBlocks` (GUS-40).
///
/// Subscribes to [BlockSettings] directly via `ListenableBuilder` (like
/// `_CustomCarouselList`) so edits in the dedicated `HabitEditorScreen`
/// surface here without re-pushing the Block-Settings route. The
/// Edit / Add actions run the parent's [maybeSaveOnLeave] first so a
/// dirty Block-Settings draft isn't buried under the pushed editor.
class _HabitList extends StatelessWidget {
  const _HabitList({required this.settings, required this.maybeSaveOnLeave});

  final BlockSettings settings;
  final Future<bool> Function() maybeSaveOnLeave;

  Future<void> _navigateToEditor(BuildContext context, String? id) async {
    final canLeave = await maybeSaveOnLeave();
    if (!context.mounted || !canLeave) return;
    if (id == null) {
      await context.push(Routes.newHabitBlock);
    } else {
      await context.push(Routes.editHabitBlockFor(id));
    }
  }

  Future<void> _confirmDelete(BuildContext context, HabitDefinition def) async {
    final label = def.title.isEmpty ? 'this habit' : '"${def.title}"';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'Deletes $label. Layouts that use it keep the slot, and existing '
          'entries keep the days you already logged — the block just renders '
          'a "Deleted block" placeholder from now on.',
        ),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: 'Cancel',
          ),
          AppButton(
            variant: AppButtonVariant.inverted,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: 'Delete',
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await settings.deleteHabit(def.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final defs = settings.habits;
        // Shared "custom block" budget with carousels (GUS-40).
        final customBlockCount = defs.length + settings.customCarousels.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Daily check-off blocks with streak tracking. Drop one into a '
                'layout from the Add-Block sheet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final def in defs)
              _HabitDefinitionRow(
                definition: def,
                onEdit: () => _navigateToEditor(context, def.id),
                onDelete: () => _confirmDelete(context, def),
              ),
            ProLimitHint(
              used: customBlockCount,
              max: kFreeMaxCustomBlocks,
              noun: 'custom blocks',
              subscriptions: AppDependencies.of(context).subscriptionRepository,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AddCustomBlockButton(
                  subscriptions: AppDependencies.of(
                    context,
                  ).subscriptionRepository,
                  currentCount: customBlockCount,
                  label: 'Add habit',
                  onAddAllowed: () => _navigateToEditor(context, null),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HabitDefinitionRow extends StatelessWidget {
  const _HabitDefinitionRow({
    required this.definition,
    required this.onEdit,
    required this.onDelete,
  });

  final HabitDefinition definition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = definition.title.isEmpty ? 'Untitled' : definition.title;
    final iconValue = definition.iconName.isEmpty ? null : definition.iconName;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconValue != null) ...[
                IconOrEmoji(
                  value: iconValue,
                  resolveIcon: (v) =>
                      carouselIconFor(v ?? '')?.icon ??
                      HugeIcons.strokeRoundedQuestion,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  expand: true,
                  onPressed: onEdit,
                  icon: HugeIcons.strokeRoundedPencil,
                  label: 'Edit',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  expand: true,
                  variant: AppButtonVariant.inverted,
                  onPressed: onDelete,
                  icon: HugeIcons.strokeRoundedDelete02,
                  label: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomDefinitionRow extends StatelessWidget {
  const _CustomDefinitionRow({
    required this.definition,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomCarouselDefinition definition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = definition.items.length;
    final label = definition.title.isEmpty ? 'Untitled' : definition.title;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count item${count == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  expand: true,
                  onPressed: onEdit,
                  icon: HugeIcons.strokeRoundedPencil,
                  label: 'Edit',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  expand: true,
                  variant: AppButtonVariant.inverted,
                  onPressed: onDelete,
                  icon: HugeIcons.strokeRoundedDelete02,
                  label: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
