import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/blocks/custom_carousel/carousel_icon_catalogue.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_button.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/icon_emoji_picker.dart';
import 'package:journaling_app_rewrite/ui/profile/view_model/habit_editor_view_model.dart';

/// Create / edit a `HabitDefinition`. Mirrors `CustomBlockEditorScreen`'s
/// draft + Cancel/Discard/Save-on-leave pattern, but a habit is just a
/// title + a single icon (no item list).
///
/// `definitionId == null` → new definition. Otherwise the screen
/// hydrates the existing one for editing.
class HabitEditorScreen extends StatefulWidget {
  const HabitEditorScreen({super.key, this.definitionId});

  final String? definitionId;

  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  HabitEditorViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = HabitEditorViewModel(
        settings: deps.blockSettings,
        definitionId: widget.definitionId,
      );
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
        content: const Text('Save your habit before leaving?'),
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
            vm.titleError ?? 'Cannot save',
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

  Future<void> _pickIcon() async {
    final vm = _viewModel;
    if (vm == null) return;
    final result = await showIconEmojiPicker(
      context,
      title: 'Pick an icon',
      selectedIconName: vm.iconName,
      icons: [
        for (final i in kCarouselIcons)
          PickerIcon(name: i.name, icon: i.icon, label: i.label),
      ],
    );
    if (result is! PickerIconResult) return;
    vm.setIconName(result.name);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold(body: SizedBox.shrink());
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconName = vm.iconName;
    final resolvedIcon = iconName == null
        ? null
        : carouselIconFor(iconName)?.icon ?? HugeIcons.strokeRoundedQuestion;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vm.isNew ? 'New habit' : 'Edit habit'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Title',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: vm.titleController,
              textInputAction: TextInputAction.done,
              maxLength: 40,
              decoration: InputDecoration(
                hintText: 'e.g. Meditate',
                border: const OutlineInputBorder(),
                errorText: vm.titleError,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Shown on the habit block beside the streak. Optional.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickIcon,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: scheme.surfaceContainerHighest,
                      ),
                      child: resolvedIcon == null
                          ? AppIcon(
                              HugeIcons.strokeRoundedAdd01,
                              size: 24,
                              color: scheme.onSurfaceVariant,
                            )
                          : AppIcon(resolvedIcon, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        iconName == null
                            ? 'Pick an icon'
                            : carouselIconFor(iconName)?.label ?? iconName,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    AppIcon(
                      HugeIcons.strokeRoundedArrowRight01,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
