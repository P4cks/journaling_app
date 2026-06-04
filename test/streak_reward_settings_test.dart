import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late SettingsStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('streak_reward_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('settings_test');
    storage = SettingsStorageService(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('settings_test');
    await tempDir.delete(recursive: true);
  });

  StreakResult longest(int n) => StreakResult(current: n, longest: n);

  test('loads unlocked blocks + sections from seeded storage', () async {
    await storage.setStreakRewardBlocksJson(
      jsonEncode([BlockType.quoteBlock.name]),
    );
    await storage.setStreakRewardSectionsJson(
      jsonEncode([SectionKind.wannado.name]),
    );

    final settings = StreakRewardSettings(storage);

    expect(settings.isBlockUnlocked(BlockType.quoteBlock), isTrue);
    expect(settings.isSectionUnlocked(SectionKind.wannado), isTrue);
    expect(settings.isBlockUnlocked(BlockType.weatherApi), isFalse);
    expect(settings.claimedCount, 2);
    expect(settings.hasClaimed, isTrue);
  });

  test('tolerates corrupt / unknown entries by skipping them', () {
    box.put('streak.reward.unlockedBlocks', 'not json{');
    box.put(
      'streak.reward.unlockedSections',
      jsonEncode(['nonexistent_kind', SectionKind.featureBlock.name]),
    );

    final settings = StreakRewardSettings(storage);

    expect(settings.unlockedBlocks, isEmpty);
    expect(settings.isSectionUnlocked(SectionKind.featureBlock), isTrue);
    expect(settings.claimedCount, 1);
  });

  test('claimBlock persists, notifies once, and unlocks', () async {
    final settings = StreakRewardSettings(storage);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.claimBlock(BlockType.quoteBlock);

    expect(settings.isBlockUnlocked(BlockType.quoteBlock), isTrue);
    expect(notifications, 1);
    expect(
      storage.getStreakRewardBlocksJson(),
      jsonEncode([BlockType.quoteBlock.name]),
    );

    // A fresh instance over the same storage re-reads the unlock.
    final reloaded = StreakRewardSettings(storage);
    expect(reloaded.isBlockUnlocked(BlockType.quoteBlock), isTrue);
  });

  test('claimSection persists, notifies once, and unlocks', () async {
    final settings = StreakRewardSettings(storage);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.claimSection(SectionKind.featureBlock);

    expect(settings.isSectionUnlocked(SectionKind.featureBlock), isTrue);
    expect(notifications, 1);
    expect(
      storage.getStreakRewardSectionsJson(),
      jsonEncode([SectionKind.featureBlock.name]),
    );
  });

  test('only one token: a second claim is a no-op', () async {
    final settings = StreakRewardSettings(storage);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.claimBlock(BlockType.quoteBlock);
    await settings.claimBlock(BlockType.weatherApi);
    await settings.claimSection(SectionKind.wannado);

    expect(settings.claimedCount, 1);
    expect(settings.isBlockUnlocked(BlockType.quoteBlock), isTrue);
    expect(settings.isBlockUnlocked(BlockType.weatherApi), isFalse);
    expect(settings.isSectionUnlocked(SectionKind.wannado), isFalse);
    expect(notifications, 1);
  });

  test('isRewardUnclaimed gates on longest >= milestone and unspent', () async {
    final settings = StreakRewardSettings(storage);

    expect(settings.isRewardUnclaimed(longest(6)), isFalse);
    expect(settings.isRewardUnclaimed(longest(kStreakRewardMilestone)), isTrue);
    expect(settings.isRewardUnclaimed(longest(30)), isTrue);

    await settings.claimBlock(BlockType.quoteBlock);

    // Once spent, never unclaimed again — even at a higher longest.
    expect(settings.isRewardUnclaimed(longest(30)), isFalse);
  });
}
