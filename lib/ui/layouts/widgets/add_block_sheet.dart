import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/habit_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/habit_definition.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/sheet_search_field.dart';

/// Block types intentionally hidden from the layout-editor picker.
///
/// `locationBlock` is still WIP. `customCarousel` and `habitTracker` are
/// excluded from the built-in grid because user-defined carousel / habit
/// "types" surface as their own per-definition tiles in the custom-blocks
/// and habit sections below — there's no abstract tile that would make
/// sense without an id to attach.
const _hiddenBlockTypes = <BlockType>{
  BlockType.locationBlock,
  BlockType.customCarousel,
  BlockType.habitTracker,
};

/// Logical groupings for the Default tab, rendered top-to-bottom with a
/// [SectionHeader] above each (GUS-56). A built-in type not listed here
/// still renders — it falls into a trailing "More" group (see
/// `_builtinGroups`) so adding a new `BlockType` never silently drops it
/// from the grid.
const _builtinCategories = <({String label, List<BlockType> types})>[
  (
    label: 'Text',
    types: [BlockType.textBlock, BlockType.promptBlock, BlockType.todoBlock],
  ),
  (label: 'Trackers', types: [BlockType.moodTracker, BlockType.streakBlock]),
  (label: 'Weather', types: [BlockType.weatherManual, BlockType.weatherApi]),
  (label: 'Memories', types: [BlockType.photoBlock, BlockType.memoryBlock, BlockType.videoBlock, BlockType.voiceBlock]),
  (label: 'Inspiration', types: [BlockType.quoteBlock]),
];

/// Discriminated return type for [showAddBlockSheet]:
/// - [AddBlockResultBuiltin] — user picked a built-in `BlockType`.
/// - [AddBlockResultCustom] — user picked one of their saved
///   custom-carousel definitions; the layout editor stores
///   `definitionId` on the slot (a `customCarousel` block).
/// - [AddBlockResultHabit] — user picked one of their saved habit
///   definitions; the layout editor stores `definitionId` on the slot
///   (a `habitTracker` block).
sealed class AddBlockResult {
  const AddBlockResult();
}

class AddBlockResultBuiltin extends AddBlockResult {
  const AddBlockResultBuiltin(this.type);
  final BlockType type;
}

class AddBlockResultCustom extends AddBlockResult {
  const AddBlockResultCustom(this.definitionId);
  final String definitionId;
}

class AddBlockResultHabit extends AddBlockResult {
  const AddBlockResultHabit(this.definitionId);
  final String definitionId;
}

/// Half-screen modal sheet that lets the user pick a block to add.
///
/// Layout (top → bottom):
/// - A search field that filters the visible cells by `BlockType.label`
///   / `description` (and custom-definition title) live as the user
///   types. (GUS-20)
/// - When [allowedTypes] is null: a 2-segment `SegmentedButton` tab
///   switcher between **Default** (built-in `BlockType`s) and **Custom**
///   (the user's saved custom-carousel *and* habit definitions — GUS-52
///   folded the former Habits tab into Custom). (GUS-24) The built-in
///   grid and the custom section render one-at-a-time based on the active
///   tab rather than stacked.
/// - The active tab's content: built-in cells in a 2-column grid, or the
///   custom-carousel + habit definition cells plus a single
///   "Add custom block" button that, after the free-cap/paywall check,
///   asks which kind to create (custom carousel or habit) before pushing
///   the matching editor screen — on save the sheet rebuilds via a
///   `ListenableBuilder` on `BlockSettings`, so the new definition
///   appears without a re-open.
///
/// Pass [allowedTypes] to restrict to a subset (e.g.
/// `{photoBlock, memoryBlock}` for feature-block sections). When set,
/// the tab switcher and custom section are hidden — feature blocks can't
/// be custom carousels — leaving just the search field + built-in grid.
Future<AddBlockResult?> showAddBlockSheet(
  BuildContext context, {
  Set<BlockType>? allowedTypes,
  String title = 'Add block',
}) {
  return showDraggableSheet<AddBlockResult>(
    context,
    title: title,
    slivers: (ctx, _) => [
      SliverToBoxAdapter(child: _AddBlockSheetBody(allowedTypes: allowedTypes)),
    ],
  );
}

/// Which tab the sheet is currently showing. Only relevant when the
/// custom section is visible (`allowedTypes == null`). The Custom tab
/// holds both custom-carousel and habit definitions (GUS-52).
enum _BlockTab { defaults, custom }

class _AddBlockSheetBody extends StatefulWidget {
  const _AddBlockSheetBody({required this.allowedTypes});

