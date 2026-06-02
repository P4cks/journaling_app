import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/subscription_service.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Free-tier cap on blocks in a single `blockOnly` layout. Pro unlocks
/// unlimited blocks. (BACKLOG #92)
const int kFreeMaxBlocksPerLayout = 6;

/// Section kinds free users may add. `featureBlock` is Pro-only, so the
/// add-section sheet greys + badges it and presents the paywall on tap.
/// (GUS-19)
const Set<SectionKind> kFreeSectionKinds = {
  SectionKind.text,
  SectionKind.blockGrid,
};

/// Gates a Pro-only action. Returns `true` when the user already has the
/// `pro` entitlement, or completes a purchase on the presented paywall;
/// `false` when they cancel, are offline, or the paywall errors.
///
/// The customer-info listener in [SubscriptionRepository] flips `isPro`
/// before the paywall returns `purchased`, so callers can proceed
/// straight away on a `true` result. This is the single gate primitive —
/// every feature gate (layout creation, block count, statistics range, …)
/// routes through it so the paywall-on-tap behaviour stays consistent.
///
/// **Offline handling.** Presenting the RevenueCat paywall needs the
/// current offering, which requires (or has cached) a network fetch. When
/// a free user taps a gated action while offline we can't sell them Pro,
/// so instead of showing a broken/empty paywall we surface a SnackBar
/// (when a [context] is supplied) explaining they need to be online, and
/// return `false`. Pass `context` from every call site so the user gets
/// that feedback; without it the gate still fails closed, just silently.
Future<bool> requirePro(
  SubscriptionRepository subscriptions, {
  BuildContext? context,
}) async {
  if (subscriptions.isPro) return true;

  // Can't present a paywall without an offering — typically means offline.
  final canPresent = await subscriptions.ensureOfferings();
  if (!canPresent) {
    if (context != null && context.mounted) {
      _showProUnavailable(
        context,
        "You're offline — connect to the internet to upgrade to Pro.",
      );
    }
    return false;
  }

  try {
    final result = await RevenueCatUI.presentPaywallIfNeeded(kProEntitlementId);
    if (result == PaywallResult.error) {
      if (context != null && context.mounted) {
        _showProUnavailable(
          context,
          "Couldn't open the upgrade screen. Please try again.",
        );
      }
      return false;
    }
    // On purchase/restore the customer-info listener has already flipped
    // `isPro`, so reading it back is the source of truth.
    return subscriptions.isPro;
  } on PlatformException catch (e) {
    debugPrint('[requirePro] paywall error: ${e.message}');
    if (context != null && context.mounted) {
      _showProUnavailable(
        context,
        "Couldn't complete that right now. Please try again.",
      );
    }
    return false;
  }
}

void _showProUnavailable(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}

/// Crown badge marking a Pro-locked affordance. Pair it with a greyed
/// control whose tap presents the paywall (via [requirePro]).
///
/// - `compact: true` → a small filled crown dot for overlaying on an
///   icon button (e.g. the layout editor's Add-block action at the cap).
/// - `compact: false` → a `primaryContainer` "Pro" chip for trailing a
///   list tile (e.g. the locked layout-kind picker tile).
class ProLockBadge extends StatelessWidget {
  const ProLockBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        child: AppIcon(
          HugeIcons.strokeRoundedCrown,
          size: 10,
          color: scheme.onPrimary,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            HugeIcons.strokeRoundedCrown,
            size: 14,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Pro',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
