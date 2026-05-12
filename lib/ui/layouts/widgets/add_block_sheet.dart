import 'package:flutter/material.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_card.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';

/// Half-screen modal sheet that lets the user pick a `BlockType` to add.
///
/// Renders a 2-column scrollable grid of scaled-down block previews, each
/// with a title and one-line description. Returns the picked `BlockType`,
/// or `null` if dismissed.
///
/// Previews use `BlockMode.readOnly` with sample data from
/// `BlockTypeDisplay.sampleData` so the grid scales automatically as new
/// `BlockType` variants are added — extending the enum + adding cases in
/// `block_type_display.dart` is the only touch needed.
Future<BlockType?> showAddBlockSheet(BuildContext context) {
  return showModalBottomSheet<BlockType>(
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
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add block',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (gridCtx, i) {
                      final type = BlockType.values[i];
                      return _AddBlockCell(type: type);
                    },
                    childCount: BlockType.values.length,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _AddBlockCell extends StatelessWidget {
  const _AddBlockCell({required this.type});

  final BlockType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(type),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AbsorbPointer(
              child: BlockCard(
                child: BlockWidget(
                  data: type.sampleData(id: 'preview-${type.name}'),
                  mode: BlockMode.readOnly,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            type.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
