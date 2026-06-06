import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:journaling_app_rewrite/data/model/block_type.dart';
import 'package:journaling_app_rewrite/data/model/journal_layout.dart';
import 'package:journaling_app_rewrite/data/model/section_kind.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/subscription_service.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_toast.dart';

/// Free-tier cap on blocks in a single `blockOnly` layout. Pro unlocks
/// unlimited blocks. (BACKLOG #92)
const int kFreeMaxBlocksPerLayout = 6;

/// Section kinds free users may add. `featureBlock` (GUS-19) and
/// `blockTextBody` (GUS-9) are Pro-only — being absent from this set,
/// the add-section sheet greys + badges them and presents the paywall
/// on tap.
const Set<SectionKind> kFreeSectionKinds = {
  SectionKind.text,
  SectionKind.blockGrid,
  SectionKind.header,
  SectionKind.divider,
};

/// Free-tier cap on sections in a `custom` (customizable) layout. The
/// (N+1)th add presents the paywall. (GUS-32)
const int kFreeMaxSectionsCustom = 3;

/// Free-tier cap on user-defined custom carousel blocks. Creating a
/// further one presents the paywall on the "Add custom block" tap.
/// (GUS-34)
const int kFreeMaxCustomBlocks = 1;

/// Free-tier cap on saved layouts. Free users keep their one seeded
/// layout; creating a second presents the paywall. (BACKLOG #90, GUS-40)
const int kFreeMaxLayouts = 1;

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
  showToast(context, message, kind: ToastKind.error);
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

/// "Add custom block" button shared by the add-block sheet and the Block
/// Settings screen. Greyed + crown-badged at the free cap
/// ([kFreeMaxCustomBlocks]); tapping at the cap presents the paywall and
/// only invokes [onAddAllowed] on a successful upgrade. Below the cap it
/// calls [onAddAllowed] directly. Callers own the navigation. (GUS-40)
class AddCustomBlockButton extends StatelessWidget {
  const AddCustomBlockButton({
    super.key,
    required this.subscriptions,
    required this.currentCount,
    required this.onAddAllowed,
    this.label = 'Add custom block',
  });

  final SubscriptionRepository subscriptions;
  final int currentCount;
  final VoidCallback onAddAllowed;

  /// Button caption. Defaults to "Add custom block"; habit add paths
  /// pass "Add habit". The free cap ([kFreeMaxCustomBlocks]) counts
  /// carousels + habits together regardless.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atLimit =
        !subscriptions.isPro && currentCount >= kFreeMaxCustomBlocks;
    return OutlinedButton.icon(
      style: atLimit
          ? OutlinedButton.styleFrom(foregroundColor: theme.disabledColor)
          : null,
      onPressed: () async {
        if (atLimit) {
          if (!await requirePro(subscriptions, context: context)) return;
          if (!context.mounted) return;
        }
        onAddAllowed();
      },
      icon: atLimit
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedPlusSign,
                  color: theme.disabledColor,
                ),
                const Positioned(
                  top: -6,
                  right: -6,
                  child: ProLockBadge(compact: true),
                ),
              ],
            )
          : AppIcon(HugeIcons.strokeRoundedPlusSign),
      label: Text(label),
    );
  }
}

/// Inline caption telling a free user how much of a counted Pro limit
/// they've used (e.g. blocks per layout, sections, custom blocks). Below
/// the cap it reads "`used` of `max` `noun` used"; at the cap it becomes a
/// tappable "`noun` limit reached — Upgrade" row that presents the paywall
/// via [requirePro]. Renders nothing for Pro users. (GUS-33)
class ProLimitHint extends StatelessWidget {
  const ProLimitHint({
    super.key,
    required this.used,
    required this.max,
    required this.noun,
    required this.subscriptions,
  });

  final int used;
  final int max;

  /// Plural noun for the counted item, e.g. "blocks", "sections".
  final String noun;
  final SubscriptionRepository subscriptions;

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isPro) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final atLimit = used >= max;

    if (!atLimit) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          '$used of $max $noun used',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => requirePro(subscriptions, context: context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            AppIcon(
              HugeIcons.strokeRoundedCrown,
              size: 14,
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '$noun limit reached — ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  children: [
                    TextSpan(
                      text: 'Upgrade to Pro',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checks if a layout contains Pro-only features. Returns `true` if the
/// layout has any sections or blocks that require a Pro subscription.
/// Called when a user has downgraded from Pro to Free to detect layouts
/// that can no longer be edited. (GUS-41)
///
/// A layout is considered Pro-only if it contains:
/// - `featureBlock`, `blockTextBody`, or `wannado` sections
/// - Pro-only block types (`weatherApi`, `quoteBlock`)
/// - More than 1 custom carousel block
bool layoutHasProOnlyFeatures(JournalLayout layout) {
  // Check sections
  for (final section in layout.sections) {
    if (section.kind == SectionKind.featureBlock ||
        section.kind == SectionKind.blockTextBody ||
        section.kind == SectionKind.wannado) {
      return true;
    }

    // Check blocks in section
    int customCarouselCount = 0;
    for (final block in section.blocks) {
      // Check for Pro-only built-in block types
      if (block.type == BlockType.weatherApi || block.type == BlockType.quoteBlock) {
        return true;
      }

      // Count custom carousel blocks to detect > 1
      if (block.type == BlockType.customCarousel) {
        customCarouselCount++;
        if (customCarouselCount > 1) {
          return true;
        }
      }
    }
  }

  return false;
}
