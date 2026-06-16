import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/routing/routes.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/bottom_sheet_scaffold.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/pro_gate.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/section_header.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/sheet_search_field.dart';

/// Result of [showAddSectionSheet]: the chosen [SectionKind] plus an
/// optional [definitionId] (only set for [SectionKind.wannado], pointing
/// at the chosen `WannadoDefinition`).
class AddSectionResult {
  const AddSectionResult(this.kind, {this.definitionId});

  final SectionKind kind;
  final String? definitionId;
}

/// One built-in (non-wanna-do) section type as rendered on the Default
/// tab. The wanna-do carousel is *not* listed here — it's the sheet's
/// "custom" type and lives on the Custom tab (GUS-71).
typedef _SectionEntry = ({
  SectionKind kind,
  HugeIconData icon,
  String label,
  String description,
});

/// Logical groupings for the Default tab, rendered top-to-bottom with a
/// [SectionHeader] above each — mirrors `_builtinCategories` in the
/// add-block sheet (GUS-71). Adding a new built-in [SectionKind] here
/// keeps it grouped; the wanna-do carousel is handled separately on the
/// Custom tab.
const List<({String label, List<_SectionEntry> entries})> _sectionCategories = [
  (
    label: 'Text',
    entries: [
      (
        kind: SectionKind.text,
        icon: HugeIcons.strokeRoundedTextFont,
        label: 'Text section',
        description: 'A full-width multi-line text area.',
      ),
      (
        kind: SectionKind.header,
        icon: HugeIcons.strokeRoundedHeading,
        label: 'Header',
        description: 'A single-line heading to break up the page.',
      ),
    ],
  ),
  (
    label: 'Layout',
    entries: [
      (
        kind: SectionKind.blockGrid,
        icon: HugeIcons.strokeRoundedGrid,
        label: 'Block grid',
        description: 'A 2-column grid of 1×1 blocks. Add blocks to grow it.',
      ),
      (
        kind: SectionKind.divider,
        icon: HugeIcons.strokeRoundedRemove01,
        label: 'Divider',
        description: 'A horizontal rule between sections.',
      ),
    ],
  ),
  (
    label: 'Featured',
    entries: [
      (
        kind: SectionKind.featureBlock,
        icon: HugeIcons.strokeRoundedKeyframe,
        label: 'Feature block',
        description: 'A large 2×2 single block — photo or memory.',
      ),
      (
        kind: SectionKind.blockTextBody,
        icon: HugeIcons.strokeRoundedImage01,
        label: 'Block + text',
        description:
            'A photo or memory floated left with text wrapping around it.',
      ),
    ],
  ),
];

/// Modal bottom sheet that picks a new section type. Mirrors the
/// add-block sheet's features and structure (GUS-71) but stays a vertical
/// list of [ListTile]s rather than a grid:
///
/// - A search field that filters the visible tiles by label / description
///   live as the user types.
/// - A 2-segment `SegmentedButton` switching between **Default** (the
///   built-in section kinds — text, block-grid, header, divider, feature
///   block, block+text — grouped under category headers) and **Custom**
///   (the user's saved `WannadoDefinition`s). The wanna-do carousel is
///   the sheet's "custom" type: each definition surfaces as its own tile,
///   plus a capped "Add wanna-do carousel" button.
///
/// Returns the picked [AddSectionResult] or `null` on dismiss.
/// Block-grid sections start empty; the user adds blocks afterwards and
/// the grid grows to fit.
///
/// Free users may add the section kinds in [kFreeSectionKinds] (text +
/// block-grid + header + divider). `featureBlock` (GUS-19),
/// `blockTextBody` (GUS-9) and `wannado` (GUS-8/GUS-42/GUS-45) are
/// Pro-only: for free users those tiles render greyed with a
/// [ProLockBadge] and tapping presents the paywall, proceeding only on a
/// successful purchase (or if the kind was unlocked via a streak reward).
Future<AddSectionResult?> showAddSectionSheet(
  BuildContext context, {
  required SubscriptionRepository subscriptions,
  required StreakRewardSettings rewards,
  required BlockSettings settings,
}) {
  return showDraggableSheet<AddSectionResult>(
    context,
    title: 'Add a Section',
    slivers: (sheetContext, _) => [
      SliverToBoxAdapter(
        child: _AddSectionSheetBody(
          subscriptions: subscriptions,
          rewards: rewards,
          settings: settings,
        ),
      ),
    ],
  );
}

/// Which tab the sheet is currently showing. The Custom tab holds the
/// user's wanna-do definitions (GUS-71).
enum _SectionTab { defaults, custom }

class _AddSectionSheetBody extends StatefulWidget {
  const _AddSectionSheetBody({
    required this.subscriptions,
    required this.rewards,
    required this.settings,
  });

  final SubscriptionRepository subscriptions;
  final StreakRewardSettings rewards;
  final BlockSettings settings;

  @override
  State<_AddSectionSheetBody> createState() => _AddSectionSheetBodyState();
}

class _AddSectionSheetBodyState extends State<_AddSectionSheetBody> {
  final TextEditingController _searchController = TextEditingController();

  /// Lower-cased, trimmed search query. Empty means "no filter".
  String _query = '';
  _SectionTab _tab = _SectionTab.defaults;

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

