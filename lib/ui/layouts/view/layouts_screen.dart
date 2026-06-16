import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';
import 'package:journaling_app_rewrite/ui/layouts/view_model/layouts_view_model.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_default_chip.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_kind_picker_sheet.dart';

String _layoutSummary(JournalLayout layout) {
  switch (layout.kind) {
    case LayoutKind.blockOnly:
      final n = layout.sections.fold<int>(0, (acc, s) => acc + s.blocks.length);
      return '$n block${n == 1 ? '' : 's'}';
    case LayoutKind.fixedFourPlusText:
      return '4 blocks + text';
    case LayoutKind.custom:
      final n = layout.sections.length;
      final blockGridSections = layout.sections
          .where((s) => s.kind == SectionKind.blockGrid)
          .length;
      return '$n section${n == 1 ? '' : 's'}'
          '${blockGridSections == n ? '' : ' (incl. text)'}';
  }
}

class LayoutsScreen extends StatefulWidget {
  const LayoutsScreen({super.key});

  @override
  State<LayoutsScreen> createState() => _LayoutsScreenState();
}

class _LayoutsScreenState extends State<LayoutsScreen> {
  LayoutsViewModel? _viewModel;
  SubscriptionRepository? _subscriptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      final deps = AppDependencies.of(context);
      _viewModel = LayoutsViewModel(repository: deps.layoutRepository);
      _viewModel!.addListener(_onChanged);
      _subscriptions = deps.subscriptionRepository;
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
    final vm = _viewModel;
    final subs = _subscriptions;

    // GUS-41: Gate pro-only layouts when user has downgraded to free
    if (layoutId != null && vm != null && subs != null) {
      final layoutIndex = vm.layouts.indexWhere((l) => l.id == layoutId);
      if (layoutIndex >= 0) {
        final layout = vm.layouts[layoutIndex];
        if (!subs.isPro && layoutHasProOnlyFeatures(layout)) {
          if (!mounted) return;
          await _showProLayoutLockedDialog(layout);
          return;
        }
      }
    }

    final path = layoutId == null
        ? Routes.newLayout
        : Routes.editLayoutFor(layoutId);
    await context.push(path);
    if (!mounted) return;
    _viewModel?.refresh();
  }

  Future<void> _showProLayoutLockedDialog(JournalLayout layout) async {
    if (!mounted) return;
    final subs = _subscriptions;
    if (subs == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro Layout'),
        content: const Text(
          'This layout uses Pro features. You need to upgrade to Pro to edit it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete Layout'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'upgrade'),
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    switch (result) {
      case 'delete':
        _viewModel?.delete(layout.id);
        showToast(context, 'Layout deleted', kind: ToastKind.success);
      case 'upgrade':
        await requirePro(subs, context: context);
      default:
        break;
    }
  }

  Future<void> _openNewLayoutFlow() async {
    final vm = _viewModel;
    final subs = _subscriptions;
    if (vm == null || subs == null) return;
    // Free users keep their one (seeded) layout; creating a second requires
    // the `pro` entitlement (BACKLOG #90, GUS-40). `requirePro`
    // short-circuits when already Pro and otherwise presents the paywall.
    if (vm.layouts.length >= kFreeMaxLayouts &&
        !await requirePro(subs, context: context)) {
      return;
    }
    if (!mounted) return;
    final kind = await showLayoutKindPickerSheet(context);
    if (!mounted || kind == null) return;
    await context.push(Routes.newLayoutFor(kind));
    if (!mounted) return;
    _viewModel?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    final subs = _subscriptions;
    if (vm == null || subs == null) return const Scaffold();

    // Listen to the subscription repo so the limit hint + FAB lock state
    // update live after a purchase/restore (GUS-40).
    return ListenableBuilder(
      listenable: subs,
      builder: (context, _) {
        final layouts = vm.layouts;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final atLimit = !subs.isPro && layouts.length >= kFreeMaxLayouts;

        final Widget list = layouts.isEmpty
            ? Center(
                child: Text(
                  'No layouts yet. Tap + to create one.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: layouts.length,
                itemBuilder: (context, index) {
                  final layout = layouts[index];
                  final isDefault = layout.id == vm.defaultLayoutId;
                  // GUS-72: mark layouts built with Pro-only features so
                  // free users can see which layouts depend on Pro (the
                  // lock dialog on tap still gates editing for downgraded
                  // free users, GUS-41). Pro users get no badge — every
                  // layout is editable for them, so it carries no signal.
                  final isProLayout =
                      !subs.isPro && layoutHasProOnlyFeatures(layout);
                  return Dismissible(
                    key: ValueKey(layout.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: scheme.errorContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppIcon(
                        HugeIcons.strokeRoundedDelete02,
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
                      subtitle: Text(_layoutSummary(layout)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isProLayout) ...[
                            const ProLockBadge(),
                            const SizedBox(width: 8),
                          ],
                          if (isDefault)
                            const LayoutDefaultChip()
                          else
                            TextButton.icon(
                              icon: AppIcon(
                                HugeIcons.strokeRoundedStar,
                                size: 16,
                              ),
                              label: const Text('Set default'),
                              onPressed: () => vm.setDefault(layout.id),
                            ),
                          const SizedBox(width: 4),
                          AppIcon(HugeIcons.strokeRoundedArrowRight01),
                          const SizedBox(width: 8),
                        ],
                      ),
                      onTap: () => _openEditor(layout.id),
                    ),
                  );
                },
              );

        return Scaffold(
          appBar: AppBar(title: const Text('Layouts')),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Renders nothing for Pro users; for free users it shows
              // "1 of 1 layouts used" → "layouts limit reached — Upgrade".
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ProLimitHint(
                  used: layouts.length,
                  max: kFreeMaxLayouts,
                  noun: 'layouts',
                  subscriptions: subs,
                ),
              ),
              Expanded(child: list),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openNewLayoutFlow,
            tooltip: atLimit ? 'Pro — unlimited layouts' : 'New layout',
            backgroundColor: atLimit ? scheme.surfaceContainerHighest : null,
            foregroundColor: atLimit ? theme.disabledColor : null,
            child: atLimit
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppIcon(
                        HugeIcons.strokeRoundedPlusSign,
                        color: theme.disabledColor,
                      ),
                      const Positioned(
                        top: -4,
                        right: -4,
                        child: ProLockBadge(compact: true),
                      ),
                    ],
                  )
                : AppIcon(HugeIcons.strokeRoundedPlusSign),
          ),
        );
      },
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
        icon.icon,
        size: 22,
        color: isDefault ? scheme.onPrimaryContainer : scheme.onSurface,
      ),
    );
  }
}
