import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/layouts/layout_icons.dart';

String _summarize(JournalLayout layout) {
  switch (layout.kind) {
    case LayoutKind.blockOnly:
      final n = layout.sections.fold<int>(
        0,
        (acc, s) => acc + s.blocks.length,
      );
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
/// Uses the same `DraggableScrollableSheet` UX as `add_block_sheet` so
/// long layout lists scroll inside the sheet instead of pushing the
/// AppBar off-screen.
Future<JournalLayout?> showLayoutPickerSheet(
  BuildContext context, {
  required List<JournalLayout> layouts,
  String title = 'Choose layout',
}) {
  if (layouts.isEmpty) return Future.value(null);
  return showModalBottomSheet<JournalLayout>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          final theme = Theme.of(ctx);
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((listCtx, index) {
                  final layout = layouts[index];
                  return ListTile(
                    leading: AppIcon(layoutIconFor(layout.iconName).duotone),
                    title: Text(layout.name),
                    subtitle: Text(_summarize(layout)),
                    onTap: () => Navigator.of(listCtx).pop(layout),
                  );
                }, childCount: layouts.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],
          );
        },
      );
    },
  );
}
