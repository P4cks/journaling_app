import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

class DebugSettings extends ChangeNotifier {
  DebugSettings(this._settings)
    : _debugMenuVisible = _settings.getDebugMenuVisible(),
      _unlockAllDays = _settings.getUnlockAllDays(),
      _showExpandedBlockDoneButton = _settings.getDebugExpandedDoneButton();

  final SettingsStorageService _settings;
  bool _debugMenuVisible;
  bool _unlockAllDays;
  bool _showExpandedBlockDoneButton;

  bool get debugMenuVisible => _debugMenuVisible;
  bool get unlockAllDays => _unlockAllDays;
  bool get showExpandedBlockDoneButton => _showExpandedBlockDoneButton;

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

  Future<void> setShowExpandedBlockDoneButton(bool value) async {
    if (_showExpandedBlockDoneButton == value) return;
    _showExpandedBlockDoneButton = value;
    debugPrint('[DebugSettings] showExpandedBlockDoneButton -> $value');
    await _settings.setDebugExpandedDoneButton(value);
    notifyListeners();
  }
}
