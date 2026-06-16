import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Rounded search input used at the top of the picker bottom sheets
/// (add-block and add-section). Shows a leading search glyph and a
/// trailing clear button once non-empty. Shared so both sheets stay
/// visually identical (GUS-71).
class SheetSearchField extends StatelessWidget {
  const SheetSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search',
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        prefixIcon: AppIcon(
          HugeIcons.strokeRoundedSearch01,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
        // Rebuild the suffix as the text changes so the clear button
        // appears / disappears with content.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear',
              icon: AppIcon(
                HugeIcons.strokeRoundedCancel01,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              onPressed: controller.clear,
            );
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

/// Empty-state caption shown when a picker sheet has no cells matching
/// the current search query. The [message] is sheet-specific (e.g.
/// "No blocks match your search." / "No sections match your search.").
class NoMatchesHint extends StatelessWidget {
  const NoMatchesHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