  final Set<BlockType>? allowedTypes;

  @override
  State<_AddBlockSheetBody> createState() => _AddBlockSheetBodyState();
}

class _AddBlockSheetBodyState extends State<_AddBlockSheetBody> {
  final TextEditingController _searchController = TextEditingController();

  /// Lower-cased, trimmed search query. Empty means "no filter".
  String _query = '';
  _BlockTab _tab = _BlockTab.defaults;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim().toLowerCase();
    if (next != _query) setState(() => _query = next);
  }

  /// True when [haystacks] should be shown for the current [_query].
  bool _matches(List<String> haystacks) {
    if (_query.isEmpty) return true;
    return haystacks.any((h) => h.toLowerCase().contains(_query));
  }

  bool get _showCustomSection => widget.allowedTypes == null;

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final settings = deps.blockSettings;
    final subscriptions = deps.subscriptionRepository;
    final rewards = deps.streakRewardSettings;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isPro = subscriptions.isPro;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SheetSearchField(
                controller: _searchController,
                hintText: 'Search blocks',
              ),
            ),
            if (_showCustomSection)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentedButton<_BlockTab>(
                  segments: const [
                    ButtonSegment(
                      value: _BlockTab.defaults,
                      label: Text('Default'),
                    ),
                    ButtonSegment(
                      value: _BlockTab.custom,
                      label: Text('Custom'),
                    ),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (sel) => setState(() => _tab = sel.first),
                ),
              ),
            if (!_showCustomSection || _tab == _BlockTab.defaults)
              _buildBuiltinGrid(
                subscriptions: subscriptions,
                isPro: isPro,
                rewards: rewards,
              )
            else
              _buildCustomSection(
                settings: settings,
                subscriptions: subscriptions,
                isPro: isPro,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBuiltinGrid({
    required SubscriptionRepository subscriptions,
    required bool isPro,
    required StreakRewardSettings rewards,
  }) {
    final allowed = widget.allowedTypes;
    final visibleTypes = BlockType.values
        .where((t) => !_hiddenBlockTypes.contains(t))
        // The streak block is a milestone reward, not a Pro purchase:
        // hide it entirely until the user has claimed it (everyone earns
        // it at the 7-day streak — see StreakRewardSettings). Once
        // unlocked it's free to add for both free and Pro users.
        .where(
          (t) =>
              t != BlockType.streakBlock ||
              rewards.isBlockUnlocked(BlockType.streakBlock),
        )
        .where((t) => allowed == null || allowed.contains(t))
        .where((t) => _matches([t.label, t.description]))
        .toList(growable: false);

    if (visibleTypes.isEmpty) {
      return const NoMatchesHint(message: 'No blocks match your search.');
    }

    // Restricted pickers (feature-block sections, `allowedTypes != null`)
    // show a small fixed subset — a single flat grid reads better than
    // sparse one-cell category headings. The logical dividers are only
    // for the full Default tab (GUS-56).
    if (allowed != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: _builtinGrid(
          visibleTypes,
          subscriptions: subscriptions,
          isPro: isPro,
          rewards: rewards,
        ),
      );
    }

    // Group the visible types under their category heading, in
    // `_builtinCategories` order. Any visible type not assigned to a
    // category lands in a trailing "More" group so nothing is dropped.
    final grouped = <({String label, List<BlockType> types})>[];
    final seen = <BlockType>{};
    for (final category in _builtinCategories) {
      final members = category.types
          .where(visibleTypes.contains)
          .toList(growable: false);
      if (members.isEmpty) continue;
      grouped.add((label: category.label, types: members));
      seen.addAll(members);
    }
    final leftovers = visibleTypes
        .where((t) => !seen.contains(t))
        .toList(growable: false);
    if (leftovers.isNotEmpty) {
      grouped.add((label: 'More', types: leftovers));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in grouped) ...[
          SectionHeader(label: group.label),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _builtinGrid(
              group.types,
              subscriptions: subscriptions,
              isPro: isPro,
              rewards: rewards,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// A 2-column grid of built-in block cells for [types]. Padding and any
  /// category heading are owned by the caller.
  Widget _builtinGrid(
    List<BlockType> types, {
    required SubscriptionRepository subscriptions,
    required bool isPro,
    required StreakRewardSettings rewards,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: types.length,
      itemBuilder: (gridCtx, i) => _BuiltinCell(
        type: types[i],
        locked:
            !isPro && types[i].isProOnly && !rewards.isBlockUnlocked(types[i]),
        subscriptions: subscriptions,
      ),
    );
  }

  /// The Custom tab: custom-carousel definitions AND habit definitions
  /// (GUS-52 folded the former separate Habits tab in here), the shared
  /// custom-block Pro hint, and a single "Add custom block" button that
  /// asks which kind to create.
  Widget _buildCustomSection({
    required BlockSettings settings,
    required SubscriptionRepository subscriptions,
    required bool isPro,
  }) {
    final theme = Theme.of(context);
    final allCustoms = settings.customCarousels;
    final allHabits = settings.habits;
    // GUS-41: a free user may add only the first `kFreeMaxCustomBlocks`
    // custom-carousel definitions to a layout; every later one greys +
    // badges and routes through the paywall on tap (same flow as a
    // Pro-locked built-in). The lock is keyed on the definition's
    // position in the *full* list so the locked set stays stable while
    // searching. Old entries that already reference a now-locked
    // definition keep rendering it — this only gates *adding* to layouts.
    final lockedIds = <String>{
      if (!isPro)
        for (var i = kFreeMaxCustomBlocks; i < allCustoms.length; i++)
          allCustoms[i].id,
    };
    final customs = allCustoms
        .where((d) => _matches([d.title]))
        .toList(growable: false);
    final habits = allHabits
        .where((d) => _matches([d.title]))
        .toList(growable: false);
    // The free cap counts carousels + habits together against one
    // "custom block" budget (GUS-13 / GUS-40), so the hint/add button
    // here reflect the combined total.
    final customBlockCount = allCustoms.length + allHabits.length;

    final nothingDefined = allCustoms.isEmpty && allHabits.isEmpty;
    final nothingMatches = !nothingDefined && customs.isEmpty && habits.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nothingDefined)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "You haven't defined any custom blocks yet.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (nothingMatches)
          const NoMatchesHint(message: 'No blocks match your search.')
        else ...[
          if (customs.isNotEmpty) ...[
            // Logical divider by custom type (GUS-56).
            const SectionHeader(label: 'Carousel'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: customs.length,
                itemBuilder: (gridCtx, i) => _CustomCell(
                  definition: customs[i],
                  // Creating a new custom block is capped by the "Add
                  // custom block" button below (GUS-34). Adding an
                  // *existing* one to a layout is free for the first
                  // `kFreeMaxCustomBlocks`; later definitions are
                  // Pro-locked for free users (GUS-41).
                  locked: lockedIds.contains(customs[i].id),
                  subscriptions: subscriptions,
                ),
              ),
            ),
          ],
          if (habits.isNotEmpty) ...[
            // Logical divider by custom type (GUS-56).
            const SectionHeader(label: 'Habit'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: habits.length,
                itemBuilder: (gridCtx, i) => _HabitCell(
                  definition: habits[i],
                  locked: false,
                  subscriptions: subscriptions,
                ),
              ),
            ),
          ],
        ],
        ProLimitHint(
          used: customBlockCount,
          max: kFreeMaxCustomBlocks,
          noun: 'custom blocks',
          subscriptions: subscriptions,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: AddCustomBlockButton(
            subscriptions: subscriptions,
            currentCount: customBlockCount,
            onAddAllowed: _promptNewCustomBlockKind,
          ),
        ),
      ],
    );
  }

  /// After the free-cap / paywall check in [AddCustomBlockButton], ask
  /// the user which kind of custom block to create, then pop the sheet
  /// and push the matching editor route. Dismissing the chooser leaves
  /// the add-block sheet open. (GUS-52)
  Future<void> _promptNewCustomBlockKind() async {
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final route = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What do you want to add?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: AppIcon(BlockType.customCarousel.icon),
                title: const Text('Custom carousel'),
                subtitle: Text(BlockType.customCarousel.description),
                onTap: () => Navigator.of(sheetCtx).pop(Routes.newCustomBlock),
              ),
              ListTile(
                leading: AppIcon(BlockType.habitTracker.icon),
                title: const Text('Habit'),
                subtitle: Text(BlockType.habitTracker.description),
                onTap: () => Navigator.of(sheetCtx).pop(Routes.newHabitBlock),
              ),
            ],
          ),
        );
      },
    );
    if (route == null || !mounted) return;
    // Pop the add-block sheet first so the editor pushes onto the
    // layout-editor screen, not the sheet.
    navigator.pop();
    router.push(route);
  }
}

