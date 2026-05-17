import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/settings_section.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/prompt_block_settings.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/text_block_settings.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
              label: 'Text Block',
              widget: [TextBlockSettings(vm: vm)],
            ),
            SettingsSection(
              label: 'Prompt Block',
              widget: [PromptBlockSettings(vm: vm)],
            ),
            SettingsSection(
              label: 'Mood Tracker',
              widget: [
                _TitleField(
                  controller: vm.moodTitleController,
                  hint: 'e.g. How are you feeling?',
                ),
              ],
            ),
            SettingsSection(
              label: 'Manual Weather',
              widget: [
                _TitleField(
                  controller: vm.weatherTitleController,
                  hint: "e.g. Today's weather",
                ),
              ],
            ),
            _CustomCarouselSections(
              settings: AppDependencies.of(context).blockSettings,
              layoutRepository: AppDependencies.of(context).layoutRepository,
              maybeSaveOnLeave: _maybeSaveOnLeave,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders one collapsed `SettingsSection` per custom carousel
/// definition, plus an "Add custom block" entry at the bottom.
///
/// Subscribes to [BlockSettings] directly via `ListenableBuilder` so
/// additions / edits / deletes done in the dedicated editor screen
/// surface here without re-pushing the Block-Settings route.
///
/// The Edit / "+ New" actions push the editor onto the navigation
/// stack. Before doing so we run the parent's [maybeSaveOnLeave]
/// because pushing past a dirty Block-Settings draft would otherwise
/// hide the unsaved fields under another route. Equivalent to the
/// AppBar back behaviour, kept consistent.
class _CustomCarouselSections extends StatelessWidget {
  const _CustomCarouselSections({
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

  int _countUsages(String definitionId) {
    var n = 0;
    for (final layout in layoutRepository.getAll()) {
      for (final section in layout.sections) {
        for (final template in section.blocks) {
          if (template.type != BlockType.customCarousel) continue;
          if (template.config['definitionId'] == definitionId) n++;
        }
      }
    }
    return n;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomCarouselDefinition def,
  ) async {
    final uses = _countUsages(def.id);
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
              SettingsSection(
                label: def.title.isEmpty ? 'Untitled' : def.title,
                widget: [
                  _CustomDefinitionRow(
                    definition: def,
                    onEdit: () => _navigateToEditor(context, def.id),
                    onDelete: () => _confirmDelete(context, def),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToEditor(context, null),
                  icon: const AppIcon(PhosphorIconsDuotone.plus),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                icon: const AppIcon(PhosphorIconsDuotone.pencilSimple),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: Icon(PhosphorIconsDuotone.trash, color: errorColor),
                label: Text('Delete', style: TextStyle(color: errorColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: errorColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional label shown above the carousel. Leave blank to hide.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.done,
          maxLength: 40,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
