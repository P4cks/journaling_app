import 'package:flutter/material.dart';

/// Builder for [showDraggableSheet]'s sliver list. Receives the
/// `ScrollController` provided by the inner [DraggableScrollableSheet]
/// so callers can wire it to a `CustomScrollView` and keep
/// drag-to-expand working as the user scrolls past the top.
typedef DraggableSheetSliverBuilder =
    List<Widget> Function(BuildContext context, ScrollController controller);

/// Shows a half-screen [showModalBottomSheet] containing a
/// [DraggableScrollableSheet], a 36×4 rounded drag handle at the top,
/// an optional left-aligned `titleMedium` header, and the caller's
/// slivers as the body. The sheet returns the value passed to
/// `Navigator.of(sheetContext).pop(...)`.
///
/// All three current callers (calendar month sheet, layout picker,
/// add-block sheet) share this exact shape — they only vary in
/// content slivers, title, and the three size factors. New
/// draggable-style sheets should use this helper rather than re-rolling
/// the chrome.
///
/// Plain menu-style bottom sheets (one short list, no drag handle, no
/// title) intentionally do NOT go through this helper — they're a
/// different visual contract.
Future<T?> showDraggableSheet<T>(
  BuildContext context, {
  String? title,
  double initialChildSize = 0.5,
  double minChildSize = 0.4,
  double maxChildSize = 0.9,
  required DraggableSheetSliverBuilder slivers,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (ctx, scrollController) {
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(child: _SheetHeader(title: title)),
              ...slivers(ctx, scrollController),
            ],
          );
        },
      );
    },
  );
}

/// Drag-handle pill + optional title row. Lives in the same file as
/// [showDraggableSheet] so the visual contract is single-source.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title!, style: theme.textTheme.titleMedium),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}
