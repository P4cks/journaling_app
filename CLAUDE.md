# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter journaling app. Each day owns a `JournalEntry` made of one or more `JournalBlockData` (text block, mood tracker, …). New days are pre-populated from a user-selected `JournalLayout` template. Persisted with Hive (`hive_ce`).

## Commands

`flutter` is not on `PATH` in this environment. Invoke it via the absolute path:

```bash
export FLUTTER=/Users/bentschuetz/Master/Personal/Projects/Coding/Flutter/flutter/bin/flutter

$FLUTTER pub get                                              # after pubspec changes
$FLUTTER pub run build_runner build --delete-conflicting-outputs  # regenerate hive_adapters.g.dart / hive_registrar.g.dart
$FLUTTER analyze
$FLUTTER run                                                  # default device
$FLUTTER test                                                 # currently no tests
```

**Run `build_runner` whenever you add/modify a class registered as an `AdapterSpec` in [lib/hive/hive_adapters.dart](lib/hive/hive_adapters.dart).** Forgetting this leaves the adapters file out of sync with the model and the app fails to compile.

## Architecture

MVVM, layered top-down:

```
lib/
├── main.dart                  Hive init → open boxes → construct services/repositories → AppDependencies → MaterialApp.router (ListenableBuilder for theme)
├── routing/                   go_router config + Routes/RouteNames constants
├── hive/                      adapter declarations + generated registrar
├── data/
│   ├── model/                 Plain Dart data classes (no annotations; adapters are generated)
│   │   └── block_content/     Typed wrappers over JournalBlockData.contentJson per BlockType
│   ├── services/              Thin Hive box wrappers (one service per box) + ChangeNotifier settings (DebugSettings, ThemeSettings)
│   └── repositories/          Domain operations over services
└── ui/
    ├── core/widgets/          AppScaffoldShell (bottom nav), AppDependencies (DI), AppIcon (Phosphor wrapper)
    ├── theme/                 SurfacePalette, buildAppTheme(), color_hex helpers
    ├── blocks/                Block widget primitives shared everywhere
    └── <screen>/
        ├── view/              StatefulWidget screen
        ├── view_model/        ChangeNotifier; owns state + repository access
        └── widgets/           Screen-specific widgets
```

### Dependency injection

