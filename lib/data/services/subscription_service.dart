
import 'package:flutter/foundation.dart';
import 'package:journaling_app_rewrite/config/app_flavor.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement identifier for "Journaling App Pro".
///
/// The dashboard *display name* ("Journaling App Pro") is separate from this
/// *identifier*. If your RevenueCat project uses a different entitlement id,
/// change ONLY this constant — every gate reads through it.
const String kProEntitlementId = 'pro';

/// Thin wrapper over the `purchases_flutter` SDK. This is the **only** file
/// that imports `purchases_flutter`; everything else goes through
/// [SubscriptionRepository]. Keeps the SDK surface in one place so swapping
/// keys or SDK calls never leaks into the UI/data layers.
///
/// The RevenueCat API key is flavor-aware: pass `--dart-define` at build time.
/// See [AppFlavor] for details.
class SubscriptionService {
  /// Configures the SDK. Must be called exactly once, before any other
  /// `Purchases` call. Invoked from `main()` before the repository is built.
  ///
  /// The API key is determined by the current [AppFlavor]. For local development
  /// and TestFlight, use the test key. For production (App Store / Play Store),
  /// use the production key passed via `--dart-define=REVENUECAT_API_KEY=appl_...`.
  static Future<void> configure() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    final key = AppFlavor.revenueCatApiKey;
    debugPrint(
      '[SubscriptionService] Configuring RevenueCat with key: $key (${AppFlavor.flavorName})',
    );
    await Purchases.configure(PurchasesConfiguration(key));
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  Future<Offerings> getOfferings() => Purchases.getOfferings();

  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) =>
      Purchases.addCustomerInfoUpdateListener(listener);

  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) =>
      Purchases.removeCustomerInfoUpdateListener(listener);

  /// Aligns the RevenueCat app-user-id with an external account id (e.g. the
  /// Firebase uid) so entitlements follow the account across devices.
  /// Currently unused — wired in when auth↔subscription linking is enabled.
  Future<CustomerInfo> logIn(String appUserId) async =>
      (await Purchases.logIn(appUserId)).customerInfo;

  Future<CustomerInfo> logOut() => Purchases.logOut();
}
