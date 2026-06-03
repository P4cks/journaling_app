import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:journaling_app_rewrite/data/services/block_settings.dart';

/// Backs [BlockSettingsScreen]. Snapshots the current [BlockSettings] on
/// construction into draft fields and only writes back when [save] is
/// called. Mirrors `LayoutEditorViewModel`'s draft / `isDirty` /
/// save-on-leave shape so the screen can reuse the same Cancel /
/// Discard / Save dialog UX.
///
/// Edits never touch the underlying [BlockSettings] until [save] runs,
/// so leaving the screen with Discard leaves both UI and persisted
/// state unchanged.
class BlockSettingsViewModel extends ChangeNotifier {
  BlockSettingsViewModel({required BlockSettings settings})
    : _settings = settings {
    _initialPrompts = settings.prompts;
    _initialPromptStrategy = settings.promptStrategy;
    _initialCarouselTitlesEnabled = settings.carouselTitlesEnabled;
    _promptStrategy = _initialPromptStrategy;
    _carouselTitlesEnabled = _initialCarouselTitlesEnabled;
    promptsController = TextEditingController(text: _initialPrompts.join('\n'));
    promptsController.addListener(_notify);
  }

  final BlockSettings _settings;

  late List<String> _initialPrompts;
  late PromptStrategy _initialPromptStrategy;
  late bool _initialCarouselTitlesEnabled;

  late final TextEditingController promptsController;
  late PromptStrategy _promptStrategy;
  late bool _carouselTitlesEnabled;

  PromptStrategy get promptStrategy => _promptStrategy;
  bool get carouselTitlesEnabled => _carouselTitlesEnabled;

  void setPromptStrategy(PromptStrategy strategy) {
    if (_promptStrategy == strategy) return;
    _promptStrategy = strategy;
    notifyListeners();
  }

  void setCarouselTitlesEnabled(bool value) {
    if (_carouselTitlesEnabled == value) return;
    _carouselTitlesEnabled = value;
    notifyListeners();
  }

  void _notify() => notifyListeners();

  List<String> _parsedPrompts() => [
    for (final line in promptsController.text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  bool get isDirty {
    if (!listEquals(_parsedPrompts(), _initialPrompts)) return true;
    if (_promptStrategy != _initialPromptStrategy) return true;
    if (_carouselTitlesEnabled != _initialCarouselTitlesEnabled) return true;
    return false;
  }

  /// Whether the current draft is in a saveable state. Always true for
  /// the moment — kept as a getter so the screen's save-on-leave dialog
  /// keeps the same code path if validation comes back later.
  bool get canSave => true;

  /// Writes the current drafts back to [BlockSettings] and re-snapshots
  /// so `isDirty` reads false post-save.
  Future<bool> save() async {
    final prompts = _parsedPrompts();
    await _settings.setPrompts(prompts);
    await _settings.setPromptStrategy(_promptStrategy);
    await _settings.setCarouselTitlesEnabled(_carouselTitlesEnabled);
    _initialPrompts = prompts;
    _initialPromptStrategy = _promptStrategy;
    _initialCarouselTitlesEnabled = _carouselTitlesEnabled;
    debugPrint('[BlockSettingsVM] saved');
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    promptsController.removeListener(_notify);
    promptsController.dispose();
    super.dispose();
  }
}
