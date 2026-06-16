import 'dart:io';

import 'package:flutter/foundation.dart';
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
/// The RevenueCat API key is build-mode-aware (see [_apiKey]): debug/profile
/// builds use the Test Store key, release builds (App Store / Play Store) use
/// the platform-specific production key.
class SubscriptionService {
  /// RevenueCat Test Store key — used for every non-release build so local
  /// development and CI never touch the live store.
  static const String _testApiKey = 'test_UHarMPzXLEUHFTZqqcFVHqhtKhF';

  /// Production (App Store) key — used only in release builds on iOS.
  static const String _appleApiKey = 'appl_wOpAmzsemMwRCpTQqryNumDhhcq';

  /// Production (Google Play) key — used only in release builds on Android.
  ///
  /// TODO: replace with the real RevenueCat `goog_…` key before the first Play
  /// Store release. RevenueCat rejects an `appl_` key on Android, so an Android
  /// release build will fail to configure until this is set.
  static const String _googleApiKey = "goog_PbGZmnCvYmbNVcFGOISQpzuPsVs";

  /// The key to configure with. Only release builds (what ships to the stores)
  /// get a production key; debug and profile builds use the Test Store key.
  static String get _apiKey {
    if (!kReleaseMode) return _testApiKey;
    return Platform.isIOS ? _appleApiKey : _googleApiKey;
  }

  /// Configures the SDK. Must be called exactly once, before any other
  /// `Purchases` call. Invoked from `main()` before the repository is built.
  static Future<void> configure() async {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    await Purchases.configure(PurchasesConfiguration(_apiKey));
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
