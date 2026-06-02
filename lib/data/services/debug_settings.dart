import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

class DebugSettings extends ChangeNotifier {
  DebugSettings(this._settings)
    : _debugMenuVisible = _settings.getDebugMenuVisible(),
      _unlockAllDays = _settings.getUnlockAllDays(),
      _showExpandedBlockDoneButton = _settings.getDebugExpandedDoneButton(),
      _textBlockCharLimit = _settings.getLimitTextBlock(),
      _textSectionCharLimit = _settings.getLimitTextSection(),
      _promptCharLimit = _settings.getLimitPrompt(),
      _todoItemCharLimit = _settings.getLimitTodoItem(),
      _todoMaxItems = _settings.getLimitTodoMaxItems();

  final SettingsStorageService _settings;
  bool _debugMenuVisible;
  bool _unlockAllDays;
  bool _showExpandedBlockDoneButton;

  // Per-block input-limit overrides. `null` = use the hard-coded default
  // in `BlockInputLimits`. Tunable from the debug menu so we can find
  // good values before baking them into the defaults.
  int? _textBlockCharLimit;
  int? _textSectionCharLimit;
  int? _promptCharLimit;
  int? _todoItemCharLimit;
  int? _todoMaxItems;

  bool get debugMenuVisible => _debugMenuVisible;
  bool get unlockAllDays => _unlockAllDays;
  bool get showExpandedBlockDoneButton => _showExpandedBlockDoneButton;

  int? get textBlockCharLimit => _textBlockCharLimit;
  int? get textSectionCharLimit => _textSectionCharLimit;
  int? get promptCharLimit => _promptCharLimit;
  int? get todoItemCharLimit => _todoItemCharLimit;
  int? get todoMaxItems => _todoMaxItems;

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

  Future<void> setTextBlockCharLimit(int? value) async {
    if (_textBlockCharLimit == value) return;
    _textBlockCharLimit = value;
    debugPrint('[DebugSettings] textBlockCharLimit -> $value');
    await _settings.setLimitTextBlock(value);
    notifyListeners();
  }

  Future<void> setTextSectionCharLimit(int? value) async {
    if (_textSectionCharLimit == value) return;
    _textSectionCharLimit = value;
    debugPrint('[DebugSettings] textSectionCharLimit -> $value');
    await _settings.setLimitTextSection(value);
    notifyListeners();
  }

  Future<void> setPromptCharLimit(int? value) async {
    if (_promptCharLimit == value) return;
    _promptCharLimit = value;
    debugPrint('[DebugSettings] promptCharLimit -> $value');
    await _settings.setLimitPrompt(value);
    notifyListeners();
  }

  Future<void> setTodoItemCharLimit(int? value) async {
    if (_todoItemCharLimit == value) return;
    _todoItemCharLimit = value;
    debugPrint('[DebugSettings] todoItemCharLimit -> $value');
    await _settings.setLimitTodoItem(value);
    notifyListeners();
  }

  Future<void> setTodoMaxItems(int? value) async {
    if (_todoMaxItems == value) return;
    _todoMaxItems = value;
    debugPrint('[DebugSettings] todoMaxItems -> $value');
    await _settings.setLimitTodoMaxItems(value);
    notifyListeners();
  }
}
