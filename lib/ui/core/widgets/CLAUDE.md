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
  (read by the Settings tile and the Layouts Pro gate) and
  `StreakRewardSettings` (GUS-22 — read by the Statistics reward card /
  AppBar badge and the add-block / add-section gating seams).
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
- [app_button.dart](app_button.dart) — `AppButton` + `enum AppButtonVariant
  {secondary, primary, text}` (GUS-75). The app's single button primitive —
  replaces the scattered raw `FilledButton` / `TextButton` / `OutlinedButton`
  call sites. Wraps `FilledButton` (so ripple / focus / pressed / disabled
  states come for free) with the house style: a 100%-rounded `StadiumBorder`
  pill, **no border side**, `elevation: 0`. `secondary` (the default) is the
  spec'd style — `colorScheme.secondary` fill, `onSurface` foreground; `primary`
  is `primary`/`onPrimary` for solid CTAs; `text` is a transparent-fill
  low-emphasis action (its disabled background is forced transparent so no faint
  pill shows). The prefix `icon` (and optional `trailingIcon`) are `HugeIconData`
  rendered through `AppIcon` **without an explicit colour**, so they inherit the
  button's resolved foreground (incl. disabled dimming) from `IconTheme` — i.e.
  the icon always matches the label/font colour. `backgroundColor` /
  `foregroundColor` override the variant's colours for one-offs (error-tinted
  "Delete" / "Sign out", greyed disabled-cap affordance). `expand: true` fills
  the horizontal constraints (full-width buttons in stretch columns / list
  views); `busy: true` swaps the prefix slot for a spinner and disables taps.
  The label is a plain `Text` (not `Flexible`) so it's safe inside unbounded
  rows. **Not migrated (intentional):** icon-only `IconButton`s, `InkWell` /
  `GestureDetector` tiles, and the compact calendar "Today" pill (a
  height-constrained bottom-bar control). `AddCustomBlockButton` (in
  [pro_gate.dart](pro_gate.dart)) is now an `AppButton` wrapped in a `Stack` for
  its crown-badge overlay at the free cap.
