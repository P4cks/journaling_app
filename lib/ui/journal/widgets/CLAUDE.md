# lib/ui/journal/widgets — Main-journal-screen widgets

See [../CLAUDE.md](../CLAUDE.md) for the screen overview.

## Files

- [journal_title.dart](journal_title.dart) — `JournalTitle`. Stacks
  [EditorTitle](editor_title.dart) on top of a smaller date subtitle
  via `formatEntryDate`. When no entry exists, falls back to a
  non-editable date-only title.
- [editor_title.dart](editor_title.dart) — `EditorTitle`
  (StatefulWidget) + internal `_InlineTitleField`. Tap-to-edit inline
  title field; commits on submit / blur, cancels via Escape. The
  parent VM normalizes empty/whitespace → null (date fallback).
- [make_entry_cta.dart](make_entry_cta.dart) — `MakeEntryCta`. Centered
  icon + title + subtitle + tonal button. Used when today has no entry
  (both as a standalone empty-day body and as the pager's trailing
  today page). `onTap` is nullable — a null renders the button
  disabled.
- [no_entry_read_only.dart](no_entry_read_only.dart) — `NoEntryReadOnly`.
  Centered "No entry was made on this day." message for past days
  with no entry.
- [profile_menu_button.dart](profile_menu_button.dart) —
  `ProfileMenuButton`. `PopupMenuButton` anchored on a userCircle
  icon (filled-check variant when signed in). The button wraps in a
  `ListenableBuilder(listenable: authRepository)` so the icon and
  menu items react to sign-in / sign-out without requiring a manual
  reopen. Items, top-to-bottom:
  1. **Streak header** (always; non-clickable) — current + longest
     streak via `computeStreak`.
  2. **Signed-in header** (only when `currentUser != null`) —
     renders `displayName ?? email ?? 'Signed in'` plus a trailing
     caret. **Clickable** (`value: 'profile'`); tapping pushes
     `/profile` so the user can review their account / sign-out from
     the full card. Replaces the old "Not signed in / Auth disabled"
     placeholder header — those states are now expressed by which
     action row is shown instead.
  3. **Divider**.
  4. **Sign out** (when signed in) — opens a confirm `AlertDialog`
     ("Sign out of <name/email>?") with Cancel / Sign out; on
     confirm calls `authRepository.signOut()`. Or **Sign in** (when
     signed out *and* `isConfigured == true`) — pushes `/profile`.
     When `isConfigured == false` (Firebase init failed →
     `DisabledAuthService`), neither row renders — the dropdown is
     local-journaling-only with no dead end.
  5. **Settings**, **Layouts**, **Block settings** — push the
     corresponding routes.
  6. **Pro banner** (only when `subscriptionRepository.isPro`;
     non-clickable) — a `primaryContainer`-tinted `_ProBanner` row
     (crown icon + "Pro active" / "Journaling App Pro") pinned at the
     bottom after a divider. `isPro` is read fresh from
     `AppDependencies` each time the menu opens, so a purchase made
     elsewhere shows up on next open. Absent entirely for free users.
  Both `onOpened` and `onSelected` call
  `FocusManager.instance.primaryFocus?.unfocus()` so navigating to
  one of the items (which pushes a new route) doesn't leave focus
  parked on a block — and `onSelected` also unfocuses *again* after
  the `await context.push(...)` returns, because Flutter's automatic
  focus restoration would otherwise re-show the keyboard when the
  previously-focused TextField becomes visible again on pop. The
  Statistics action does the same dance in its `onPressed`. The
  Change-layout action only unfocuses on open because it opens a
  sheet (no route push, no auto-restoration risk).
