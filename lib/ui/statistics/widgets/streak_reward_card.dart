import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/data/services/streak_reward_settings.dart';
import 'package:journaling_app_rewrite/data/services/streak_service.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_icon.dart';
import 'package:journaling_app_rewrite/ui/statistics/widgets/claim_reward_sheet.dart';

/// Celebratory card shown on the Statistics screen when the user has
/// earned the 7-day streak milestone but not yet spent the reward token.
/// Renders nothing when there's no unclaimed reward.
///
/// The claim everyone earns is the **Streak block**. The "Claim your
/// reward" button then branches on Pro status:
/// - **Free users** open [showClaimRewardSheet] to additionally pick one
///   Pro block / section.
/// - **Pro users** claim directly (no picker) — they also get the Quote
///   block as downgrade insurance via [StreakRewardSettings.claimAsPro].
class StreakRewardCard extends StatelessWidget {
  const StreakRewardCard({
    super.key,
    required this.streak,
    required this.rewards,
    required this.subscriptions,
  });

  final StreakResult streak;
  final StreakRewardSettings rewards;
  final SubscriptionRepository subscriptions;

  Future<void> _claimAsPro(BuildContext context) async {
    await rewards.claimAsPro();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Streak block + Quote block unlocked!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!rewards.isRewardUnclaimed(streak)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isPro = subscriptions.isPro;
    final blurb = isPro
        ? 'Unlock the Streak block — plus a Quote block to keep, on us.'
        : 'Unlock the Streak block, plus one Pro block or section of your '
              'choice, on us.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedGift,
                  size: 28,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '7-day streak reward!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        blurb,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => isPro
                    ? _claimAsPro(context)
                    : showClaimRewardSheet(context, rewards: rewards),
                icon: const AppIcon(HugeIcons.strokeRoundedSparkles, size: 18),
                label: const Text('Claim your reward'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
