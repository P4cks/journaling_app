# lib/ui/core/widgets — Shared widgets

Cross-screen widgets and helpers used everywhere. See [../CLAUDE.md](../CLAUDE.md)
for how they fit together; this file is per-file notes.

## Files

- [app_dependencies.dart](app_dependencies.dart) — `AppDependencies extends InheritedWidget`.
  DI root. Constructed once in `main.dart`. `static of(context)` is
  guarded by `assert(widget != null)` so a missing ancestor fails
  loudly in dev rather than NPE-ing at first use. `updateShouldNotify`
  compares every dependency reference — bumping a repository (which
  we don't currently do at runtime) would re-trigger dependants.
  Exposes the repositories + settings objects listed in
  [../CLAUDE.md](../CLAUDE.md), including `SubscriptionRepository`
  (read by the Settings tile and the Layouts Pro gate).
- [app_icon.dart](app_icon.dart) — `AppIcon` + `HugeIconData` typedef.
  Wraps the `hugeicons` package's `HugeIcon` widget; pulls `size` and
  `color` from the surrounding `IconTheme` when unset. The free
  HugeIcons package ships only the stroke-rounded family, so there is
  no secondary / fill variant — selected and active states must be
  communicated via `color`, not by swapping the glyph. `HugeIconData`
  aliases the SVG-JSON shape (`List<List<dynamic>>`) that
  `HugeIcons.strokeRoundedXxx` constants expose so call sites type
  their parameters cleanly. The streak card now drives the flame's
  active vs. dim state via the `color` prop (dimmed via
  `withValues(alpha: 0.55)`) instead of swapping a fill glyph.
- [section_header.dart](section_header.dart) — `SectionHeader`.
  Accent-tinted titleSmall label used by Settings and the entries list.
- [settings_section.dart](settings_section.dart) — `SettingsSection`.
  Canonical grouped-settings wrapper: `label` renders through
  `SectionHeader`, and `children` are padded rows/controls followed by
  a divider. Import this file directly for settings-style groups.
- [pro_gate.dart](pro_gate.dart) — shared Pro-gating primitives.
  `Future<bool> requirePro(SubscriptionRepository, {BuildContext? context})`
  — returns `true` immediately when already Pro, else presents
  `RevenueCatUI.presentPaywallIfNeeded('pro')` and returns the
  post-paywall `subscriptions.isPro` (the customer-info listener has
  already flipped it on purchase/restore, so reading it back is the
  source of truth). The single gate primitive every feature gate routes
  through, so paywall-on-tap behaviour stays consistent. **Offline
  handling**: before presenting it calls `subscriptions.ensureOfferings()`;
  if no offering can be loaded (typically offline, so we can't sell Pro)
  it surfaces a "you're offline" SnackBar (when a `context` is passed)
  and returns `false` instead of showing a broken/empty paywall.
  `PlatformException` and `PaywallResult.error` are likewise caught and
  reported via SnackBar. **Pass `context` from every call site** so the
  user gets that feedback; without it the gate still fails closed,
  just silently.
  `ProLockBadge({compact})` — crown badge marking a locked affordance:
  `compact: true` → small filled crown dot for overlaying on an icon
  button (e.g. the editor's Add-block `+` at the block cap);
  `compact: false` → a `primaryContainer` "Pro" chip for trailing a
  list tile (e.g. the locked layout-kind picker tile).
  `ProLimitHint({used, max, noun, subscriptions})` — inline free-user
  caption for a counted cap: "`used` of `max` `noun` used" below the cap,
  a tappable "limit reached — Upgrade to Pro" row (calls `requirePro`) at
  the cap, and `SizedBox.shrink()` for Pro users (GUS-33). Surfaced in the
  block-only + custom layout editor bodies, the add-block sheet's
  custom section, and the layouts list (layouts cap, GUS-40).
  **Free-tier caps (all in this file):** `kFreeMaxBlocksPerLayout = 6`
  (blocks in a `blockOnly` layout, BACKLOG #92); `kFreeMaxSectionsCustom
  = 3` (sections in a `custom` layout, GUS-32); `kFreeMaxCustomBlocks = 1`
  (user-defined custom carousel blocks, GUS-34); `kFreeMaxLayouts = 1`
  (saved layouts, BACKLOG #90 / GUS-40); `const Set<SectionKind>
  kFreeSectionKinds = {text, blockGrid}` — section kinds free users may
  add; `featureBlock` is Pro (GUS-19), so the add-section sheet greys +
  badges it. (Built-in block gating is keyed off `BlockType.isProOnly` /
  `kProOnlyBlockTypes` in
  [../../blocks/block_type_display.dart](../../blocks/block_type_display.dart).)
- [settings_nav_tile.dart](settings_nav_tile.dart) — `SettingsNavTile`.
  Icon + title + caret-right `ListTile` that pushes a named `route`
  via `context.push`. Used for navigation rows inside settings
  sections that only route to another screen (e.g. Settings → Manage
  templates / Configure blocks).
- [bottom_sheet_scaffold.dart](bottom_sheet_scaffold.dart) —
  `Future<T?> showDraggableSheet<T>(context, {title, initialChildSize,
  minChildSize, maxChildSize, required slivers})`. Single helper that
  composes `showModalBottomSheet<T>(isScrollControlled: true,
  useSafeArea: true)` with a `DraggableScrollableSheet`, a 36×4
  rounded drag handle, and an optional left-aligned `titleMedium`
  header. The caller's `slivers` builder receives the inner
  `ScrollController` (which the helper wires to the wrapping
  `CustomScrollView`). Used by the three draggable sheets — calendar
  month sheet, layout picker, add-block sheet. Plain menu-style
  bottom sheets intentionally don't go through this helper.
- [streak_stat_card.dart](streak_stat_card.dart) — `StreakStatCard` +
  private nudge widget. Renders a `StreakResult` from
  [services/streak_service.dart](../../../data/services/streak_service.dart).
  Reused by the entries list and by the profile dropdown's header
  (in compact form).

## Gotchas

- **`AppDependencies.of` must run after the widget is mounted** —
  call from `didChangeDependencies`, not `initState`. The
  `InheritedWidget` lookup throws otherwise.
- **No more app-shell.** The bottom navigation is gone; the
  `AppScaffoldShell` and `NavigationGuard` files have been removed.
  Screens push directly to top-level routes from the main screen's
  top-bar buttons / profile dropdown. The layout editor still uses
  `PopScope` for its dirty-state Back-press dialog, which is
  sufficient since no tab switches happen anymore.

## When to update this file

- A new shared widget is added.
- The DI surface in `AppDependencies` changes.
