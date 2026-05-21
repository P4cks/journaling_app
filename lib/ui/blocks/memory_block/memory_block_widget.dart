import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/block_content/memory_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/photo_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/core/format/date_format.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Fires the memory block's primary action — navigates to the source
/// entry. Called from `MainJournalScreen` when the user double-taps
/// the memory tile and the "expand on edit" setting is OFF (per the
/// `BlockTypeDisplay.isActionBlock` contract). No-op when the memory
/// hasn't been seeded yet (no eligible past entry) or `onJumpToDate`
/// is null.
void fireMemoryBlockAction(
  JournalBlockData data,
  ValueChanged<DateTime>? onJumpToDate,
) {
  if (onJumpToDate == null) return;
  final content = MemoryBlockContent.fromMap(data.content);
  final iso = content.sourceEntryDate;
  if (iso == null) return;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return;
  onJumpToDate(parsed);
}

/// Surfaces a random non-empty block from a past entry. The pick is
/// **locked once shown** — the first build with empty content asks the
/// repository for a random eligible block and persists the snapshot
/// into this entry's content via `onChanged`. Subsequent rebuilds read
/// the stored snapshot. Tapping the rendered memory navigates to the
/// source entry.
class MemoryBlockWidget extends StatefulWidget {
  const MemoryBlockWidget({
    super.key,
    required this.data,
    required this.mode,
    this.onJumpToDate,
    this.onChanged,
    this.onDoubleTap,
    this.expanded = false,
  });

  final JournalBlockData data;
  final BlockMode mode;
  final ValueChanged<JournalBlockData>? onChanged;
  final ValueChanged<DateTime>? onJumpToDate;

  /// Host's "push expanded route" callback. Wired onto the body's
  /// `GestureDetector(onDoubleTap)`. The Navigate button is rendered
  /// OUTSIDE that detector so its InkWell single-tap navigates
  /// without being intercepted.
  final VoidCallback? onDoubleTap;

  /// Legacy prop — currently unused. The Navigate button is always
  /// visible in editable mode now.
  final bool expanded;

  @override
  State<MemoryBlockWidget> createState() => _MemoryBlockWidgetState();
}

class _MemoryBlockWidgetState extends State<MemoryBlockWidget> {
  bool _picking = false;
  bool _noEligible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePick();
  }

  void _maybePick() {
    final content = MemoryBlockContent.fromMap(widget.data.content);
    if (content.isSeeded || _picking || _noEligible) return;
    _picking = true;
    final deps = AppDependencies.of(context);
    final repo = deps.journalRepository;
    // Eligible types are user-configurable via Block Settings → Memory.
    // memoryBlock itself is filtered by `BlockSettings.setMemoryEligibleTypes`
    // before persistence so we don't need a defensive filter here.
    final pick = repo.pickRandomEligibleBlock(
      beforeDate: DateTime.now(),
      eligibleTypes: deps.blockSettings.memoryEligibleTypes,
    );
    _picking = false;
    if (pick == null) {
      setState(() => _noEligible = true);
      return;
    }
    final date = pick.date;
    final block = pick.block;
    final isoDate =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    widget.onChanged?.call(
      JournalBlockData.create(
        id: widget.data.id,
        type: widget.data.type,
        content: MemoryBlockContent(
          sourceEntryDate: isoDate,
          sourceBlockId: block.id,
          sourceType: block.type,
          snapshotJson: block.contentJson,
        ).toMap(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = MemoryBlockContent.fromMap(widget.data.content);

    if (_noEligible && !content.isSeeded) {
      return Center(
        child: Text(
          'No memories yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.disabledColor,
          ),
        ),
      );
    }

    if (!content.isSeeded) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final caption = _formatCaption(content.sourceEntryDate);
    final body = _renderSnapshot(context, content);
    final canNavigate =
        widget.onJumpToDate != null && content.sourceEntryDate != null;

    // Body wrapped in a `GestureDetector(onDoubleTap)` so the
    // double-tap-to-expand reaches the host. Single taps fall through
    // (no `onTap`) — there's nothing to engage on the snapshot
    // itself. The Navigate button is OUTSIDE this detector so its
    // InkWell single-tap fires normally.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null)
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: widget.onDoubleTap,
            child: body,
          ),
        ),
        if (canNavigate && widget.mode == BlockMode.editable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () => widget.onJumpToDate!(
                DateTime.parse(content.sourceEntryDate!),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Navigate to that day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String? _formatCaption(String? isoDate) {
    if (isoDate == null) return null;
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return null;
    return 'from ${formatEntryDate(parsed)}';
  }

  Widget _renderSnapshot(BuildContext context, MemoryBlockContent content) {
    final theme = Theme.of(context);
    final type = content.sourceType;
    final raw = content.snapshotJson;
    if (type == null || raw == null) {
      return Text(
        'Memory unavailable',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.disabledColor,
        ),
      );
    }
    Map<String, dynamic> decoded;
    try {
      final parsed = jsonDecode(raw);
      decoded = parsed is Map<String, dynamic>
          ? parsed
          : Map<String, dynamic>.from(parsed as Map);
    } catch (_) {
      return Text(
        'Memory unavailable',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.disabledColor,
        ),
      );
    }

    switch (type) {
      case BlockType.textBlock:
        final text = TextBlockContent.fromMap(decoded).text;
        return SingleChildScrollView(
          child: Text(text, style: theme.textTheme.bodySmall),
        );
      case BlockType.moodTracker:
        final emoji = MoodBlockContent.fromMap(decoded).emoji;
        return Center(
          child: Text(emoji ?? '—', style: const TextStyle(fontSize: 48)),
        );
      case BlockType.photoBlock:
        final path = PhotoBlockContent.fromMap(decoded).photoPath;
        if (path == null || path.isEmpty) {
          return Text(
            'Photo missing',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.disabledColor,
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox.expand(
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  'Photo missing',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.disabledColor,
                  ),
                ),
              ),
            ),
          ),
        );
      // Other types aren't currently picked (see `_eligibleTypes`).
      // Render a generic placeholder if the eligibility set is widened
      // later but this widget hasn't been updated.
      case BlockType.weatherManual:
      case BlockType.promptBlock:
      case BlockType.todoBlock:
      case BlockType.quoteBlock:
      case BlockType.memoryBlock:
      case BlockType.weatherApi:
      case BlockType.locationBlock:
      case BlockType.customCarousel:
        return Text('Memory', style: theme.textTheme.bodySmall);
    }
  }
}
