import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';

/// Lifetime-best streak (in days) at which the user earns the one-time
/// reward. Eligibility keys off `StreakResult.longest`, so the reward is
/// never revoked once a streak breaks.
const kStreakRewardMilestone = 7;

/// Streak-reward state, persisted in the `settings` Hive box.
///
/// The first 7-day milestone grants the user **one** token they may spend
/// to permanently unlock a single Pro block **or** Pro section. "Claimed"
/// is derived — `claimedCount > 0` means the token is spent (see
/// [claimBlock] / [claimSection], which guard against a second claim).
///
/// One instance is constructed in `main.dart` and exposed via
/// `AppDependencies`. The two UI surfaces (the Statistics reward card and
/// the Statistics AppBar badge) and the gating seams (add-block /
/// add-section sheets) read from this object.
class StreakRewardSettings extends ChangeNotifier {
  StreakRewardSettings(this._storage) {
    _load();
  }

  final SettingsStorageService _storage;

  Set<BlockType> _unlockedBlocks = <BlockType>{};
  Set<SectionKind> _unlockedSections = <SectionKind>{};

  void _load() {
    final blocksRaw = _storage.getStreakRewardBlocksJson();
    if (blocksRaw != null && blocksRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(blocksRaw);
        if (decoded is List) {
          final byName = {for (final t in BlockType.values) t.name: t};
          _unlockedBlocks = {
            for (final v in decoded)
              if (v is String && byName.containsKey(v)) byName[v]!,
          };
        }
      } catch (_) {
        // Corrupt JSON — fall back to empty.
      }
    }
    final sectionsRaw = _storage.getStreakRewardSectionsJson();
    if (sectionsRaw != null && sectionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(sectionsRaw);
        if (decoded is List) {
          final byName = {for (final k in SectionKind.values) k.name: k};
          _unlockedSections = {
            for (final v in decoded)
              if (v is String && byName.containsKey(v)) byName[v]!,
          };
        }
      } catch (_) {
        // Corrupt JSON — fall back to empty.
      }
    }
  }

  Set<BlockType> get unlockedBlocks => Set.unmodifiable(_unlockedBlocks);
  Set<SectionKind> get unlockedSections => Set.unmodifiable(_unlockedSections);

  bool isBlockUnlocked(BlockType type) => _unlockedBlocks.contains(type);
  bool isSectionUnlocked(SectionKind kind) =>
      _unlockedSections.contains(kind);

  /// How many tokens the user has spent. The first milestone grants
  /// exactly one, so `claimedCount > 0` ⇒ the token is spent.
  int get claimedCount => _unlockedBlocks.length + _unlockedSections.length;

  bool get hasClaimed => claimedCount > 0;

  /// True when the user has earned the milestone but not yet spent the
  /// token. Single source of truth for both the reward card and the
  /// AppBar badge.
  bool isRewardUnclaimed(StreakResult streak) =>
      streak.longest >= kStreakRewardMilestone && claimedCount == 0;

  Future<void> claimBlock(BlockType type) async {
    if (claimedCount > 0) return;
    _unlockedBlocks = {..._unlockedBlocks, type};
    await _storage.setStreakRewardBlocksJson(
      jsonEncode([for (final t in _unlockedBlocks) t.name]),
    );
    debugPrint('[StreakRewardSettings] claimBlock -> ${type.name}');
    notifyListeners();
  }

  Future<void> claimSection(SectionKind kind) async {
    if (claimedCount > 0) return;
    _unlockedSections = {..._unlockedSections, kind};
    await _storage.setStreakRewardSectionsJson(
      jsonEncode([for (final k in _unlockedSections) k.name]),
    );
    debugPrint('[StreakRewardSettings] claimSection -> ${kind.name}');
    notifyListeners();
  }
}