- [app_toast.dart](app_toast.dart) — `showToast(context, message,
  {kind = ToastKind.info, duration})` + `enum ToastKind {info, success,
  error}` (GUS-49). The app's single transient-notification primitive —
  replaces the scattered raw `SnackBar`s. Built on
  `ScaffoldMessenger`/`SnackBar` (so native queueing, swipe-to-dismiss
  and lifecycle still apply) but the visible body is a transparent,
  zero-elevation SnackBar wrapping `_ToastPill`: a themed rounded,
  **shadowless** (pill `Material` elevation 0, GUS-55) pill,
  right-aligned with a touch more bottom clearance than the floating
  default (SnackBar `margin` bottom 24, GUS-55), that **flies in from the
  right** via a `SlideTransition`
  (`Offset(1,0) → 0`) + fade on mount, and **flies back out to the right**
  by reversing that same animation on a `Timer` `_kToastExitDuration`
  before the messenger auto-dismisses (so the visible exit is ours, not
  the messenger's default downward slide). `kind` drives only the leading
  icon + its accent colour, all pulled from `colorScheme` (never
  hard-coded). `clearSnackBars()` runs first so toasts don't stack.
  Confirmation dialogs (Delete? / Sign out?) are intentionally **not**
  routed through this — only one-way informational messages are.
- [icon_emoji_picker.dart](icon_emoji_picker.dart) — the shared
  searchable picker (GUS-44). `Future<PickerResult?>
  showIconEmojiPicker(context, {required List<PickerIcon> icons,
  bool allowEmoji = false, String? selectedIconName, String title})`.
  Modal bottom sheet (`isScrollControlled`, `useSafeArea`): a search
  field, an optional Emoji / Icon `SegmentedButton` (shown only when
  `allowEmoji`, defaults to the Emoji tab), then a grid. Returns a
  sealed `PickerResult` — `PickerIconResult(name)` or
  `PickerEmojiResult(emoji)` — or `null` on dismiss. `PickerIcon`
  (`{name, icon, label}`) is the shared shape callers map their
  per-area icon catalogue to (`kCarouselIcons`, `kLayoutIcons`). The
  emoji grid is grouped by `EmojiCategory` (sliver headers + lazy
  `SliverGrid` over [emoji_catalogue.dart](emoji_catalogue.dart), so
  the ~1900-entry set stays performant); the icon grid is a
  `GridView.builder` with `selectedIconName` highlight. Search filters
  icons by `name`/`label` and emojis by `name`. Sheet height is
  `min(85% screen, screen − keyboard − 24)` with keyboard-inset bottom
  padding so the search field stays visible while typing. The single
  picker behind all three call sites: the custom-carousel editor
  (`allowEmoji: true`), the habit editor (icon-only), and the layout
  icon picker (icon-only, via `showLayoutIconPicker`).
- [emoji_catalogue.dart](emoji_catalogue.dart) — **GENERATED, do not
  edit by hand** (GUS-44). `enum EmojiCategory {smileys, people,
  nature, food, travel, activities, objects, symbols, flags}`,
  `class EmojiEntry(emoji, name, category)`, and `const
  kEmojiCatalogue` (~1899 base emojis). Generated from the Unicode
  `emoji-test.txt` (Emoji 17.0) by
  [tool/gen_emoji_catalogue.dart](../../../../tool/gen_emoji_catalogue.dart):
  fully-qualified entries only, **base forms only** — skin-tone and
  hair-color variants are dropped (the full permutation set would make
  the grid unusable). `emoji` is the persisted value (stored verbatim
  in `CarouselItem.value`); `name` is the CLDR short name, used for
  search. Append-only contract like the icon catalogues — saved picks
  render the raw glyph regardless, so regenerating never breaks
  history. Regenerate with `dart run tool/gen_emoji_catalogue.dart`.
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
  it surfaces a "you're offline" toast (`showToast`, when a `context` is
  passed) and returns `false` instead of showing a broken/empty paywall.
  `PlatformException` and `PaywallResult.error` are likewise caught and
  reported via toast. **Pass `context` from every call site** so the
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
  custom section, the add-section sheet's Custom (wanna-do) tab, the
  layouts list (layouts cap, GUS-40), and the Block Settings
  custom-carousel list.
  `AddCustomBlockButton({subscriptions, currentCount, onAddAllowed,
  label = 'Add custom block', max = kFreeMaxCustomBlocks})` — shared
  `OutlinedButton.icon`. Greyed + `ProLockBadge(compact:)`-overlaid at the
  `max` cap; tapping at the cap presents the paywall and only invokes
  `onAddAllowed` on a successful upgrade, below the cap it calls it
  directly. The `label` param lets other add-paths render "Add habit"
  (GUS-13) / "Add wanna-do carousel" (GUS-71); `max` lets the add-section
  Custom tab cap on `kFreeMaxWannados` instead. Used by the add-block
  sheet's custom + habit sections, the add-section sheet's wanna-do tab,
  and `block_settings_screen`'s custom-carousel + habit lists so all add
  paths gate identically against their respective free budget (carousels +
  habits counted together, GUS-40 / GUS-13).
  **Free-tier caps (all in this file):** `kFreeMaxBlocksPerLayout = 6`
  (blocks in a `blockOnly` layout, BACKLOG #92); `kFreeMaxSectionsCustom
  = 3` (sections in a `custom` layout, GUS-32); `kFreeMaxCustomBlocks = 1`
  (user-defined custom carousel blocks, GUS-34); `kFreeMaxLayouts = 1`
  (saved layouts, BACKLOG #90 / GUS-40); `const Set<SectionKind>
  kFreeSectionKinds = {text, blockGrid, header, divider}` — section
  kinds free users may add; `featureBlock` (GUS-19), `blockTextBody`
  (GUS-9), and `wannado` (GUS-8) are all Pro (NOT in the set), so the
  add-section sheet greys + badges them. `header` (GUS-6) and `divider`
  (GUS-7) are free. (Built-in block gating is keyed off `BlockType.isProOnly` /
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
  `CustomScrollView`). Used by the draggable sheets — calendar
  month sheet, layout picker, add-block sheet, add-section sheet. Plain
  menu-style bottom sheets intentionally don't go through this helper.
- [sheet_search_field.dart](sheet_search_field.dart) — two small widgets
  shared by the add-block and add-section picker sheets (GUS-71):
  `SheetSearchField({required controller, hintText = 'Search'})` — the
  rounded search `TextField` with a leading search glyph and a trailing
  clear button (shown via a `ValueListenableBuilder` on the controller
  once non-empty); and `NoMatchesHint({required message})` — the
  muted empty-state caption rendered when a search filters everything
  out. Extracted from `add_block_sheet`'s former private `_SearchField` /
  `_NoMatchesHint` so both sheets stay visually identical; `hintText` /
  `message` are the only per-sheet differences.
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
