import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_content/custom_carousel_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/habit_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/mood_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/prompt_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_content/text_block_content.dart';
import 'package:journaling_app_rewrite/data/model/block_template.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/entry_section.dart';
import 'package:journaling_app_rewrite/data/model/journal_block_data.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry.dart';
import 'package:journaling_app_rewrite/data/model/journal_entry_emptiness.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/model/block_visuals.dart';
import 'package:journaling_app_rewrite/data/repositories/layout_repository.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';
import 'package:journaling_app_rewrite/data/services/hive_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/theme_settings.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Single source of truth for journal entries. Extends [ChangeNotifier]
/// so view models can subscribe and react to creates/updates/deletes/sweeps
/// without each owner having to plumb refresh calls through.
class JournalRepository extends ChangeNotifier {
  final HiveStorageService _storage;
  final LayoutRepository _layouts;
  final BlockSettings _blockSettings;
  final ThemeSettings _themeSettings;

  JournalRepository(
    this._storage,
    this._layouts,
    this._blockSettings,
    this._themeSettings,
  );

  final Random _rng = Random();

  /// Local-midnight normalization. All repository methods normalize inputs
  /// before keying so callers don't have to. Times-of-day on the input
  /// `DateTime` are discarded.
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dateKey(DateTime date) => _normalize(date).toIso8601String();

  JournalEntry? getEntryForDate(DateTime date) {
    final key = _dateKey(date);
    final entry = _storage.getJournalEntry(key);
    debugPrint(
      '[JournalRepository] getEntryForDate($key) -> ${entry ?? 'null'}',
    );
    return entry;
  }

  /// Creates a new entry for [date] using either the explicitly supplied
  /// [layout] or, if `null`, the user's default layout. Saves and returns it.
  /// **Does not check for an existing entry** — callers should use
  /// [getEntryForDate] first if they want to avoid overwriting.
  JournalEntry createEntryForDate(DateTime date, {JournalLayout? layout}) {
    final resolvedLayout = layout ?? _layouts.getDefault();
    final normalizedDate = _normalize(date);
    final entry = JournalEntry(
      id: _uuid.v4(),
      date: normalizedDate,
      lastModified: DateTime.now(),
      sections: materializeLayout(resolvedLayout, normalizedDate),
    );
    debugPrint(
      '[JournalRepository] created $entry from layout=${resolvedLayout?.name ?? '<none>'}',
    );
    saveJournalEntry(entry);
    return entry;
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    debugPrint('[JournalRepository] saveJournalEntry $entry');
    await _storage.saveJournalEntry(_dateKey(entry.date), entry);
    notifyListeners();
  }

  /// All entries across all days, in unspecified order. Sorting/grouping
  /// is the caller's responsibility.
  List<JournalEntry> getAllEntries() {
    final all = _storage.getAllJournalEntries();
    debugPrint('[JournalRepository] getAllEntries -> ${all.length} entries');
    return all;
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    debugPrint('[JournalRepository] deleteEntry $entry');
    await _storage.deleteJournalEntry(_dateKey(entry.date));
    notifyListeners();
  }

  /// Wipes every entry. Destructive — exposed for the debug menu's
  /// "Delete all entries" action. Returns the number deleted; notifies
  /// once if anything was deleted.
  Future<int> deleteAllEntries() async {
    final all = getAllEntries();
    if (all.isEmpty) return 0;
    for (final entry in all) {
      await _storage.deleteJournalEntry(_dateKey(entry.date));
    }
    debugPrint('[JournalRepository] deleteAllEntries removed ${all.length}');
    notifyListeners();
    return all.length;
  }

  /// Removes past-day entries whose every block is at its default empty
  /// state. Today's entries are never deleted — the user may still be
  /// drafting. Pass [now] in tests; defaults to `DateTime.now()`.
  ///
  /// Returns the number of entries deleted. Notifies once if any entry
  /// was deleted (not per-entry — listeners just need to know "something
  /// changed").
  Future<int> sweepEmptyPastEntries({DateTime? now}) async {
    final today = _normalize(now ?? DateTime.now());
    var deleted = 0;
    for (final entry in getAllEntries()) {
      final entryDay = _normalize(entry.date);
      if (!entryDay.isBefore(today)) continue;
      if (!entry.hasNoContent) continue;
      await _storage.deleteJournalEntry(_dateKey(entry.date));
      deleted++;
    }
    if (deleted > 0) {
      debugPrint(
        '[JournalRepository] sweepEmptyPastEntries removed $deleted entries',
      );
      notifyListeners();
    }
    return deleted;
  }

