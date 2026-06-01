import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:journaling_app_rewrite/data/services/subscription_service.dart';

/// Domain state for in-app subscriptions. Exposes a single [isPro] flag driven
/// by the `pro` entitlement ([kProEntitlementId]).
///
/// Entitlement state is **never persisted to Hive** — the RevenueCat SDK caches
/// it internally and the [CustomerInfoUpdateListener] keeps this notifier live
/// (purchases via `RevenueCatUI.presentPaywall()` flip [isPro] automatically).
/// Mirrors [AuthRepository]'s listener pattern: subscribe in the constructor,
/// clean up in [dispose].
class SubscriptionRepository extends ChangeNotifier {
  SubscriptionRepository(this._service) {
    _service.addCustomerInfoUpdateListener(_onCustomerInfo);
  }

  final SubscriptionService _service;

  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _isLoading = false;
  String? _errorMessage;

  /// Whether the user currently has the `pro` entitlement active.
  bool get isPro =>
      _customerInfo?.entitlements.active.containsKey(kProEntitlementId) ??
      false;

  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches initial customer info + offerings. Called once from `main()`
  /// after [SubscriptionService.configure].
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customerInfo = await _service.getCustomerInfo();
      _offerings = await _service.getOfferings();
      debugPrint('[SubscriptionRepository] init; isPro=$isPro');
    } on PlatformException catch (e) {
      _errorMessage = e.message;
      debugPrint('[SubscriptionRepository] init failed: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Restores prior purchases (e.g. after a reinstall or on a new device).
  Future<void> restore() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _customerInfo = await _service.restorePurchases();
      debugPrint('[SubscriptionRepository] restore; isPro=$isPro');
    } on PlatformException catch (e) {
      _errorMessage = e.message;
      debugPrint('[SubscriptionRepository] restore failed: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    debugPrint('[SubscriptionRepository] customerInfo update; isPro=$isPro');
    notifyListeners();
  }

  @override
  void dispose() {
    _service.removeCustomerInfoUpdateListener(_onCustomerInfo);
    super.dispose();
  }
}
