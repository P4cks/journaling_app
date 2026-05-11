import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

class DebugSettings extends ChangeNotifier {
  DebugSettings(this._settings) : _unlockAllDays = _settings.getUnlockAllDays();

  final SettingsStorageService _settings;
  bool _unlockAllDays;

  bool get unlockAllDays => _unlockAllDays;

  Future<void> setUnlockAllDays(bool value) async {
    if (_unlockAllDays == value) return;
    _unlockAllDays = value;
    debugPrint('[DebugSettings] unlockAllDays -> $value');
    await _settings.setUnlockAllDays(value);
    notifyListeners();
  }
}
