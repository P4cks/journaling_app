# lib/ui — Presentation layer

All Flutter widgets live here. MVVM with `ChangeNotifier` view models;
no third-party state management library. Each screen owns a folder with
the same three-part shape:

```
<screen>/
├── view/         StatefulWidget screen
├── view_model/   ChangeNotifier; owns state + repository access
└── widgets/      screen-private widgets
```

## Subdirectories

- [blocks/CLAUDE.md](blocks/CLAUDE.md) — `BlockGrid`, `BlockCard`, the
  `BlockWidget` dispatcher, and one concrete-block subdir per block type
  ([text_block/](blocks/text_block/), [text_section/](blocks/text_section/),
  [header_section/](blocks/header_section/),
  [block_text_section/](blocks/block_text_section/),
  [wannado_section/](blocks/wannado_section/),
  [mood_tracker/](blocks/mood_tracker/)).
  Shared by the journal pager (main screen) and the layout editor.
- [core/CLAUDE.md](core/CLAUDE.md) — non-screen-specific widgets and
  helpers used everywhere. `AppDependencies` (DI), `AppIcon`
  (HugeIcons wrapper), `date_format` (small intl-free formatters),
  shared `StreakStatCard` / `SectionHeader` / `SettingsSection`.
- [theme/CLAUDE.md](theme/CLAUDE.md) — `buildAppTheme()`, the
  `SurfacePalette` catalogue, color/hex helpers.
- [journal/CLAUDE.md](journal/CLAUDE.md) — Main journal screen: AppBar
  with editable title + date subtitle + entries-icon + profile dropdown,
  swipe pager between entries, sticky calendar bar at the bottom.
  Merger of the former Home + journal-entry editor.
- [journal_entries/CLAUDE.md](journal_entries/CLAUDE.md) — Sectioned
  list of all entries (plural). Route still exists at `/entries` but
  no AppBar action links to it after the stats rewire — kept around
  so the list view can be restored later without re-implementation.
- [statistics/CLAUDE.md](statistics/CLAUDE.md) — Stats dashboard
  (streak, mood distribution / over-time, weekly frequency). Pushed
  from the main screen's top-bar Statistics icon — replaces the
  former Entries push.
- [layouts/CLAUDE.md](layouts/CLAUDE.md) — Layouts CRUD: list, editor,
  icon catalogue, picker sheets. Pushed from the profile dropdown.
- [profile/CLAUDE.md](profile/CLAUDE.md) — Settings and Block-settings
  screens, plus the widgets the profile dropdown's header reuses
  (`ProfileAuthCard`). No standalone profile screen.
- [subscription/CLAUDE.md](subscription/CLAUDE.md) — `SubscriptionScreen`:
  plan status + RevenueCat paywall / Customer Center / restore. Pushed
  from the Settings "Subscription" tile.

## Conventions used across the UI

These are the patterns every screen uses. If you find yourself doing
something different, ask whether you should bring the new screen into
line (or whether the convention itself needs to change — but if so,
update this file).

### DI via `AppDependencies`

`AppDependencies` is an `InheritedWidget` ([core/widgets/app_dependencies.dart](core/widgets/app_dependencies.dart))
constructed once in `main.dart`. It exposes `JournalRepository`,
`LayoutRepository`, `DebugSettings`, `ThemeSettings` to the whole tree.
Screens grab them via `AppDependencies.of(context)` in
`didChangeDependencies` (NOT `initState` — `InheritedWidget` access
isn't safe there) and pass them into a freshly-constructed VM.

### View ↔ ViewModel wiring

Every screen state class looks like:

```dart
class _MyScreenState extends State<MyScreen> {
  MyViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {                    // guarded — runs once
      final deps = AppDependencies.of(context);
      _viewModel = MyViewModel(...);
      _viewModel!.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onChanged() { if (mounted) setState(() {}); }
}
```

Don't subscribe via `ListenableBuilder` for the VM itself — the
`setState`-on-notify approach is the established pattern and keeps the
build tree simple. `ListenableBuilder` is fine for ambient notifiers
(`DebugSettings`, `ThemeSettings`).

### Iconography

All icons go through [core/widgets/app_icon.dart](core/widgets/app_icon.dart).
Pass any `HugeIcons.strokeRoundedXxx` constant — the free
`hugeicons` package ships only the stroke-rounded family, so there is
no separate "filled" / "active" variant. Express selected / active
states via colour (typically `colorScheme.primary`) rather than
swapping the glyph. `AppIcon` inherits `size` and `color` from the
surrounding `IconTheme` when unset. Never reintroduce raw `Icons.*` or
the old `PhosphorIconsXxx.*`.

### Theming

Read colors from `Theme.of(context).colorScheme`. Use
`scheme.surfaceContainer{Low,High,Highest}` (computed by `buildAppTheme`)
rather than picking opacities by hand. For elevated cards in dimmed
dark themes, prefer a plain `Container` + explicit `BoxShadow` over
`Material(elevation: N)` — see `BlockCard` for why.

### Color values

Use `.withValues(alpha: x)`, not the deprecated `.withOpacity(x)`.
Persist user-picked colors as `#RRGGBB` hex via
[theme/color_hex.dart](theme/color_hex.dart).

## When to update this file

- A new screen directory is added under `lib/ui/`. Add a row to the
  subdirectories list and a CLAUDE.md inside it.
- One of the cross-cutting conventions above changes — bring this
  description in line.
