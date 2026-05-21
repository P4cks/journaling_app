import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: const Text('Save'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fix the highlighted fields before saving'),
            ),
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
                  layoutRepository:
                      AppDependencies.of(context).layoutRepository,
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
    final errorColor = Theme.of(context).colorScheme.error;
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final def in defs)
              _CustomDefinitionRow(
                definition: def,
                onEdit: () => _navigateToEditor(context, def.id),
                onDelete: () => _confirmDelete(context, def),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToEditor(context, null),
                  icon: AppIcon(HugeIcons.strokeRoundedPlusSign),
                  label: const Text('Add custom block'),
                ),
              ),
            ),
          ],
        );
      },
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
    final errorColor = theme.colorScheme.error;
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
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: AppIcon(HugeIcons.strokeRoundedPencil),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: AppIcon(HugeIcons.strokeRoundedDelete02, color: errorColor),
                  label: Text('Delete', style: TextStyle(color: errorColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: errorColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
