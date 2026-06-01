import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/subscription_service.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';

/// Free-tier cap on blocks in a single `blockOnly` layout. Pro unlocks
/// unlimited blocks. (BACKLOG #92)
const int kFreeMaxBlocksPerLayout = 6;

/// Gates a Pro-only action. Returns `true` when the user already has the
/// `pro` entitlement, or completes a purchase on the presented paywall;
/// `false` when they cancel or the paywall errors.
///
/// The customer-info listener in [SubscriptionRepository] flips `isPro`
/// before the paywall returns `purchased`, so callers can proceed
/// straight away on a `true` result. This is the single gate primitive —
/// every feature gate (layout creation, block count, …) routes through
/// it so the paywall-on-tap behaviour stays consistent.
Future<bool> requirePro(SubscriptionRepository subscriptions) async {
  if (subscriptions.isPro) return true;
  final result = await RevenueCatUI.presentPaywallIfNeeded(kProEntitlementId);
  return result == PaywallResult.purchased;
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
