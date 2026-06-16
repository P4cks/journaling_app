import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/emoji_catalogue.dart';

/// One curated icon offered in the picker — the shared shape over the
/// per-area icon catalogues (`kCarouselIcons`, `kLayoutIcons`). Map a
/// catalogue entry to this at the call site.
class PickerIcon {
  const PickerIcon({required this.name, required this.icon, required this.label});

  final String name;
  final HugeIconData icon;
  final String label;
}

/// What [showIconEmojiPicker] returns: either a chosen icon (by stable
/// `name`) or a chosen emoji (the glyph itself). `null` on dismiss.
sealed class PickerResult {
  const PickerResult();
}

class PickerIconResult extends PickerResult {
  const PickerIconResult(this.name);
  final String name;
}

class PickerEmojiResult extends PickerResult {
  const PickerEmojiResult(this.emoji);
  final String emoji;
}

/// Modal bottom-sheet picker for an icon and (optionally) an emoji.
///
/// Shared by the custom-carousel editor (`allowEmoji: true` → both tabs,
/// returns a `CarouselItem`-shaped pick), the habit editor, and the
/// layout icon picker (icon-only). When [allowEmoji] is true the sheet
/// shows an Emoji / Icon `SegmentedButton`; otherwise just the icon grid.
/// [selectedIconName] highlights the matching icon tile.
Future<PickerResult?> showIconEmojiPicker(
  BuildContext context, {
  required List<PickerIcon> icons,
  bool allowEmoji = false,
  String? selectedIconName,
  String title = 'Pick an item',
}) {
  return showModalBottomSheet<PickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _IconEmojiPickerSheet(
      icons: icons,
      allowEmoji: allowEmoji,
      selectedIconName: selectedIconName,
      title: title,
    ),
  );
}

enum _Tab { emoji, icon }

const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 56,
  mainAxisSpacing: 4,
  crossAxisSpacing: 4,
  childAspectRatio: 1,
);

const _emojiCategoryLabels = <EmojiCategory, String>{
  EmojiCategory.smileys: 'Smileys & Emotion',
  EmojiCategory.people: 'People & Body',
  EmojiCategory.nature: 'Animals & Nature',
  EmojiCategory.food: 'Food & Drink',
  EmojiCategory.travel: 'Travel & Places',
  EmojiCategory.activities: 'Activities',
  EmojiCategory.objects: 'Objects',
  EmojiCategory.symbols: 'Symbols',
  EmojiCategory.flags: 'Flags',
};

class _IconEmojiPickerSheet extends StatefulWidget {
  const _IconEmojiPickerSheet({
    required this.icons,
    required this.allowEmoji,
    required this.selectedIconName,
    required this.title,
  });

  final List<PickerIcon> icons;
  final bool allowEmoji;
  final String? selectedIconName;
  final String title;

  @override
  State<_IconEmojiPickerSheet> createState() => _IconEmojiPickerSheetState();
}

class _IconEmojiPickerSheetState extends State<_IconEmojiPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late _Tab _tab = widget.allowEmoji ? _Tab.emoji : _Tab.icon;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _popIcon(String name) => Navigator.of(context).pop(PickerIconResult(name));
  void _popEmoji(String emoji) =>
      Navigator.of(context).pop(PickerEmojiResult(emoji));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // Sit above the keyboard with a 24px top margin so the search field
    // and tabs stay on-screen while typing.
    final height = math.min(screenH * 0.85, screenH - keyboard - 24);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const _DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.title, style: theme.textTheme.titleMedium),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search',
                  isDense: true,
                  prefixIcon: AppIcon(
                    HugeIcons.strokeRoundedSearch01,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: AppIcon(HugeIcons.strokeRoundedCancel01),
                          onPressed: _searchController.clear,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (widget.allowEmoji)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SegmentedButton<_Tab>(
                  segments: const [
                    ButtonSegment(value: _Tab.emoji, label: Text('Emoji')),
                    ButtonSegment(value: _Tab.icon, label: Text('Icon')),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            Expanded(
              child: _tab == _Tab.emoji
                  ? _buildEmojiGrid(theme)
                  : _buildIconGrid(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconGrid(ThemeData theme) {
    final list = widget.icons.where((i) {
      if (_query.isEmpty) return true;
      return i.label.toLowerCase().contains(_query) ||
          i.name.toLowerCase().contains(_query);
    }).toList();
    if (list.isEmpty) return _NoMatches();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      gridDelegate: _gridDelegate,
      itemCount: list.length,
      itemBuilder: (context, i) {
        final ic = list[i];
        return _IconTile(
          icon: ic,
          selected: ic.name == widget.selectedIconName,
          onTap: () => _popIcon(ic.name),
        );
      },
    );
  }

  Widget _buildEmojiGrid(ThemeData theme) {
    final grouped = <EmojiCategory, List<EmojiEntry>>{};
    for (final e in kEmojiCatalogue) {
      if (_query.isNotEmpty && !e.name.toLowerCase().contains(_query)) continue;
      (grouped[e.category] ??= <EmojiEntry>[]).add(e);
    }
    if (grouped.isEmpty) return _NoMatches();

    final slivers = <Widget>[];
    for (final cat in EmojiCategory.values) {
      final list = grouped[cat];
      if (list == null || list.isEmpty) continue;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              _emojiCategoryLabels[cat]!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final e = list[i];
                return _EmojiTile(entry: e, onTap: () => _popEmoji(e.emoji));
              },
              childCount: list.length,
            ),
          ),
        ),
      );
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
    return CustomScrollView(slivers: slivers);
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final PickerIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: icon.label,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: AppIcon(
            icon.icon,
            size: 26,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.entry, required this.onTap});

  final EmojiEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: entry.name,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(entry.emoji, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No matches',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