/// Deterministic post-it visuals for a preview tile, seeded from a
/// stable [seed] (block type name or custom-definition id) against the
/// live post-it palette — mirrors `_slotPreviewData` in the layout
/// editor so the add-block sheet previews match what a materialized
/// entry looks like (rotation / offset / colour). The seed is stable,
/// so visuals don't jitter across rebuilds. When post-it mode is off,
/// `BlockChrome` ignores these fields, so they're harmless. (GUS-23)
BlockVisuals _previewVisuals(BuildContext context, String seed) {
  final palette = AppDependencies.of(context).themeSettings.postItPalette;
  return BlockVisuals.random(Random(seed.hashCode), palette);
}

class _BuiltinCell extends StatelessWidget {
  const _BuiltinCell({
    required this.type,
    required this.locked,
    required this.subscriptions,
  });

  final BlockType type;
  final bool locked;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickBlock(
        context: context,
        locked: locked,
        subscriptions: subscriptions,
        result: AddBlockResultBuiltin(type),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewTile(
            locked: locked,
            visuals: _previewVisuals(context, type.name),
            child: BlockWidget(
              data: type.sampleData(id: 'preview-${type.name}'),
              mode: BlockMode.readOnly,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: locked ? theme.disabledColor : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            type.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Square block preview with the shared chrome. When [locked], the
/// preview dims and a compact Pro crown overlays the top-right corner.
///
/// [visuals] carry the post-it look (rotation / offset / colour). They
/// only take effect when post-it mode is enabled — `BlockChrome` ignores
/// them otherwise (GUS-23).
class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.locked,
    required this.child,
    this.visuals = BlockVisuals.zero,
  });

  final bool locked;
  final Widget child;
  final BlockVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final tile = AspectRatio(
      aspectRatio: 1,
      child: AbsorbPointer(
        child: BlockChrome(visuals: visuals, child: child),
      ),
    );
    if (!locked) return tile;
    return Stack(
      children: [
        Opacity(opacity: 0.45, child: tile),
        const Positioned(top: 6, right: 6, child: ProLockBadge(compact: true)),
      ],
    );
  }
}