- [calendar_bottom_bar.dart](calendar_bottom_bar.dart) —
  `CalendarBottomBar`. Sticky compact week strip via `TableCalendar`
  in `CalendarFormat.week`, plus a conditional "Today" pill (only
  shown when `selectedDate` is not today — slides in/out via
  `AnimatedSwitcher` + horizontal `SizeTransition`), and a trailing
  IconButton that opens the full-month view via
  [showDraggableSheet](../../core/widgets/bottom_sheet_scaffold.dart)
  (initial 0.6, no title). Collapses to zero height when the keyboard
  is up (`viewInsetsOf`).

  **Cell styling** is driven by `CalendarBuilders` (not
  `CalendarStyle` decorations) so each day can get its own colour:
    - Days with an entry → rounded-rect border in a per-date palette
      colour.
    - Today (no entry) → low-opacity (18%) fill of its own colour.
    - Today + has entry (not selected) → fill + border.
    - Selected day → full fill of the day's colour; text uses
      [contrastOn](../../theme/color_hex.dart) for legibility.
  Colour comes from `themeSettings.postItPalette` via
  `_dayPaletteColor(day, palette)`, seeded by `y*10000+m*100+d` so a
  given date always renders the same colour. When
  `themeSettings.postItModeEnabled` is false, every cell falls back
  to `scheme.primary` (geometry unchanged). The week strip and month
  sheet share `_buildDayCell`. Marker dots are gone — the border
  carries the "has entry" signal. The month sheet sets
  `outsideDaysVisible: false` so adjacent-month days are hidden — they
  rendered as bare greyed numbers with no entry marker, which looked
  broken when a trailing/leading day had an entry (GUS-36). The week
  strip keeps all 7 days (no outside-day concept in week format).
- [journal_pager.dart](journal_pager.dart) — `JournalPager` plus the
  private `_SectionsBody`. The swipe pager: `PageView.builder` over
  `vm.pagerDates` sorted ascending (entry dates plus a trailing
  synthetic today page when today has no entry — GUS-29). Each page
  resolves its entry via `vm.entryForDate(date)`; a null entry (the
  today page) renders `MakeEntryCta(onTap: widget.onMakeEntry)`
  instead of `_SectionsBody`. Two-way sync with `vm.selectedDate`
  — external changes animate the controller; user swipes call
  `vm.setSelectedDate`. Pass `externalLock: true` to forcibly disable
  the horizontal swipe (used by `MainJournalScreen` while a TextField
  is focused — the screen also collapses the AppBar to a single Done
  action in that state). Also accepts the double-tap edit-mode
  plumbing: `editingBlockId` (propagated down into every `BlockGrid`
  and `TextSectionWidget`), `onRequestBlockEdit(JournalBlockData)`
  for grid + feature blocks, and `onRequestTextSectionEdit(JournalBlockData)`
  for full-width text sections (separate callback so the screen can
  set `isTextSection: true` on the route push). `_SectionsBody`
  wires its own `GestureDetector(onDoubleTap)` around `TextSectionWidget`
  and `featureBlock` tiles; `BlockGrid` does the same for each grid
  tile. Both detectors are skipped while the tile is already in edit
  mode so single-taps reach the inner field without doubleTapTimeout
  latency. Each page is a `_SectionsBody` that iterates
  the entry's `sections` and renders them vertically in a single
  outer `SingleChildScrollView`:
    - `SectionKind.text` → `TextSectionWidget` (full-width, no card).
    - `SectionKind.blockGrid` → `BlockGrid(scrollable: false)` with
      the section's blocks.
  Mode is chosen by the screen's `modeFor` callback. Holds a
  `Set<String> _lockedBlockIds` populated by `onInteractionLockChanged`
  forwarded from each `BlockGrid`. When non-empty, the outer
  `PageView` swaps to `NeverScrollableScrollPhysics` so an inner
  mood/weather carousel wins the horizontal drag.

  **`SectionKind.featureBlock`** → renders the section's single block
  inside a full-width `AspectRatio(1, BlockCard(...))` (i.e. 2×2 in
  block-grid terms — same height as a 2-row block-grid section
  filled with one tile). Empty feature sections (no template) render
  nothing.

  **Empty blockGrid sections render nothing** — when a section's
  `blocks` list is empty (e.g. a kind-B layout saved with zero filled
  slots), `_SectionsBody` returns `SizedBox.shrink()` for that
  section so the entry doesn't have awkward padding around an empty
  grid. Text sections are still rendered even when their
  `TextBlockContent` is empty (the user might be about to start
  typing).

## Gotchas

- **`PageController.animateToPage` must run after the build.**
  `JournalPager.didUpdateWidget` schedules it in `addPostFrameCallback`
  so it doesn't fire during a `notifyListeners → setState` re-entrant
  build. Don't move it back into the synchronous didUpdateWidget body.
- **`PopupMenuButton` headers must use `enabled: false`** so they
  render but don't dismiss the menu on tap. The streak/auth rows are
  status-only and have no action.
- **`CalendarBottomBar` reads `MediaQuery.viewInsetsOf(context)`** to
  detect keyboard visibility — `viewInsets.bottom > 0` is the
  conventional test. Don't switch to `viewPaddingOf` (that's the
  inverse — system insets like the bottom nav-bar).
