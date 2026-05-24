import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/layout_kind.dart';
import 'package:journaling_app_rewrite/data/model/layout_section.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/services/layout_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class LayoutRepository {
  final LayoutStorageService _layouts;
  final SettingsStorageService _settings;

  LayoutRepository(this._layouts, this._settings);

  List<JournalLayout> getAll() {
    final all = _layouts.getAllLayouts();
    debugPrint('[LayoutRepository] getAll -> ${all.length} layouts');
    return all;
  }

  JournalLayout? getById(String id) => _layouts.getLayout(id);

  /// Counts layout template slots that reference a custom carousel definition.
  ///
  /// [definitionId] is the custom block definition id stored in a template's
  /// config map. The output is the number of layout block slots that currently
  /// point at that definition, which callers use to warn before deletion.
  int countCustomCarouselUsage(String definitionId) {
    var count = 0;
    for (final layout in _layouts.getAllLayouts()) {
      for (final section in layout.sections) {
        for (final template in section.blocks) {
          if (template.type != BlockType.customCarousel) continue;
          if (template.config['definitionId'] == definitionId) count++;
        }
      }
    }
    return count;
  }

  Future<void> save(JournalLayout layout) {
    debugPrint(
      '[LayoutRepository] save id=${layout.id} name=${layout.name} kind=${layout.kind} sections=${layout.sections.length}',
    );
    return _layouts.saveLayout(layout);
  }

  Future<void> delete(String id) async {
    debugPrint('[LayoutRepository] delete id=$id');
    await _layouts.deleteLayout(id);
    if (_settings.getDefaultLayoutId() == id) {
      debugPrint('[LayoutRepository] cleared default (was $id)');
      await _settings.clearDefaultLayoutId();
    }
  }

  /// Wipes every layout, then immediately re-seeds a fresh "Default"
  /// layout so the user isn't stranded with no way to create entries.
  /// Destructive — exposed for the debug menu's "Delete all layouts"
  /// action. Returns the number deleted (excludes the re-seeded
  /// default).
  Future<int> deleteAllLayouts() async {
    final all = _layouts.getAllLayouts();
    for (final layout in all) {
      await _layouts.deleteLayout(layout.id);
    }
    await _settings.clearDefaultLayoutId();
    debugPrint('[LayoutRepository] deleteAllLayouts removed ${all.length}');
    await seedDefaultIfEmpty();
    return all.length;
  }

  JournalLayout? getDefault() {
    final id = _settings.getDefaultLayoutId();
    if (id == null) {
      debugPrint('[LayoutRepository] getDefault -> no default set');
      return null;
    }
    final layout = _layouts.getLayout(id);
    debugPrint(
      '[LayoutRepository] getDefault -> ${layout?.name ?? '<missing>'} ($id)',
    );
    return layout;
  }

  Future<void> setDefault(String id) {
    debugPrint('[LayoutRepository] setDefault id=$id');
    return _settings.setDefaultLayoutId(id);
  }

  /// First-launch invariant: guarantees there is at least one layout
  /// and one default selection so the journal editor never has to
  /// branch on "no layouts exist."
  ///
  /// Behaviour, idempotent across launches:
  /// - If the layouts box already has entries: keep them. If no default
  ///   id is set, adopt the existing default (or the first stored
  ///   layout if there's no `getDefault()` hit) so subsequent calls to
  ///   `JournalRepository.createEntryForDate(date, layout: null)`
  ///   always resolve.
  /// - If the box is empty: create a minimal block-only layout named
  ///   "Default" with one row and a single text block, persist it, and
  ///   set it as the default.
  ///
  /// Called from `main.dart` after services are wired and before
  /// `runApp`. Also called from [deleteAllLayouts] so the debug
  /// "Delete all layouts" action never leaves the user stranded.
  /// Returns the layout that ended up as the default.
  Future<JournalLayout> seedDefaultIfEmpty() async {
    if (!_layouts.isEmpty) {
      final existing = getDefault() ?? _layouts.getAllLayouts().first;
      if (_settings.getDefaultLayoutId() == null) {
        debugPrint(
          '[LayoutRepository] no default set; adopting ${existing.id}',
        );
        await _settings.setDefaultLayoutId(existing.id);
      }
      debugPrint(
        '[LayoutRepository] seedDefaultIfEmpty: keeping existing default ${existing.name}',
      );
      return existing;
    }
    // Default layout: a 4-slot block grid (2 cols × 2 rows) followed
    // by a full-width text section, using `LayoutKind.custom` (the
    // "normal" reorderable kind — NOT `fixedFourPlusText`, which is
    // structurally locked). `custom` lets users drag-reorder the four
    // blocks in their journal entries.
    final seed = JournalLayout(
      id: _uuid.v4(),
      name: 'Default',
      kind: LayoutKind.custom,
      sections: [
        LayoutSection(
          id: _uuid.v4(),
          kind: SectionKind.blockGrid,
          rows: 2,
          blocks: [
            for (var i = 0; i < 4; i++)
              BlockTemplate.create(id: _uuid.v4(), type: BlockType.textBlock),
          ],
        ),
        LayoutSection(
          id: _uuid.v4(),
          kind: SectionKind.text,
          rows: null,
          blocks: const [],
        ),
      ],
    );
    debugPrint(
      '[LayoutRepository] seeding fresh default layout ${seed.name} (${seed.id})',
    );
    await _layouts.saveLayout(seed);
    await _settings.setDefaultLayoutId(seed.id);
    return seed;
  }
}