`AppDependencies` is an `InheritedWidget` ([lib/ui/core/widgets/app_dependencies.dart](lib/ui/core/widgets/app_dependencies.dart)) exposing `JournalRepository`, `LayoutRepository`, `DebugSettings`, and `ThemeSettings` to the whole tree. Screens grab them in `didChangeDependencies` (NOT `initState` — InheritedWidget access isn't safe there) and pass them into a freshly-constructed ViewModel.

### View → ViewModel binding

Each screen's State holds a nullable VM, instantiates it in `didChangeDependencies` (guarded so it only happens once), and subscribes via `vm.addListener(() => setState(() {}))`. `dispose()` removes the listener and calls `vm.dispose()`.

### Routing

[lib/routing/app_router.dart](lib/routing/app_router.dart) — a single `StatefulShellRoute.indexedStack` with three branches (profile, home, entries) producing the persistent bottom nav. **Sub-routes (journal editor, layouts CRUD) live inside the relevant branch so the bottom nav stays visible.** Use `Routes.*` constants and helpers (e.g. `Routes.journalEntryFor(date)`); `RouteNames.*` for named navigation.

### Block system

`BlockType` (enum) → `BlockWidget` (dispatcher) → concrete widget per type (`TextBlockWidget`, `MoodTrackerWidget`). Each concrete widget renders differently in `BlockMode.readOnly` vs `BlockMode.editable`. Content is stored as JSON in `JournalBlockData.contentJson`; typed access via the `block_content/` wrappers.

`BlockGrid` ([lib/ui/blocks/block_grid.dart](lib/ui/blocks/block_grid.dart)) is the **only** widget that lays out blocks — used by the home preview, the fullscreen editor, AND the layout editor (WYSIWYG). 2-column `StaggeredGrid.count` of square 1×1 tiles. An optional `onReorder` callback enables insertion-based drag-and-drop with a ghost preview at the drop position.

### Theming

[lib/ui/theme/app_theme.dart](lib/ui/theme/app_theme.dart) exports `buildAppTheme({palette, brightness, secondary, accent, surfaceOverride})` — a pure function that assembles a `ThemeData` from a curated `SurfacePalette` plus optional user overrides. `surfaceContainer*` tiers are derived by `Color.lerp(surface, onSurface, …)` so blocks always read as elevated against a dimmed base. `primary` is the accent (10%), `secondary` is the secondary (30%), and `tertiary` is a harmony of the two.

[lib/ui/theme/surface_palette.dart](lib/ui/theme/surface_palette.dart) holds the const list `kSurfacePalettes` (midnight, graphite, forest, plum, slate, cocoa) — each with a seed, dark/light surface, and default secondary/accent.

[lib/data/services/theme_settings.dart](lib/data/services/theme_settings.dart) is a `ChangeNotifier` mirroring `DebugSettings`. `main.dart` wraps `MaterialApp.router` in `ListenableBuilder(listenable: themeSettings, ...)` and supplies both `theme` and `darkTheme` so `ThemeMode.system` flips live.

### Iconography

All app icons go through [lib/ui/core/widgets/app_icon.dart](lib/ui/core/widgets/app_icon.dart) — a `PhosphorIcon` wrapper that wires the **duotone secondary tone** to `colorScheme.primary` (the user's accent). Use `PhosphorIconsDuotone.xxx` for default icons and `PhosphorIconsFill.xxx` for active/selected states (e.g. bottom-nav active tab, selected mood chip). Don't reintroduce raw `Icons.*` — `flutter analyze` won't catch it, but it'll look out of place.

### Hive schema changes

Adding fields, renaming fields, or changing a field's type in a Hive-stored model breaks deserialization of existing data. **Bump the box name** in [lib/main.dart](lib/main.dart) (`journalEntries_v4`, `journalLayouts_v3`) and re-run `build_runner`. Old boxes are orphaned on disk; harmless but never read.

## Conventions

- **Logging** — data + VM layers use `debugPrint` with a `[ClassName]` prefix. Helpful for tracing repository calls and state transitions during drag/drop.
- **No third-party state management.** Pure `ChangeNotifier` + `setState` + `InheritedWidget` is the established pattern; don't introduce Provider/Riverpod/Bloc without alignment.
- **Hero animation** between home preview and fullscreen editor uses the constant tag `journalEntryHeroTag` (re-exported from `journal_entry_view.dart`). Both ends wrap the same `BlockGrid` in `Material(color: surfaceContainerLow)` so the morph looks like pure expansion.
- **Debug flags** live in `DebugSettings` (persisted via `SettingsStorageService`). Currently: `unlockAllDays` overrides both calendar future-day gating and editor read-only-for-past-days gating.
- **Color API** — use `.withValues(alpha: x)` (not the deprecated `.withOpacity(x)`); store user-picked colors as `#RRGGBB` hex strings via [lib/ui/theme/color_hex.dart](lib/ui/theme/color_hex.dart).

## Gotchas hit during development

These are subtle and worth checking before re-introducing them.

- **`setState` during build assertion** when DnD machinery is in play. The fresh `DragTarget` inserted under the user's finger fires `onMove` synchronously during the build pass. `BlockGrid._safeSetState` defers via `addPostFrameCallback` when `WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks`.
- **Closure-over-variable bug** with `DragTarget.builder`: if the local `content` variable is reassigned after the builder closure is created, the builder returns the new value (often the `DragTarget` itself), causing infinite recursion. Always capture in a `final` var before passing through a builder closure.
- **`SingleChildScrollView` sizes to its content height, not the parent's max.** If you need it to fill (e.g. for the grey surface to reach the bottom of the screen), wrap in `SizedBox.expand`. See `JournalEntryEditorScreen.body`.
- **TextField inside a square cell**: must use `expands: true, maxLines: null, minLines: null` inside a `SizedBox.expand` so it scrolls in-place rather than blowing out the cell.
- The Hive default-path setup is `await Hive.initFlutter();` followed by `Hive.registerAdapters();` — **do not also call `Hive.init('.')`**, that overrides the path with a non-writable one on iOS/macOS and `openBox` fails.
- **Material elevation on dimmed dark themes is mostly tint, not shadow.** That's why `BlockCard` uses a plain `Container` + explicit `BoxShadow` instead of `Material(elevation: N)` — disabling tint and tuning shadow alpha makes the drop shadow read on the deep base.

## Workflow with the user

The user explicitly prefers **small, phased steps**. When working on a multi-phase feature:

1. Land each phase as its own commit (and ideally its own PR) rather than batching multiple phases into one giant commit. Earlier work in this codebase merged multiple phases per PR and it made review harder.
2. After each phase: pause, summarize what changed, and let the user run/verify before continuing.
3. If a phase involves a Hive schema change, that's a natural commit boundary — don't bundle UI changes into the same commit unless they're required for the schema change to compile.
4. Plan-mode before any sizeable feature; the user has approved a roadmap-style plan with sub-phases and likes that structure.

## Progress (sessions so far)

PRs are on branches under `claude/*` in github.com/P4cks/journaling_app.

**PR #1 — calendar + nav scaffold** (merged)
- Bottom nav with three tabs (Profile, Home, Entries) via `StatefulShellRoute.indexedStack`.
- Home: `TableCalendar` (top) + journal entry preview placeholder (bottom).
- `HomeViewModel` tracks selected/focused date.

**PR #2 — layouts, block grid editor, debug toggle** (merged)
- `JournalEntryCollection` removed; entries stored directly per day with a `date` field.
- `JournalLayout` model + `LayoutRepository` + Profile → Layouts CRUD screen with star-default, swipe-to-delete, layout editor with WYSIWYG `BlockGrid` and insertion-based DnD.
- `BlockCard` + `BlockGrid` introduced; used in preview, fullscreen editor, and layout editor.
- Fullscreen editor: Hero-animated, read-only by default with pencil-toggle to edit, AppBar tints in edit mode, "Change layout" action with confirmation dialog.
- Calendar: defaults to week view, format toggle, future days disabled.
- Past-day entries are read-only (lock icon); `DebugSettings.unlockAllDays` toggle in Profile bypasses gating for both calendar and editor.
- Body uses `SizedBox.expand` so the grey surface fills the fullscreen.

**PR #3 — visual polish + customizable theming** (branch `claude/practical-edison-f6110a`)
- Default theme is now darker / dimmed with colorful highlights (60-30-10 rule). `buildAppTheme()` assembles a `ColorScheme` from a curated `SurfacePalette` plus optional user-supplied secondary/accent overrides.
- `ThemeSettings` (`ChangeNotifier`, persisted via `SettingsStorageService`) holds `themeMode`, `paletteId`, `secondaryOverride`, `accentOverride`, `debugSurfaceOverride`. `main.dart` wraps `MaterialApp.router` in `ListenableBuilder` and supplies both light + dark themes; `themeMode` defaults to `ThemeMode.system`.
- Curated palettes (`midnight`, `graphite`, `forest`, `plum`, `slate`, `cocoa`) live in [lib/ui/theme/surface_palette.dart](lib/ui/theme/surface_palette.dart).
- Profile screen gets an **Appearance** section (segmented theme-mode selector, palette grid, secondary/accent color tiles) and an extended **Debug** section (surface override + HSL free-pick for secondary/accent). All controls listen via `ListenableBuilder(listenable: theme, …)`.
- Color picker is rolled in-house ([lib/ui/profile/widgets/swatch_grid_picker.dart](lib/ui/profile/widgets/swatch_grid_picker.dart)) — 12 curated hues + HSL sliders for debug free-pick. No external color-picker dependency.
- `BlockCard` switched from `Material(elevation: 1)` to `Container` with explicit `BoxShadow` (alpha 0.55 dark / 0.18 light, 14px blur, +4 Y offset) for a soft drop shadow that reads on dimmed surfaces.
- Iconography migrated to **Phosphor duotone** via [lib/ui/core/widgets/app_icon.dart](lib/ui/core/widgets/app_icon.dart). Active/selected states use the Fill variant. `AppIcon` automatically wires the duotone secondary tone to `colorScheme.primary` (the accent) so icons express the theme.
- New dep: `phosphor_flutter: ^2.1.0`.

## Things to be aware of starting cold

- The current worktree directory mirrors the branch name (`claude/practical-edison-f6110a`).
- The `/Users/.../plans/let-s-work-on-making-shimmering-clock.md` plan file holds the latest approved phase plan; updated when new phases are designed.
- There are no automated tests. Manual smoke-test path: launch app → confirm midnight palette + dimmed dark surface + visible block shadows → tap today → see blocks render with Phosphor duotone icons → tap pencil → type → back → preview reflects edit. Then Profile → Appearance → swap palette, swap accent color, switch to Light mode and back. Then Profile → Layouts → create a layout with two blocks, set as default → pick a new day → confirm both blocks appear.
