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
    _initialTextCharLimit = settings.textCharLimit;
    _initialMoodTitle = settings.moodTitle;
    _initialWeatherTitle = settings.weatherTitle;
    _promptStrategy = _initialPromptStrategy;
    promptsController = TextEditingController(
      text: _initialPrompts.join('\n'),
    );
    textCharLimitController = TextEditingController(
      text: _initialTextCharLimit?.toString() ?? '',
    );
    moodTitleController = TextEditingController(text: _initialMoodTitle ?? '');
    weatherTitleController = TextEditingController(
      text: _initialWeatherTitle ?? '',
    );
    promptsController.addListener(_notify);
    textCharLimitController.addListener(_notify);
    moodTitleController.addListener(_notify);
    weatherTitleController.addListener(_notify);
  }

  final BlockSettings _settings;

  late List<String> _initialPrompts;
  late PromptStrategy _initialPromptStrategy;
  late int? _initialTextCharLimit;
  late String? _initialMoodTitle;
  late String? _initialWeatherTitle;

  late final TextEditingController promptsController;
  late final TextEditingController textCharLimitController;
  late final TextEditingController moodTitleController;
  late final TextEditingController weatherTitleController;
  late PromptStrategy _promptStrategy;

  PromptStrategy get promptStrategy => _promptStrategy;

  void setPromptStrategy(PromptStrategy strategy) {
    if (_promptStrategy == strategy) return;
    _promptStrategy = strategy;
    notifyListeners();
  }

  void _notify() => notifyListeners();

  List<String> _parsedPrompts() => [
    for (final line in promptsController.text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];

  int? _parsedTextCharLimit() {
    final raw = textCharLimitController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  /// Non-null when the text-char-limit field has invalid content — i.e.
  /// non-empty and not a positive whole number. The screen surfaces
  /// this on the TextField and disables save until it's clear.
  String? get textCharLimitError {
    final raw = textCharLimitController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      return 'Enter a positive whole number, or leave blank.';
    }
    return null;
  }

  String? _normalizeTitle(String s) {
    final trimmed = s.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get isDirty {
    if (!listEquals(_parsedPrompts(), _initialPrompts)) return true;
    if (_promptStrategy != _initialPromptStrategy) return true;
    if (_parsedTextCharLimit() != _initialTextCharLimit) return true;
    if (_normalizeTitle(moodTitleController.text) != _initialMoodTitle) {
      return true;
    }
    if (_normalizeTitle(weatherTitleController.text) != _initialWeatherTitle) {
      return true;
    }
    return false;
  }

  bool get canSave => textCharLimitError == null;

  /// Writes the current drafts back to [BlockSettings] and re-snapshots
  /// so `isDirty` reads false post-save. Returns false (without writing)
  /// when validation fails.
  Future<bool> save() async {
    if (!canSave) return false;
    final prompts = _parsedPrompts();
    final textCharLimit = _parsedTextCharLimit();
    final moodTitle = _normalizeTitle(moodTitleController.text);
    final weatherTitle = _normalizeTitle(weatherTitleController.text);
    await _settings.setPrompts(prompts);
    await _settings.setPromptStrategy(_promptStrategy);
    await _settings.setTextCharLimit(textCharLimit);
    await _settings.setMoodTitle(moodTitle);
    await _settings.setWeatherTitle(weatherTitle);
    _initialPrompts = prompts;
    _initialPromptStrategy = _promptStrategy;
    _initialTextCharLimit = textCharLimit;
    _initialMoodTitle = moodTitle;
    _initialWeatherTitle = weatherTitle;
    debugPrint('[BlockSettingsVM] saved');
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    promptsController.removeListener(_notify);
    textCharLimitController.removeListener(_notify);
    moodTitleController.removeListener(_notify);
    weatherTitleController.removeListener(_notify);
    promptsController.dispose();
    textCharLimitController.dispose();
    moodTitleController.dispose();
    weatherTitleController.dispose();
    super.dispose();
  }
}
