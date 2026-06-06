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
/// The first 7-day milestone grants the user a one-time reward. The
/// reward always unlocks the **Streak block** ([BlockType.streakBlock])
/// for **everyone** (free and Pro). On top of that:
/// - **Free users** additionally pick one Pro block **or** Pro section to
///   unlock permanently ([claimBlock] / [claimSection]).
/// - **Pro users** additionally get the **Quote block**
///   ([BlockType.quoteBlock]) — downgrade insurance, since the picker
///   would be pointless for someone who already owns everything
///   ([claimAsPro]).
///
/// "Claimed" is derived — every claim path unlocks at least the streak
/// block, so `claimedCount > 0` means the reward is spent. The three
/// claim methods all guard against a second claim.
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

  Future<void> _persistBlocks() => _storage.setStreakRewardBlocksJson(
    jsonEncode([for (final t in _unlockedBlocks) t.name]),
  );

  Future<void> _persistSections() => _storage.setStreakRewardSectionsJson(
    jsonEncode([for (final k in _unlockedSections) k.name]),
  );

  /// Free-user claim: spend the token on a Pro [type], and also unlock
  /// the streak block for everyone. Guards against a second claim.
  Future<void> claimBlock(BlockType type) async {
    if (claimedCount > 0) return;
    _unlockedBlocks = {..._unlockedBlocks, type, BlockType.streakBlock};
    await _persistBlocks();
    debugPrint('[StreakRewardSettings] claimBlock -> ${type.name} + streak');
    notifyListeners();
  }

  /// Free-user claim: spend the token on a Pro [kind] section, and also
  /// unlock the streak block for everyone. Guards against a second claim.
  Future<void> claimSection(SectionKind kind) async {
    if (claimedCount > 0) return;
    _unlockedSections = {..._unlockedSections, kind};
    _unlockedBlocks = {..._unlockedBlocks, BlockType.streakBlock};
    await _persistSections();
    await _persistBlocks();
    debugPrint('[StreakRewardSettings] claimSection -> ${kind.name} + streak');
    notifyListeners();
  }

  /// Pro-user claim: the picker is pointless for someone who already owns
  /// everything, so the reward auto-unlocks the streak block **and** the
  /// quote block. The quote block then survives a future downgrade to
  /// free. Guards against a second claim.
  Future<void> claimAsPro() async {
    if (claimedCount > 0) return;
    _unlockedBlocks = {
      ..._unlockedBlocks,
      BlockType.streakBlock,
      BlockType.quoteBlock,
    };
    await _persistBlocks();
    debugPrint('[StreakRewardSettings] claimAsPro -> streak + quote');
    notifyListeners();
  }

  /// Debug-only: wipe the reward state so the milestone becomes claimable
  /// again. Clears both sets, deletes both persisted keys, then notifies.
  /// Existing entries keep any blocks they already contain — this only
  /// resets the *availability* gating + the "claimed" derivation.
  Future<void> reset() async {
    if (_unlockedBlocks.isEmpty && _unlockedSections.isEmpty) return;
    _unlockedBlocks = <BlockType>{};
    _unlockedSections = <SectionKind>{};
    await _storage.setStreakRewardBlocksJson(null);
    await _storage.setStreakRewardSectionsJson(null);
    debugPrint('[StreakRewardSettings] reset -> cleared all unlocks');
    notifyListeners();
  }
}
