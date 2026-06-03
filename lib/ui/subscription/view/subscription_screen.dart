import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:journaling_app_rewrite/data/repositories/subscription_repository.dart';
import 'package:journaling_app_rewrite/ui/core/widgets/app_dependencies.dart';

/// Subscription hub reached from Settings → Subscription. Shows the current
/// plan and routes purchases through the RevenueCat paywall + Customer Center.
/// State comes entirely from [SubscriptionRepository] (the `pro` entitlement);
/// a purchase made on the paywall flips `isPro` via the SDK's customer-info
/// listener, so this screen never tracks purchase state itself.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionRepository? _subscriptions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscriptions ??= AppDependencies.of(context).subscriptionRepository;
  }

  Future<void> _openPaywall() async {
    await RevenueCatUI.presentPaywall();
    // No manual refresh: the repository's customer-info listener updates isPro.
  }

  Future<void> _openCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  Future<void> _restore() async {
    final subs = _subscriptions!;
    await subs.restore();
    if (!mounted) return;
    final message =
        subs.errorMessage ??
        (subs.isPro
            ? 'Purchases restored — Journaling App Pro is active.'
            : 'No previous purchases found.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final subs = _subscriptions;
    if (subs == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListenableBuilder(
        listenable: subs,
        builder: (context, _) {
          final theme = Theme.of(context);
          final isPro = subs.isPro;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _StatusCard(isPro: isPro),
              const SizedBox(height: 24),
              if (isPro) ...[
                FilledButton(
                  onPressed: subs.isLoading ? null : _openCustomerCenter,
                  child: const Text('Manage subscription'),
                ),
              ] else ...[
                FilledButton(
                  onPressed: subs.isLoading ? null : _openPaywall,
                  child: const Text('Upgrade to Pro'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: subs.isLoading ? null : _restore,
                child: const Text('Restore purchases'),
              ),
              if (subs.isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (subs.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  subs.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPro ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPro ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPro ? 'Journaling App Pro' : 'Free plan',
            style: theme.textTheme.titleMedium?.copyWith(
              color: isPro ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPro
                ? 'Active — thanks for supporting the app. You have unlimited '
                      'layouts and every Pro feature.'
                : 'Upgrade to unlock unlimited layouts and more.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isPro
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
