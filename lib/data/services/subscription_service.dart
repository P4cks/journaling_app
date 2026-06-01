import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat entitlement identifier for "Journaling App Pro".
///
/// The dashboard *display name* ("Journaling App Pro") is separate from this
/// *identifier*. If your RevenueCat project uses a different entitlement id,
/// change ONLY this constant — every gate reads through it.
const String kProEntitlementId = 'pro';

/// RevenueCat Test Store key (the `test_` prefix). Correct for development /
/// sandbox across both platforms. For production store builds, replace the two
/// per-platform constants below with the real public SDK keys
/// (`appl_…` for App Store, `goog_…` for Google Play).
const String _revenueCatTestKey = 'test_UHarMPzXLEUHFTZqqcFVHqhtKhF';
const String _revenueCatIosKey = _revenueCatTestKey; // TODO: appl_... for prod
const String _revenueCatAndroidKey =
    _revenueCatTestKey; // TODO: goog_... for prod

/// Thin wrapper over the `purchases_flutter` SDK. This is the **only** file
/// that imports `purchases_flutter`; everything else goes through
/// [SubscriptionRepository]. Keeps the SDK surface in one place so swapping
/// keys or SDK calls never leaks into the UI/data layers.
class SubscriptionService {
  /// Configures the SDK. Must be called exactly once, before any other
  /// `Purchases` call. Invoked from `main()` before the repository is built.
  static Future<void> configure() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    final key = Platform.isAndroid ? _revenueCatAndroidKey : _revenueCatIosKey;
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
