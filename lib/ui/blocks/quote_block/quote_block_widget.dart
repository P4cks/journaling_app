import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/quote_block_content.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/services/quote_service.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Renders today's ZenQuotes quote.
///
/// **Lifecycle**: on first build, if the block's content has no quote
/// stored yet, fetches via [QuoteService] and persists the result into
/// the entry's content via `onChanged`. Subsequent rebuilds use the
/// stored value — re-opening the entry never refetches. ZenQuotes
/// returns the same quote for all callers on a given day, so all
/// entries created on the same day will see the same quote.
class QuoteBlockWidget extends StatefulWidget {
  const QuoteBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onChanged,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;

  @override
  State<QuoteBlockWidget> createState() => _QuoteBlockWidgetState();
}

class _QuoteBlockWidgetState extends State<QuoteBlockWidget> {
  bool _fetching = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeFetch();
  }

  void _maybeFetch() {
    final content = QuoteBlockContent.fromMap(widget.data.content);
    final hasQuote = content.quote != null && content.quote!.isNotEmpty;
    if (hasQuote || _fetching) return;
    _fetching = true;
    final service = AppDependencies.of(context).quoteService;
    service.getTodayQuote().then((daily) {
      if (!mounted) return;
      _fetching = false;
      if (daily == null) {
        setState(() => _failed = true);
        return;
      }
      _failed = false;
      widget.onChanged?.call(
        widget.data.copyWith(
          content: QuoteBlockContent(
            quote: daily.quote,
            author: daily.author,
            fetchedDate: daily.fetchedDate,
          ).toMap(),
        ),
      );
    });
  }

  void _retry() {
    setState(() => _failed = false);
    _fetching = false;
    _maybeFetch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = QuoteBlockContent.fromMap(widget.data.content);

    if (content.quote != null && content.quote!.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '“${content.quote}”',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
              if (content.author != null && content.author!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '— ${content.author}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't fetch today's quote.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _retry,
              icon: AppIcon(HugeIcons.strokeRoundedRefresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
