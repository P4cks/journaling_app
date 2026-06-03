# lib/ui/subscription — Subscription screen

The RevenueCat-backed monetization surface. Reached from Settings →
Subscription. Shows the user's plan and routes purchases through the
native RevenueCat paywall and Customer Center.

```
subscription/
└── view/   SubscriptionScreen
```

## Files

- [view/subscription_screen.dart](view/subscription_screen.dart) —
  `SubscriptionScreen` (`StatefulWidget`). Grabs
  `AppDependencies.of(context).subscriptionRepository` in
  `didChangeDependencies` and wraps the body in a
  `ListenableBuilder(listenable: subscriptionRepository)`. Renders a
  status card ("Journaling App Pro" vs "Free plan") and:
  - **Free:** an "Upgrade to Pro" `FilledButton` →
    `RevenueCatUI.presentPaywall()`.
  - **Pro:** a "Manage subscription" `FilledButton` →
    `RevenueCatUI.presentCustomerCenter()` (cancel / refund / plan
    change flows).
  - Always: a "Restore purchases" `TextButton` →
    `subscriptionRepository.restore()`, with a SnackBar reporting the
    result.
  - Loading spinner + `errorMessage` surfaced from the repository.

## Implementation details

- **No manual purchase-state tracking.** A purchase made on the paywall
  flips `subscriptionRepository.isPro` via the SDK's customer-info
  listener, so the `ListenableBuilder` re-renders without this screen
  refreshing anything. Don't add a `setState` after `presentPaywall()`.
- The paywall **content/design is configured in the RevenueCat
  dashboard** (Paywalls tab) against the offering — there is no
  per-screen layout code for it. `RevenueCatUI` is the only paywall API
  used; no embedded `PaywallView` widget.
- The entitlement identifier (`pro`) lives in `kProEntitlementId`
  ([../../data/services/subscription_service.dart](../../data/services/subscription_service.dart)) —
  this screen reads it only indirectly through `isPro`.

## Gotchas

- **`RevenueCatUI` calls require the SDK to be configured** (done in
  `main.dart` via `SubscriptionService.configure()` before `runApp`).
  Presenting a paywall before configure throws natively.
- **Test Store key today.** With the `test_…` key, sandbox purchases
  work without App Store / Play accounts; the same UI exercises the
  real flow once `appl_`/`goog_` keys are swapped in.

## When to update this file

- The screen gains new entry points or buttons (e.g. tier comparison,
  promo-code entry).
- The paywall presentation switches from `RevenueCatUI` modals to an
  embedded `PaywallView`.
- A second entitlement / tier is introduced (the status card and gate
  logic would need to branch).
