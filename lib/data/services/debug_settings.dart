import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

class DebugSettings extends ChangeNotifier {
  DebugSettings(this._settings)
    : _debugMenuVisible = _settings.getDebugMenuVisible(),
      _unlockAllDays = _settings.getUnlockAllDays();

  final SettingsStorageService _settings;
  bool _debugMenuVisible;
  bool _unlockAllDays;

  bool get debugMenuVisible => _debugMenuVisible;
  bool get unlockAllDays => _unlockAllDays;

  Future<void> setDebugMenuVisible(bool value) async {
    if (_debugMenuVisible == value) return;
    _debugMenuVisible = value;
    debugPrint('[DebugSettings] debugMenuVisible -> $value');
    await _settings.setDebugMenuVisible(value);
    notifyListeners();
  }

  Future<void> setUnlockAllDays(bool value) async {
    if (_unlockAllDays == value) return;
    _unlockAllDays = value;
    debugPrint('[DebugSettings] unlockAllDays -> $value');
    await _settings.setUnlockAllDays(value);
    notifyListeners();
  }
}
