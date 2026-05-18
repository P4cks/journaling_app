# Improvements

Refactor observations that are worth preserving, but should stay separate from
small behavior-preserving cleanup commits.

## Open

- `lib/ui/profile/view/settings_screen.dart` has nested `Column` and
  `ListenableBuilder` layers around the Appearance section that could be
  extracted into an `AppearanceSettingsSection` widget. That would make the
  theme editor callbacks easier to scan without changing the settings flow.
- `lib/ui/profile/view/block_settings_screen.dart` counts custom-carousel usage
  inside a private widget by walking layouts directly. Consider moving that
  query into a view model or repository helper so the UI only renders the result
  and the usage-count logic can be tested independently.
- Several UI files are large enough to hide responsibilities
  (`layout_editor_screen.dart`, `settings_screen.dart`, `block_grid.dart`,
  `profile_auth_card.dart`). Split them only when touching their feature areas,
  so behavior stays easy to verify commit by commit.

## Resolved During Refactor

- `SettingsSection` had two identical implementations. The canonical shared
  widget now lives in `lib/ui/core/widgets/settings_section.dart`, and profile
  settings screens import that copy directly.
