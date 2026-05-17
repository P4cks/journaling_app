import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/ui/core/settings_section.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/block_settings_view_model.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/prompt_block_settings.dart';
import 'package:journaling_app_rewrite/ui/profile/widgets/text_block_settings.dart';

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
          ],
        ),
      ),
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
