import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';
import 'package:journaling_app_rewrite/ui/layouts/widgets/layout_default_chip.dart';

String _summarize(JournalLayout layout) {
  switch (layout.kind) {
    case LayoutKind.blockOnly:
      final n = layout.sections.fold<int>(0, (acc, s) => acc + s.blocks.length);
      return '$n block${n == 1 ? '' : 's'}';
    case LayoutKind.fixedFourPlusText:
      return '4 blocks + text';
    case LayoutKind.custom:
      final n = layout.sections.length;
      final allBlockGrid = layout.sections.every(
        (s) => s.kind == SectionKind.blockGrid,
      );
      return '$n section${n == 1 ? '' : 's'}'
          '${allBlockGrid ? '' : ' (incl. text)'}';
  }
}

/// Modal bottom sheet that lets the user pick from [layouts]. Returns the
/// chosen layout, or `null` if dismissed.
///
/// Stateless and stand-alone — both the "Make entry" CTA on the home screen
/// and the "Change layout" action inside the editor call into this same
/// sheet. The editor wraps the result in a destructive-action confirm
/// dialog (existing blocks will be replaced); the home CTA skips the
/// confirm because there is nothing to replace.
///
/// Pass [defaultLayoutId] to highlight the user's default layout: its row
/// gets a tinted leading icon and a trailing "Default" chip so the user
/// can tell at a glance which layout a no-pick entry would use (GUS-28).
///
/// Pass [onManageLayouts] to append a "Create or edit layouts" footer row
/// below the list (GUS-64). Tapping it dismisses the sheet (returning
/// `null` to the awaiting caller) and then invokes the callback — the
/// caller is responsible for navigating to the Layouts screen. Omit it to
/// render no footer.
///
/// Pass [subscriptions] to gate Pro-built layouts for free users
/// (GUS-72). A layout flagged by `layoutHasProOnlyFeatures` renders
/// greyed with a trailing "Pro" chip for a non-Pro user, and tapping it
/// presents the paywall via `requirePro` rather than applying it — the
/// sheet only pops with the layout on a successful upgrade. Pro users
/// (and layouts without Pro features) tap straight through. Omit it (or
/// pass `null`) to disable the gate entirely.
///
/// Uses the shared `showDraggableSheet` scaffold so the drag handle,
/// title, and `DraggableScrollableSheet` chrome match the calendar and
/// add-block sheets.
Future<JournalLayout?> showLayoutPickerSheet(
  BuildContext context, {
  required List<JournalLayout> layouts,
  String? defaultLayoutId,
  String title = 'Choose layout',
  VoidCallback? onManageLayouts,
  SubscriptionRepository? subscriptions,
}) {
  if (layouts.isEmpty) return Future.value(null);
  return showDraggableSheet<JournalLayout>(
    context,
    title: title,
    slivers: (ctx, _) => [
      SliverList(
        delegate: SliverChildBuilderDelegate((listCtx, index) {
          final layout = layouts[index];
          final isDefault = layout.id == defaultLayoutId;
          // GUS-72: free users can't apply Pro-built layouts. Such a row
          // greys + badges and routes the tap through the paywall; only a
          // successful upgrade applies it. Pro users tap straight through.
          final isProLocked = subscriptions != null &&
              !subscriptions.isPro &&
              layoutHasProOnlyFeatures(layout);
          final theme = Theme.of(listCtx);
          final scheme = theme.colorScheme;
          final mutedColor = theme.disabledColor;
          return ListTile(
            leading: HugeIcon(
              icon: layoutIconFor(layout.iconName).icon,
              color: isProLocked
                  ? mutedColor
                  : (isDefault ? scheme.primary : null),
            ),
            title: Text(
              layout.name,
              style: isProLocked ? TextStyle(color: mutedColor) : null,
            ),
            subtitle: Text(
              _summarize(layout),
              style: isProLocked ? TextStyle(color: mutedColor) : null,
            ),
            trailing: (isProLocked || isDefault)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isProLocked) const ProLockBadge(),
                      if (isProLocked && isDefault)
                        const SizedBox(width: 8),
                      if (isDefault) const LayoutDefaultChip(),
                    ],
                  )
                : null,
            onTap: () async {
              if (isProLocked) {
                // Capture the navigator before the async gap — `listCtx`
                // may unmount while the paywall is up.
                final navigator = Navigator.of(listCtx);
                if (!await requirePro(subscriptions, context: listCtx)) {
                  return;
                }
                navigator.pop(layout);
              } else {
                Navigator.of(listCtx).pop(layout);
              }
            },
          );
        }, childCount: layouts.length),
      ),
      if (onManageLayouts != null)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 1),
              Builder(
                builder: (footerCtx) {
                  final scheme = Theme.of(footerCtx).colorScheme;
                  return ListTile(
                    leading: AppIcon(
                      HugeIcons.strokeRoundedPencilEdit02,
                      color: scheme.primary,
                    ),
                    title: Text(
                      'Manage layouts',
                      style: TextStyle(color: scheme.primary),
                    ),
                    onTap: () {
                      Navigator.of(footerCtx).pop();
                      onManageLayouts();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
    ],
  );
}
