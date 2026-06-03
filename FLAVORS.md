# Flutter Flavors Setup

This project uses **flavors** (dev/prod) to manage environment-specific configuration, primarily the RevenueCat API key.

## Architecture

- **Dev flavor**: Uses RevenueCat's test/sandbox API key
  - Local development
  - Testing on simulator/device
  - TestFlight (internal testing with test purchases)
- **Prod flavor**: Uses RevenueCat's production API key
  - App Store production builds
  - Real purchases, real analytics

## Flavor Configuration

### Dart

- [`lib/config/app_flavor.dart`](lib/config/app_flavor.dart) — reads build-time `--dart-define` flags
- [`lib/data/services/subscription_service.dart`](lib/data/services/subscription_service.dart) — uses `AppFlavor.revenueCatApiKey`

### Android

- [`android/app/build.gradle.kts`](android/app/build.gradle.kts) — defines two product flavors (dev/prod)
- Dev builds get `.dev` app ID suffix (e.g., `com.example.journaling_app_rewrite.dev`)
- Prod builds use the main app ID

### iOS

- iOS flavors are configured via build schemes (optional, see below)
- Primarily controlled via `--dart-define` flags at build time

## Build Commands

### Local Development

```bash
# Run on simulator (dev flavor, test API key)
flutter run --flavor dev \
  --dart-define=REVENUECAT_API_KEY=test_UHarMPzXLEUHFTZqqcFVHqhtKhF \
  --dart-define=FLAVOR_NAME=dev

# Run on device (dev flavor)
flutter run --flavor dev -d <device-id> \
  --dart-define=REVENUECAT_API_KEY=test_UHarMPzXLEUHFTZqqcFVHqhtKhF \
  --dart-define=FLAVOR_NAME=dev
```

### TestFlight Build (AAB for Play Store beta)

Use the **test API key** for TestFlight so testers can use test accounts (no real charges).

```bash
# Android App Bundle (for Play Store internal testing)
flutter build appbundle --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=test_UHarMPzXLEUHFTZqqcFVHqhtKhF \
  --dart-define=FLAVOR_NAME=prod
```

```bash
# iOS (for TestFlight)
flutter build ipa --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=appl_wOpAmzsemMwRCpTQqryNumDhhcq \
  --dart-define=FLAVOR_NAME=prod
```

**Output:**
- iOS: `build/ios/ipa/Runner.ipa` — upload to App Store Connect → TestFlight
- Android: `build/app/outputs/bundle/prodRelease/app-prod-release.aab` — upload to Play Console → Internal Testing

### Production Build (Real API Key)

Replace `test_…` with your **production RevenueCat API key** (`appl_…` for App Store SDK).

```bash
# iOS production
flutter build ipa --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=appl_YOUR_REAL_KEY_HERE \
  --dart-define=FLAVOR_NAME=prod
```

```bash
# Android production
flutter build appbundle --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=goog_YOUR_REAL_KEY_HERE \
  --dart-define=FLAVOR_NAME=prod
```

## Getting Your Production API Keys

1. Log into your [RevenueCat Dashboard](https://app.revenuecat.com)
2. Go to **Project Settings** → **API Keys**
3. Find:
   - **App Store SDK Key** (looks like `appl_...`)
   - **Google Play SDK Key** (looks like `goog_...`)
4. Use these in the production build commands above

## Testing Pro Features

### With Test API Key (TestFlight)

1. Use the **test API key** in your TestFlight build (shown above)
2. Create **test user accounts** in RevenueCat Dashboard:
   - Go to **Customers** → **+ Add Customer**
   - Create test user accounts with email addresses
3. Give testers the login credentials
4. Testers log in → RevenueCat grants them test entitlements → they see pro features without being charged

### With Production API Key (App Store / Play Store)

1. Production key processes **real purchases**
2. Use **Sandbox Testing** (Apple/Google testing credentials) for internal testing
3. OR use RevenueCat's test users with production key (customers created in the Dashboard are always free to test)

## Flavor-Aware Code

Access the current flavor in Dart:

```dart
import 'package:journaling_app_rewrite/config/app_flavor.dart';

// Check current flavor
if (AppFlavor.isProd) {
  // Production-only logic
}

// Get current API key
final key = AppFlavor.revenueCatApiKey;

// Get flavor name
final flavorName = AppFlavor.flavorName; // "dev" or "prod"
```

## Xcode Scheme Setup (Optional)

If you want to switch flavors directly in Xcode instead of the CLI, you can create schemes:

1. Open `ios/Runner.xcworkspace` in Xcode
2. **Product** → **Scheme** → **Edit Scheme**
3. Create two schemes: `Runner-dev` and `Runner-prod`
4. For each scheme, set:
   - **Build** → **Pre-actions** → Add a script that passes `--dart-define` flags
   - Or manually pass the flags when running `flutter run --scheme Runner-prod --flavor prod`

**Simpler approach:** Just use the CLI commands above with `--flavor` and `--dart-define`.

## Troubleshooting

### "which API key am I using?"

Check the app logs on startup:

```
[SubscriptionService] Configuring RevenueCat with key: test_... (dev)
// or
[SubscriptionService] Configuring RevenueCat with key: appl_... (prod)
```

### Android: "dev flavor not found"

Make sure you ran `flutter clean` after editing `build.gradle.kts`:

```bash
flutter clean && flutter pub get
```

### iOS: "Build settings not applied"

Delete derived data and rebuild:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter clean
flutter pub get
flutter build ipa --flavor prod ...
```

## Summary

- **Dev**: Test key, test purchases, local/TestFlight testing
- **Prod**: Production key, real purchases, App Store/Play Store
- **Build via CLI** with `--flavor` and `--dart-define` flags
- **Log output** shows which key is in use
- **Create test users** in RevenueCat for internal testing with prod builds
