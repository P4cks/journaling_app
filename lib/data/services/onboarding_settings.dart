import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';

/// First-run onboarding state, persisted in the `settings` Hive box
/// (GUS-18).
///
/// A single `completed` flag gates whether the welcome-carousel tutorial
/// auto-shows on launch. It flips to `true` the first time the user
/// finishes or skips the tutorial and never resets (replaying from
/// Settings re-sets it to `true`, a harmless no-op).
///
/// One instance is constructed in `main.dart` and exposed via
/// `AppDependencies`. The main journal screen reads it to decide whether
/// to push the tutorial on first frame; the onboarding screen writes it
/// on completion.
class OnboardingSettings extends ChangeNotifier {
  OnboardingSettings(this._storage)
    : _completed = _storage.getOnboardingCompleted();

  final SettingsStorageService _storage;
  bool _completed;

  bool get completed => _completed;

  Future<void> setCompleted(bool value) async {
    if (_completed == value) return;
    _completed = value;
    debugPrint('[OnboardingSettings] completed -> $value');
    await _storage.setOnboardingCompleted(value);
    notifyListeners();
  }
}
