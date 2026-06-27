# lib/ui/onboarding — First-run welcome tutorial (GUS-18)

The onboarding carousel shown to new users. A self-contained
`PageView` of icon-driven slides — no coupling to live UI, so it reads
identically whether auto-shown on first launch or replayed from
Settings.

```
onboarding/
└── view/   OnboardingScreen — the welcome carousel
```

## Purpose

Introduce the app's value (daily entries, blocks, templates, streaks,
theming) the first time the app is opened, and stay replayable
afterwards. It sits at the top of the UI layer as a standalone pushed
route (`/onboarding`), not part of any other screen.

## Files

- [view/onboarding_screen.dart](view/onboarding_screen.dart) —
  `OnboardingScreen({bool firstRun = false})` (`StatefulWidget`).
  - Owns a `PageController` + current-page index over the private
    `_kSteps` list (`_OnboardingStep` = icon + title + body). Slide
    content is static and lives in this file; each slide renders a
    tinted circular `AppIcon` over a `titleLarge` headline + a
    `bodyMedium` paragraph (all colours from `colorScheme`).
  - Bottom chrome: a row of `_Dot` page indicators (active dot wider +
    `primary`), a `Skip` text `AppButton` (top-right), and a primary
    `AppButton` that reads **"Next"** (with a trailing arrow) on every
    slide except the last, where it reads **"Get started"**.
  - **Completion:** both Skip and Get started call
    `AppDependencies.of(context).onboardingSettings.setCompleted(true)`
    then `context.pop()`.
  - **`firstRun` dismissal guard:** the body is wrapped in
    `PopScope(canPop: !firstRun)`. On first launch (`firstRun == true`,
    passed via the route's `extra`) system back is blocked so the
    tutorial exits only through Skip / Get started. From Settings
    (`firstRun == false`) back works normally.

## How it's reached

- **First launch (auto):** `MainJournalScreen.didChangeDependencies`
  reads `AppDependencies.onboardingSettings.completed`; when false it
  schedules a one-shot post-frame `context.push(Routes.onboarding,
  extra: true)`. The persisted flag means this fires only once.
- **Replay:** Settings → Help → "Replay tutorial" pushes
  `Routes.onboarding` with no `extra` (so `firstRun` defaults to
  false).
- Route wiring: [../../routing/app_router.dart](../../routing/app_router.dart)
  maps `Routes.onboarding` → `OnboardingScreen(firstRun: state.extra
  as bool? ?? false)`.

## Gotchas

- **The flag never resets.** `Settings → Debug → "Reset everything"`
  does not clear `onboarding.completed`. To re-test the first-run
  auto-show, delete the app / clear app data (or temporarily call
  `onboardingSettings.setCompleted(false)`).
- **Adding/removing a slide** only means editing `_kSteps` — the dots,
  page count, and the last-slide button label all derive from its
  length. Keep icon names to verified `HugeIcons.strokeRounded*`
  constants (the free package ships only that family).

## When to update this file

- The slide set or its data shape changes materially.
- The trigger mechanism changes (e.g. moving to a router redirect).
- A new file is added under `onboarding/`.