/// Shared tap handler for both built-in and custom cells: when [locked],
/// present the paywall and only pop with [result] on a successful
/// purchase; otherwise pop immediately.
Future<void> _pickBlock({
  required BuildContext context,
  required bool locked,
  required SubscriptionRepository subscriptions,
  required AddBlockResult result,
}) async {
  if (!locked) {
    Navigator.of(context).pop(result);
    return;
  }
  final ok = await requirePro(subscriptions, context: context);
  if (ok && context.mounted) {
    Navigator.of(context).pop(result);
  }
}

class _CustomCell extends StatelessWidget {
  const _CustomCell({
    required this.definition,
    required this.locked,
    required this.subscriptions,
  });

  final CustomCarouselDefinition definition;
  final bool locked;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Build a sample JournalBlockData that points at this definition
    // and pre-selects the first item so the preview renders something
    // recognisable (the widget reads from BlockSettings live).
    final CarouselItem? sample = definition.items.isEmpty
        ? null
        : definition.items.first;
    final data = JournalBlockData.create(
      id: 'preview-${definition.id}',
      type: BlockType.customCarousel,
      content: CustomCarouselBlockContent(
        definitionId: definition.id,
        selected: sample,
      ).toMap(),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickBlock(
        context: context,
        locked: locked,
        subscriptions: subscriptions,
        result: AddBlockResultCustom(definition.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewTile(
            locked: locked,
            visuals: _previewVisuals(context, definition.id),
            child: BlockWidget(data: data, mode: BlockMode.readOnly),
          ),
          const SizedBox(height: 8),
          Text(
            definition.title.isEmpty ? 'Untitled' : definition.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: locked ? theme.disabledColor : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${definition.items.length} item${definition.items.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HabitCell extends StatelessWidget {
  const _HabitCell({
    required this.definition,
    required this.locked,
    required this.subscriptions,
  });

  final HabitDefinition definition;
  final bool locked;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sample data points at this definition (uncompleted) so the
    // preview renders the habit's empty checkbox + title + icon (the
    // widget reads the definition from BlockSettings live).
    final data = JournalBlockData.create(
      id: 'preview-${definition.id}',
      type: BlockType.habitTracker,
      content: HabitBlockContent(definitionId: definition.id).toMap(),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickBlock(
        context: context,
        locked: locked,
        subscriptions: subscriptions,
        result: AddBlockResultHabit(definition.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewTile(
            locked: locked,
            visuals: _previewVisuals(context, definition.id),
            child: BlockWidget(data: data, mode: BlockMode.readOnly),
          ),
          const SizedBox(height: 8),
          Text(
            definition.title.isEmpty ? 'Untitled' : definition.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: locked ? theme.disabledColor : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Daily habit',
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
