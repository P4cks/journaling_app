import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/data/model/carousel_item.dart';
import 'package:journaling_app_rewrite/data/model/custom_carousel_definition.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/blocks/chrome/block_chrome.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_mode.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_type_display.dart';
import 'package:journaling_app_rewrite/ui/blocks/block_widget.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';

/// Block types intentionally hidden from the layout-editor picker.
///
/// `locationBlock` is still WIP. `customCarousel` is excluded from the
/// built-in grid because user-defined carousel "types" surface as their
/// own per-definition tiles in the custom-blocks section below — there's
/// no abstract "Custom carousel" tile that would make sense without an
/// id to attach.
const _hiddenBlockTypes = <BlockType>{
  BlockType.locationBlock,
  BlockType.customCarousel,
};

/// Discriminated return type for [showAddBlockSheet]:
/// - [AddBlockResultBuiltin] — user picked a built-in `BlockType`.
/// - [AddBlockResultCustom] — user picked one of their saved
///   custom-carousel definitions; the layout editor stores
///   `definitionId` on the slot.
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

/// Half-screen modal sheet that lets the user pick a block to add.
///
/// Layout (top → bottom):
/// - A search field that filters the visible cells by `BlockType.label`
///   / `description` (and custom-definition title) live as the user
///   types. (GUS-20)
/// - When [allowedTypes] is null: a 2-segment `SegmentedButton` tab
///   switcher between **Default** (built-in `BlockType`s) and **Custom**
///   (the user's saved custom-carousel definitions). (GUS-24) The
///   built-in grid and the custom section render one-at-a-time based on
///   the active tab rather than stacked.
/// - The active tab's content: built-in cells in a 2-column grid, or the
///   custom-definition cells plus an "Add custom block" button that
///   pushes the editor screen — on save the sheet rebuilds via a
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

/// Which of the two tabs the sheet is currently showing. Only relevant
/// when the custom section is visible (`allowedTypes == null`).
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

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isPro = subscriptions.isPro;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _SearchField(controller: _searchController),
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
              _buildBuiltinGrid(subscriptions: subscriptions, isPro: isPro)
            else
              _buildCustomSection(
                settings: settings,
                subscriptions: subscriptions,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBuiltinGrid({
    required SubscriptionRepository subscriptions,
    required bool isPro,
  }) {
    final allowed = widget.allowedTypes;
    final visibleTypes = BlockType.values
        .where((t) => !_hiddenBlockTypes.contains(t))
        .where((t) => allowed == null || allowed.contains(t))
        .where((t) => _matches([t.label, t.description]))
        .toList(growable: false);

    if (visibleTypes.isEmpty) {
      return const _NoMatchesHint();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: visibleTypes.length,
        itemBuilder: (gridCtx, i) => _BuiltinCell(
          type: visibleTypes[i],
          locked: !isPro && visibleTypes[i].isProOnly,
          subscriptions: subscriptions,
        ),
      ),
    );
  }

  Widget _buildCustomSection({
    required BlockSettings settings,
    required SubscriptionRepository subscriptions,
  }) {
    final theme = Theme.of(context);
    final allCustoms = settings.customCarousels;
    final customs = allCustoms
        .where((d) => _matches([d.title]))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allCustoms.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "You haven't defined any custom carousel blocks yet.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (customs.isEmpty)
          const _NoMatchesHint()
        else
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
                // Already-created custom blocks are always usable —
                // the Pro cap applies to *creating* a new one, gated
                // on the "Add custom block" button below. (GUS-34)
                locked: false,
                subscriptions: subscriptions,
              ),
            ),
          ),
        ProLimitHint(
          used: allCustoms.length,
          max: kFreeMaxCustomBlocks,
          noun: 'custom blocks',
          subscriptions: subscriptions,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: AddCustomBlockButton(
            subscriptions: subscriptions,
            currentCount: allCustoms.length,
            onAddAllowed: () {
              // Pop the sheet first so the editor pushes onto the
              // layout-editor screen, not the sheet.
              Navigator.of(context).pop();
              GoRouter.of(context).push(Routes.newCustomBlock);
            },
          ),
        ),
      ],
    );
  }
}

/// Rounded search input used at the top of the add-block sheet. Shows a
/// leading search glyph and a trailing clear button once non-empty.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search blocks',
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

/// Empty-state caption shown when the active tab has no cells matching
/// the current search query.
class _NoMatchesHint extends StatelessWidget {
  const _NoMatchesHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Text(
        'No blocks match your search.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
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