- **`TableCalendar` is keyed on the visible week/month** in both
  `_WeekStripState` and `_MonthCalendarState`. `table_calendar` 3.2.0's
  `didUpdateWidget → _updatePage → animateToPage` flow is unreliable
  when the parent pushes a new `focusedDay` that crosses a week/month
  boundary — symptoms in the wild were "dragging the journal pager
  back from May 24 to May 23 lands the strip on June 2033" and
  "tapping Today moves the journal entry but the week strip doesn't
  scroll". The fix is `key: ValueKey('week-<Sunday>')` on the week
  strip and `key: ValueKey('month-<yyyy-mm>')` on the month sheet —
  Flutter remounts the State (and rebuilds its internal
  `PageController`) whenever the user's selection crosses a
  boundary, so `initialPage` is always recomputed from the new
  `focusedDay`. Inside a week/month the Key stays stable, so taps
  and internal chevron/swipe navigation animate normally without
  remounting. `_focusedDay` is also stored as UTC midnight via
  `_WeekStripState._toUtcMidnight(...)` to match `firstDay`/
  `lastDay`, but that alone wasn't sufficient — the package
  normalises focusedDay in its own constructor regardless.
  `selectedDayPredicate` uses `isSameDay` (y/m/d only) so a UTC
  `focusedDay` still matches the user's local `widget.selectedDate`.
- **The week strip and the month sheet each keep their own focused
  day**, so paging within the strip doesn't pollute the sheet's view
  (or vice versa). The shared state is `selectedDate`, not focus.
- **`_buildDayCell` reads `themeSettings` inline (no local
  ListenableBuilder).** Palette / post-it-mode changes propagate via
  the root-level `ListenableBuilder(listenable: themeSettings)` in
  [main.dart](../../../main.dart) which rebuilds the whole
  MaterialApp. If you ever lift this widget out of that tree, add a
  local listener — otherwise palette edits won't take effect until
  the next unrelated rebuild.
- **Per-date colour is seeded by `y*10000 + m*100 + d`, not
  `day.hashCode`.** `DateTime.hashCode` mixes the time-of-day
  fields, so two `DateTime` instances for the same calendar date but
  different times would map to different colours. The cell always
  receives a normalised `DateTime` from `TableCalendar`, but be
  defensive: don't switch the seed to `hashCode`.
- **`JournalPager`'s lock-set keys are block IDs**, not a bool flag.
  If two carousels are expanded simultaneously (mood + manual weather
  on the same day), collapsing one keeps the other's lock in place.
  The block widgets release on `_collapse()` and again, defensively,
  in `dispose()` to avoid a stuck `NeverScrollableScrollPhysics`.
- **Carousel lock rebuilds are post-frame.** Expanded carousel widgets
  may release their lock from `dispose()`, which can happen while
  Flutter has the widget tree locked. `JournalPager._onLockChanged`
  mutates the lock set immediately but defers its `setState` with a
  post-frame callback; don't switch it back to synchronous `setState`.
- **Don't add `unfocus()` to `onPageChanged`.** It was tried once to
  fix "single tap doesn't raise keyboard after entry switch" but
  introduced a worse bug: if the user taps a new entry's field during
  / right after the page settles, the `unfocus()` races the user's
  `DelayedTapFocus.requestFocus` and the keyboard flashes up + back
  down. The real underlying cause was the dead-zone bug in the chrome
  (the FittedBox sized to 160 px, leaving most of the expanded card
  un-interactive). With each block widget now owning its 12 px
  padding inside its own gesture wrapper (see `blocks/CLAUDE.md`),
  taps across the full chrome reach the block's gesture — no
  page-change unfocus needed.
- **`onReorderBlockInSection` is forwarded from `MainJournalScreen`
  to `BlockGrid` for editable entries only.** The pager plumbs a
  `(sectionId, from, to)` callback that closes over the section id
  so a single `BlockGrid` can dispatch its reorder back to
  `MainJournalViewModel.reorderBlockInSection`. Past (read-only)
  entries pass `null` — long-press in `BlockGrid` is conditional on
  the callback being non-null, so past entries stay locked.

## When to update this file

- A new widget is added.
- The PopupMenuButton items change (e.g. an "Export" entry).
- The sync model between calendar and pager changes.
- A new gesture (long-press, double-tap) is wired in.
