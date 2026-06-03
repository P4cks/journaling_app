import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/wannado_item.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/settings_section.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/prompt_block_settings.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

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
                  layoutRepository: AppDependencies.of(
                    context,
                  ).layoutRepository,
                  maybeSaveOnLeave: _maybeSaveOnLeave,
                ),
              ],
            ),
            SettingsSection(
              label: 'Wanna-dos',
              children: [
                _WannadoList(
                  settings: AppDependencies.of(context).blockSettings,
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
            ProLimitHint(
              used: defs.length,
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
                  currentCount: defs.length,
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

/// Manages the user's *global* wanna-do list (GUS-8) — a single bucket
/// list rendered by every `SectionKind.wannado` section as a rotating
/// carousel. Pure display: items have text only, no done state. Writes
/// directly to [BlockSettings] (not draft state), mirroring
/// `_CustomCarouselList` / `_MemoryEligibleTypesPicker`, so additions /
/// edits / deletes surface in every visible wannado section immediately.
class _WannadoList extends StatelessWidget {
  const _WannadoList({required this.settings});

  final BlockSettings settings;

  Future<void> _add(BuildContext context) async {
    final text = await _showEditDialog(context);
    if (text == null) return;
    await settings.addWannado(WannadoItem(id: _uuid.v4(), text: text));
  }

  Future<void> _edit(BuildContext context, WannadoItem item) async {
    final text = await _showEditDialog(context, initial: item.text);
    if (text == null) return;
    await settings.updateWannado(item.copyWith(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final items = settings.wannados;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'A single bucket list shown by every Wanna-dos section. '
                'Items rotate through one at a time.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.text),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: AppIcon(HugeIcons.strokeRoundedPencil),
                      onPressed: () => _edit(context, item),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: AppIcon(
                        HugeIcons.strokeRoundedDelete02,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () => settings.deleteWannado(item.id),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _add(context),
                  icon: AppIcon(HugeIcons.strokeRoundedPlusSign),
                  label: const Text('Add wanna-do'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Single-field add/edit dialog for a wanna-do. Returns the trimmed
/// text, or `null` on cancel / empty.
Future<String?> _showEditDialog(BuildContext context, {String? initial}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _WannadoEditDialog(initial: initial),
  );
  if (result == null || result.isEmpty) return null;
  return result;
}

/// The add/edit dialog content. **Stateful so it owns its
/// `TextEditingController`** and disposes it in its own `dispose()` —
/// disposing the controller synchronously right after `showDialog`
/// returns crashes the TextField as it rebuilds during the dialog's
/// exit animation ("A TextEditingController was used after being
/// disposed"), and that thrown exception aborts the frame so a freshly
/// added wanna-do never paints until a restart.
class _WannadoEditDialog extends StatefulWidget {
  const _WannadoEditDialog({this.initial});

  final String? initial;

  @override
  State<_WannadoEditDialog> createState() => _WannadoEditDialogState();
}

class _WannadoEditDialogState extends State<_WannadoEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add wanna-do' : 'Edit wanna-do'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'e.g. See the northern lights',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
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
                  icon: AppIcon(
                    HugeIcons.strokeRoundedDelete02,
                    color: errorColor,
                  ),
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
