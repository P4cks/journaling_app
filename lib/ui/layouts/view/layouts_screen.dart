import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';
import 'package:journaling_app_rewrite/ui/layouts/view_model/layouts_view_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LayoutsScreen extends StatefulWidget {
  const LayoutsScreen({super.key});

  @override
  State<LayoutsScreen> createState() => _LayoutsScreenState();
}

class _LayoutsScreenState extends State<LayoutsScreen> {
  LayoutsViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = LayoutsViewModel(repository: deps.layoutRepository);
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

  Future<void> _openEditor(String? layoutId) async {
    final path = layoutId == null
        ? Routes.newLayout
        : Routes.editLayoutFor(layoutId);
    await context.push(path);
    if (!mounted) return;
    _viewModel?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold();

    final layouts = vm.layouts;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Layouts')),
      body: layouts.isEmpty
          ? Center(
              child: Text(
                'No layouts yet. Tap + to create one.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            )
          : ListView.builder(
              itemCount: layouts.length,
              itemBuilder: (context, index) {
                final layout = layouts[index];
                final isDefault = layout.id == vm.defaultLayoutId;
                return Dismissible(
                  key: ValueKey(layout.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: scheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AppIcon(
                      PhosphorIconsDuotone.trash,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) => vm.delete(layout.id),
                  child: ListTile(
                    leading: _LayoutIconBadge(
                      iconName: layout.iconName,
                      isDefault: isDefault,
                    ),
                    title: Text(layout.name),
                    subtitle: Text(
                      '${layout.blocks.length} '
                      'block${layout.blocks.length == 1 ? '' : 's'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: AppIcon(
                            isDefault
                                ? PhosphorIconsFill.star
                                : PhosphorIconsDuotone.star,
                            color: isDefault ? scheme.primary : null,
                          ),
                          tooltip: isDefault
                              ? 'Default layout'
                              : 'Set as default',
                          onPressed: isDefault
                              ? null
                              : () => vm.setDefault(layout.id),
                        ),
                        const AppIcon(PhosphorIconsDuotone.caretRight),
                        const SizedBox(width: 8),
                      ],
                    ),
                    onTap: () => _openEditor(layout.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(null),
        tooltip: 'New layout',
        child: const AppIcon(PhosphorIconsBold.plus),
      ),
    );
  }
}

/// Square badge showing the layout's chosen icon in the layouts list.
/// Default layouts get a slightly stronger background tint so they read
/// as the "primary" entry without needing the star icon to communicate
/// it (the star moved to the trailing controls).
class _LayoutIconBadge extends StatelessWidget {
  const _LayoutIconBadge({required this.iconName, required this.isDefault});

  final String? iconName;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = layoutIconFor(iconName);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDefault
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDefault ? scheme.primary : scheme.outlineVariant,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: AppIcon(
        isDefault ? icon.fill : icon.duotone,
        size: 22,
        color: isDefault ? scheme.onPrimaryContainer : scheme.onSurface,
      ),
    );
  }
}