  /// Whether [kind] is Pro-locked for the current user — free users who
  /// haven't unlocked it via a streak reward. Mirrors the add-block
  /// `isProOnly` gate.
  bool _isLocked(SectionKind kind) {
    if (widget.subscriptions.isPro) return false;
    if (kFreeSectionKinds.contains(kind)) return false;
    return !widget.rewards.isSectionUnlocked(kind);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SheetSearchField(
                controller: _searchController,
                hintText: 'Search sections',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SegmentedButton<_SectionTab>(
                segments: const [
                  ButtonSegment(
                    value: _SectionTab.defaults,
                    label: Text('Default'),
                  ),
                  ButtonSegment(
                    value: _SectionTab.custom,
                    label: Text('Custom'),
                  ),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (sel) => setState(() => _tab = sel.first),
              ),
            ),
            if (_tab == _SectionTab.defaults)
              _buildDefaultTab()
            else
              _buildCustomTab(settings),
          ],
        );
      },
    );
  }

  /// The Default tab: built-in section kinds grouped under category
  /// headers, filtered by the search query.
  Widget _buildDefaultTab() {
    final groups = <({String label, List<_SectionEntry> entries})>[];
    for (final category in _sectionCategories) {
      final matching = category.entries
          .where((e) => _matches([e.label, e.description]))
          .toList(growable: false);
      if (matching.isEmpty) continue;
      groups.add((label: category.label, entries: matching));
    }

    if (groups.isEmpty) {
      return const NoMatchesHint(message: 'No sections match your search.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          SectionHeader(label: group.label),
          for (final entry in group.entries)
            _SectionTile(
              icon: entry.icon,
              label: entry.label,
              description: entry.description,
              locked: _isLocked(entry.kind),
              onTap: () => _pickKind(entry.kind),
            ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  /// The Custom tab: the user's wanna-do definitions (the sheet's
  /// "custom" type), filtered by the search query, plus the capped
  /// "Add wanna-do carousel" button.
  Widget _buildCustomTab(BlockSettings settings) {
    final theme = Theme.of(context);
    final allDefs = settings.wannadoDefinitions;
    final defs = allDefs
        .where((d) => _matches([d.title]))
        .toList(growable: false);
    final wannadoLocked = _isLocked(SectionKind.wannado);

    final nothingDefined = allDefs.isEmpty;
    final nothingMatches = !nothingDefined && defs.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nothingDefined)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              "You haven't created any wanna-do lists yet. Create one, "
              'then add it as a section.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (nothingMatches)
          const NoMatchesHint(message: 'No sections match your search.')
        else
          for (final def in defs)
            _SectionTile(
              icon: HugeIcons.strokeRoundedSparkles,
              label: def.title.isEmpty ? 'Untitled' : def.title,
              description:
                  '${def.items.length} '
                  'item${def.items.length == 1 ? '' : 's'}',
              locked: wannadoLocked,
              onTap: () => _pickWannado(def.id, locked: wannadoLocked),
            ),
        ProLimitHint(
          used: allDefs.length,
          max: kFreeMaxWannados,
          noun: 'wanna-do carousels',
          subscriptions: widget.subscriptions,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AddCustomBlockButton(
              subscriptions: widget.subscriptions,
              currentCount: allDefs.length,
              max: kFreeMaxWannados,
              label: 'Add wanna-do carousel',
              onAddAllowed: _createWannado,
            ),
          ),
        ),
      ],
    );
  }

  /// Pop the sheet with a built-in [kind]. When the kind is Pro-locked,
  /// present the paywall first and only pop on a successful purchase.
  Future<void> _pickKind(SectionKind kind) async {
    if (!_isLocked(kind)) {
      Navigator.of(context).pop(AddSectionResult(kind));
      return;
    }
    final ok = await requirePro(widget.subscriptions, context: context);
    if (ok && mounted) {
      Navigator.of(context).pop(AddSectionResult(kind));
    }
  }

  /// Pop the sheet with the chosen wanna-do [definitionId]. When the
  /// wanna-do section is Pro-locked, present the paywall first.
  Future<void> _pickWannado(String definitionId, {required bool locked}) async {
    if (!locked) {
      Navigator.of(
        context,
      ).pop(AddSectionResult(SectionKind.wannado, definitionId: definitionId));
      return;
    }
    final ok = await requirePro(widget.subscriptions, context: context);
    if (ok && mounted) {
      Navigator.of(
        context,
      ).pop(AddSectionResult(SectionKind.wannado, definitionId: definitionId));
    }
  }

  /// After the free-cap / paywall check in [AddCustomBlockButton], pop the
  /// add-section sheet and push the wanna-do editor onto the layout-editor
  /// screen so the user can create a new definition, then re-open the
  /// picker to attach it. Mirrors `_promptNewCustomBlockKind` in the
  /// add-block sheet (GUS-71).
  void _createWannado() {
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    navigator.pop();
    router.push(Routes.newWannado);
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.locked = false,
  });

  final HugeIconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = locked ? theme.disabledColor : null;
    return ListTile(
      leading: AppIcon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: locked
              ? theme.disabledColor
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: locked ? const ProLockBadge() : null,
      onTap: onTap,
    );
  }
}
