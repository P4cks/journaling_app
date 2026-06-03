import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:journaling_app_rewrite/data/services/settings_storage_service.dart';
import 'package:journaling_app_rewrite/data/services/subscription_service.dart';

/// Domain state for in-app subscriptions. Exposes a single [isPro] flag driven
/// by the `pro` entitlement ([kProEntitlementId]).
///
/// Entitlement state is driven by the RevenueCat SDK (which caches
/// [CustomerInfo] internally) and the [CustomerInfoUpdateListener] keeps this
/// notifier live (purchases via `RevenueCatUI.presentPaywall()` flip [isPro]
/// automatically). On top of that we persist a single **last-known Pro**
/// boolean to the settings box so that a cold start while offline — where the
/// SDK cache may be cold and the network fetch throws — still honours an
/// existing subscription (offline failsafe). Mirrors [AuthRepository]'s
/// listener pattern: subscribe in the constructor, clean up in [dispose].
class SubscriptionRepository extends ChangeNotifier {
  SubscriptionRepository(this._service, this._settings)
    : _lastKnownPro = _settings.getSubscriptionLastKnownPro(),
      _debugForceFree = _settings.getSubscriptionDebugForceFree() {
    _service.addCustomerInfoUpdateListener(_onCustomerInfo);
  }

  final SubscriptionService _service;
  final SettingsStorageService _settings;

  CustomerInfo? _customerInfo;
  Offerings? _offerings;
  bool _isLoading = false;
  String? _errorMessage;

  /// Persisted last-known entitlement state — the offline failsafe.
  bool _lastKnownPro;

  /// Debug override: when true, [isPro] reports `false` regardless of the
  /// real entitlement so developers can exercise the free experience.
  bool _debugForceFree;

  /// Live entitlement state derived from [CustomerInfo], or `null` when we
  /// have no customer info yet (e.g. a cold start that failed offline).
  bool? get _entitlementActive =>
      _customerInfo?.entitlements.active.containsKey(kProEntitlementId);

  /// Whether the user should be treated as Pro.
  ///
  /// Resolution order:
  /// 1. Debug "simulate free" override → always `false`.
  /// 2. Live entitlement from [CustomerInfo] (SDK-cached, works offline once
  ///    the SDK has cached at least once).
  /// 3. Persisted last-known Pro flag (offline failsafe when we have no
  ///    customer info at all).
  bool get isPro {
    if (_debugForceFree) return false;
    return _entitlementActive ?? _lastKnownPro;
  }

  /// Debug override state (see [setDebugForceFree]). Surfaced in the Settings
  /// → Debug section.
  bool get debugForceFree => _debugForceFree;

  /// Whether a paywall can currently be presented — i.e. we have a current
  /// offering loaded. Used by the UI gate to detect "offline / can't buy"
  /// before attempting to present the RevenueCat paywall.
  bool get hasOfferings => _offerings?.current != null;

  CustomerInfo? get customerInfo => _customerInfo;
  Offerings? get offerings => _offerings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetches initial customer info + offerings. Called once from `main()`
  /// after [SubscriptionService.configure]. Failures are swallowed (offline
  /// cold start) — [isPro] then falls back to the persisted last-known flag.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _applyCustomerInfo(await _service.getCustomerInfo());
      _offerings = await _service.getOfferings();
      debugPrint('[SubscriptionRepository] init; isPro=$isPro');
    } on PlatformException catch (e) {
      _errorMessage = e.message;
      debugPrint(
        '[SubscriptionRepository] init failed (offline?): ${e.message}; '
        'falling back to lastKnownPro=$_lastKnownPro',
      );
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
      _applyCustomerInfo(await _service.restorePurchases());
      debugPrint('[SubscriptionRepository] restore; isPro=$isPro');
    } on PlatformException catch (e) {
      _errorMessage = e.message;
      debugPrint('[SubscriptionRepository] restore failed: ${e.message}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Attempts to (re)load the current offering. Returns whether a paywall can
  /// be presented afterwards. Called by the Pro gate right before presenting
  /// the paywall so a stale-empty offering (e.g. offline at launch, online
  /// now) gets a fresh fetch, and a truly offline user is detected instead of
  /// being shown a broken paywall.
  Future<bool> ensureOfferings() async {
    if (hasOfferings) return true;
    try {
      _offerings = await _service.getOfferings();
    } on PlatformException catch (e) {
      debugPrint(
        '[SubscriptionRepository] ensureOfferings failed: ${e.message}',
      );
    }
    return hasOfferings;
  }

  /// Toggles the debug "simulate free account" override. Persisted so it
  /// survives restarts (debug builds only surface the toggle). Turning it off
  /// immediately reveals the real cached entitlement — no network needed.
  Future<void> setDebugForceFree(bool value) async {
    if (_debugForceFree == value) return;
    _debugForceFree = value;
    debugPrint('[SubscriptionRepository] debugForceFree -> $value');
    await _settings.setSubscriptionDebugForceFree(value);
    notifyListeners();
  }

  void _onCustomerInfo(CustomerInfo info) {
    _applyCustomerInfo(info);
    debugPrint('[SubscriptionRepository] customerInfo update; isPro=$isPro');
    notifyListeners();
  }

  /// Stores fresh customer info and snapshots the (real) entitlement into the
  /// persisted last-known flag. The persisted value tracks the *real*
  /// entitlement, never the debug override, so toggling the override never
  /// corrupts the offline failsafe.
  void _applyCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    final active = info.entitlements.active.containsKey(kProEntitlementId);
    if (active != _lastKnownPro) {
      _lastKnownPro = active;
      // Fire-and-forget persistence; a missed write just costs us one stale
      // offline session, which the next online sync corrects.
      _settings.setSubscriptionLastKnownPro(active);
    }
  }

  @override
  void dispose() {
    _service.removeCustomerInfoUpdateListener(_onCustomerInfo);
    super.dispose();
  }
}