  /// **Debug-only.** Generates randomized sample entries across the
  /// past [days] days to populate the statistics charts (GUS-35). Each
  /// generated entry gets one block-grid section with a text block
  /// (random word count) and a mood tracker (random emoji, occasionally
  /// none so the mood-over-time line shows gaps), so every stat —
  /// counts, words, mood distribution / over-time, and entry frequency
  /// — has data to render. Roughly [density] of the days get an entry
  /// so the frequency chart isn't a solid wall of bars.
  ///
  /// Days that already have an entry are skipped so real data is never
  /// overwritten. Today is left untouched (the user may be drafting).
  /// Returns the number of entries created; notifies once if any were.
  Future<int> debugGenerateSampleEntries({
    int days = 400,
    double density = 0.7,
  }) async {
    final today = _normalize(DateTime.now());
    var created = 0;
    for (var back = 1; back <= days; back++) {
      if (_rng.nextDouble() > density) continue;
      final date = today.subtract(Duration(days: back));
      if (getEntryForDate(date) != null) continue;
      final entry = JournalEntry(
        id: _uuid.v4(),
        date: date,
        lastModified: DateTime.now(),
        sections: [
          EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.blockGrid,
            rows: 1,
            blocks: [
              JournalBlockData.create(
                id: _uuid.v4(),
                type: BlockType.textBlock,
                content: TextBlockContent(text: _sampleText()).toMap(),
                visuals: BlockVisuals.random(
                  _rng,
                  _themeSettings.postItPalette,
                ),
              ),
              JournalBlockData.create(
                id: _uuid.v4(),
                type: BlockType.moodTracker,
                content: MoodBlockContent(emoji: _sampleMood()).toMap(),
                visuals: BlockVisuals.random(
                  _rng,
                  _themeSettings.postItPalette,
                ),
              ),
            ],
          ),
        ],
      );
      await _storage.saveJournalEntry(_dateKey(date), entry);
      created++;
    }
    if (created > 0) {
      debugPrint(
        '[JournalRepository] debugGenerateSampleEntries created $created '
        'over $days days',
      );
      notifyListeners();
    }
    return created;
  }

  /// ~15% of generated days have no mood, so the mood-over-time line
  /// renders gaps (the VM emits `null` for moodless days).
  String? _sampleMood() {
    if (_rng.nextDouble() < 0.15) return null;
    return moodEmojis[_rng.nextInt(moodEmojis.length)];
  }

  static const _sampleWords = <String>[
    'today',
    'I',
    'felt',
    'grateful',
    'for',
    'the',
    'small',
    'moments',
    'work',
    'was',
    'busy',
    'but',
    'good',
    'walked',
    'in',
    'park',
    'and',
    'read',
    'a',
    'book',
    'tired',
    'happy',
    'calm',
    'thinking',
    'about',
    'tomorrow',
    'coffee',
    'rain',
    'sun',
    'morning',
    'evening',
    'friends',
  ];

  String _sampleText() {
    final count = 5 + _rng.nextInt(40);
    return List.generate(
      count,
      (_) => _sampleWords[_rng.nextInt(_sampleWords.length)],
    ).join(' ');
  }

  /// Materializes [layout] into a fresh list of [EntrySection]s with
  /// per-type initial content seeded from block-type-global settings.
  ///
  /// Text sections each get a single fresh `JournalBlockData(textBlock)`
  /// with empty `TextBlockContent`. Block-grid sections materialize one
  /// `JournalBlockData` per template in their `blocks` list. Prompt
  /// slots are numbered layout-wide so multiple prompt blocks (across
  /// any section) get distinct daily picks.
  ///
  /// Exposed publicly so the editor's `applyLayout` / change-layout
  /// flow stays in sync with `createEntryForDate`.
  List<EntrySection> materializeLayout(JournalLayout? layout, DateTime date) {
    if (layout == null) return const [];
    var promptSlotIndex = 0;
    int nextPromptSlot() => promptSlotIndex++;
    return [
      for (final section in layout.sections)
        switch (section.kind) {
          SectionKind.text => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.text,
            blocks: [
              JournalBlockData.create(
                id: _uuid.v4(),
                type: BlockType.textBlock,
                content: const TextBlockContent(text: '').toMap(),
              ),
            ],
          ),
          SectionKind.blockGrid => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.blockGrid,
            rows: section.rows,
            blocks: [
              for (final template in section.blocks)
                _materializeOne(template, date, nextPromptSlot),
            ],
          ),
          SectionKind.featureBlock => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.featureBlock,
            blocks: section.blocks.isEmpty
                ? const []
                : [_materializeOne(section.blocks.first, date, nextPromptSlot)],
          ),
          // Header reuses the text-block JSON path (like `text`): one
          // fresh empty textBlock holds the heading string.
          SectionKind.header => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.header,
            blocks: [
              JournalBlockData.create(
                id: _uuid.v4(),
                type: BlockType.textBlock,
                content: const TextBlockContent(text: '').toMap(),
              ),
            ],
          ),
          // Divider is purely visual — carries no blocks.
          SectionKind.divider => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.divider,
            blocks: const [],
          ),
          // Block + text body: the float block (any type — GUS-46 — 0 or
          // 1 template) materialized like `featureBlock`, plus a fresh
          // empty `textBlock` (like `text`) appended LAST. The pager keys
          // off this order (body = last block), so the float may itself
          // be a textBlock without ambiguity.
          SectionKind.blockTextBody => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.blockTextBody,
            blocks: [
              if (section.blocks.isNotEmpty)
                _materializeOne(section.blocks.first, date, nextPromptSlot),
              JournalBlockData.create(
                id: _uuid.v4(),
                type: BlockType.textBlock,
                content: const TextBlockContent(text: '').toMap(),
              ),
            ],
          ),
          // Wanna-do carousel renders a `WannadoDefinition` off
          // `BlockSettings` (resolved by `definitionId`); the section
          // carries no per-entry blocks. Carry the chosen definition id
          // across from the layout section so the entry renders the same
          // list the layout pointed at.
          SectionKind.wannado => EntrySection(
            id: _uuid.v4(),
            kind: SectionKind.wannado,
            blocks: const [],
            definitionId: section.definitionId,
          ),
        },
    ];
  }

  /// Picks a random non-empty block from a past (strictly-before [beforeDate])
  /// entry, restricted to types in [eligibleTypes]. Returns the parent
  /// entry's normalized date alongside the block so callers can persist
  /// both for tap-to-navigate. Returns `null` when no eligible blocks
  /// exist.
  ({DateTime date, JournalBlockData block})? pickRandomEligibleBlock({
    required DateTime beforeDate,
    required Set<BlockType> eligibleTypes,
  }) {
    final cutoff = _normalize(beforeDate);
    final pool = <({DateTime date, JournalBlockData block})>[];
    for (final entry in getAllEntries()) {
      if (!_normalize(entry.date).isBefore(cutoff)) continue;
      for (final section in entry.sections) {
        for (final block in section.blocks) {
          if (!eligibleTypes.contains(block.type)) continue;
          if (block.isEmpty) continue;
          pool.add((date: _normalize(entry.date), block: block));
        }
      }
    }
    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  JournalBlockData _materializeOne(
    BlockTemplate template,
    DateTime date,
    int Function() nextPromptSlotIndex,
  ) {
    final type = template.type;
    final visuals = BlockVisuals.random(_rng, _themeSettings.postItPalette);
    switch (type) {
      case BlockType.promptBlock:
        final slot = nextPromptSlotIndex();
        final prompt = _blockSettings.pickPromptFor(
          date: date,
          slotIndex: slot,
        );
        return JournalBlockData.create(
          id: _uuid.v4(),
          type: type,
          content: PromptBlockContent(prompt: prompt ?? '', answer: '').toMap(),
          visuals: visuals,
        );
      case BlockType.customCarousel:
        // Carry the layout slot's definitionId through to the entry so
        // the widget can resolve the registry at render time. No
        // selection yet — the user has to tap to pick.
        final defId = template.config['definitionId'] as String?;
        return JournalBlockData.create(
          id: _uuid.v4(),
          type: type,
          content: CustomCarouselBlockContent(definitionId: defId).toMap(),
          visuals: visuals,
        );
      case BlockType.habitTracker:
        // Carry the layout slot's definitionId through to the entry so
        // the widget can resolve the registry at render time. Not
        // completed yet — the user taps the checkbox to cross it off.
        final defId = template.config['definitionId'] as String?;
        return JournalBlockData.create(
          id: _uuid.v4(),
          type: type,
          content: HabitBlockContent(definitionId: defId).toMap(),
          visuals: visuals,
        );
      case BlockType.moodTracker:
      case BlockType.weatherManual:
      case BlockType.textBlock:
      case BlockType.todoBlock:
      case BlockType.quoteBlock:
      case BlockType.memoryBlock:
      case BlockType.weatherApi:
      case BlockType.photoBlock:
      case BlockType.locationBlock:
      case BlockType.streakBlock:
        return JournalBlockData.create(
          id: _uuid.v4(),
          type: type,
          content: const {},
          visuals: visuals,
        );
    }
  }
}
