import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
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
/// Uses the shared `showDraggableSheet` scaffold so the drag handle,
/// title, and `DraggableScrollableSheet` chrome match the calendar and
/// add-block sheets.
Future<JournalLayout?> showLayoutPickerSheet(
  BuildContext context, {
  required List<JournalLayout> layouts,
  String? defaultLayoutId,
  String title = 'Choose layout',
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
          final scheme = Theme.of(listCtx).colorScheme;
          return ListTile(
            leading: HugeIcon(
              icon: layoutIconFor(layout.iconName).icon,
              color: isDefault ? scheme.primary : null,
            ),
            title: Text(layout.name),
            subtitle: Text(_summarize(layout)),
            trailing: isDefault ? const LayoutDefaultChip() : null,
            onTap: () => Navigator.of(listCtx).pop(layout),
          );
        }, childCount: layouts.length),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
    ],
  );
}
