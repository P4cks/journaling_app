import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
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

  Future<void> save(JournalLayout layout) {
    debugPrint(
      '[LayoutRepository] save id=${layout.id} name=${layout.name} blocks=${layout.blocks}',
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
    final seed = JournalLayout(
      id: _uuid.v4(),
      name: 'Default',
      blocks: const [BlockType.textBlock],
    );
    debugPrint(
      '[LayoutRepository] seeding fresh default layout ${seed.name} (${seed.id})',
    );
    await _layouts.saveLayout(seed);
    await _settings.setDefaultLayoutId(seed.id);
    return seed;
  }
}
