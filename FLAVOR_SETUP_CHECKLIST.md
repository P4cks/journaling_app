# Flutter Flavors Setup Checklist

## ✅ Already Done

- [x] Created `lib/config/app_flavor.dart` — reads flavor config from dart-define
- [x] Updated `lib/data/services/subscription_service.dart` — uses `AppFlavor.revenueCatApiKey`
- [x] Set up Android flavors in `android/app/build.gradle.kts`
- [x] Created `FLAVORS.md` with complete build command reference

## 🚀 Next Steps

### 1. Verify the Flutter project still builds

```bash
cd /path/to/journaling_app_rewrite
flutter clean
flutter pub get
```

If there are any import errors, check that `lib/config/app_flavor.dart` exists.

### 2. Test dev flavor locally

```bash
flutter run --flavor dev \
  --dart-define=REVENUECAT_API_KEY=test_UHarMPzXLEUHFTZqqcFVHqhtKhF \
  --dart-define=FLAVOR_NAME=dev
```

Watch the startup logs — you should see:
```
[SubscriptionService] Configuring RevenueCat with key: test_... (dev)
```

### 3. Build TestFlight (iOS)

First, set up your iOS signing in Xcode (if not done already).

Then build with the test API key:

```bash
flutter build ipa --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=test_UHarMPzXLEUHFTZqqcFVHqhtKhF \
  --dart-define=FLAVOR_NAME=prod
```

Output: `build/ios/ipa/Runner.ipa`

Steps to upload:
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Click **TestFlight** tab
4. Click **+** to add a new build
5. Select the build you just created via Xcode (it auto-uploads if you use `open -a Transporter build/ios/ipa`)

### 4. Create test users in RevenueCat

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Click **Customers** in the sidebar
3. Click **+ Add Customer**
4. Create a few test users with emails (e.g., `tester1@example.com`)
5. Click on each → **Entitlements** → **Grant "pro"** entitlement
6. Share these credentials with your TestFlight testers
7. They log in with these test accounts → see Pro features without being charged ✨

### 5. For production (App Store / Play Store)

When you're ready to ship:

1. Get your **production API keys** from RevenueCat:
   - App Store SDK Key (looks like `appl_XXX...`)
   - Google Play SDK Key (looks like `goog_XXX...`)

2. Build with production keys:

```bash
# iOS
flutter build ipa --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=appl_YOUR_KEY_HERE \
  --dart-define=FLAVOR_NAME=prod

# Android
flutter build appbundle --flavor prod --release \
  --dart-define=REVENUECAT_API_KEY=goog_YOUR_KEY_HERE \
  --dart-define=FLAVOR_NAME=prod
```

## 📋 File Changes Summary

### New Files
- `lib/config/app_flavor.dart` — flavor config (reads --dart-define)
- `FLAVORS.md` — build commands & setup guide
- `FLAVOR_SETUP_CHECKLIST.md` — this file

### Modified Files
- `lib/data/services/subscription_service.dart` — uses AppFlavor instead of hardcoded keys
- `android/app/build.gradle.kts` — added dev/prod product flavors

### Unchanged (still works)
- `ios/` → uses --dart-define at build time; no Xcode project changes needed
- `main.dart` → no changes; just imports and uses SubscriptionService normally

## 🆘 Troubleshooting

**"Error: lib/config/app_flavor.dart not found"**
- Make sure the file was created at the right path
- Try: `ls lib/config/app_flavor.dart`

**"Android build fails after adding flavors"**
```bash
flutter clean
flutter pub get
flutter build apk --flavor dev
```

**"How do I know which key is being used?"**
- Watch the startup logs for:
  ```
  [SubscriptionService] Configuring RevenueCat with key: test_... (dev)
  ```

**TestFlight testers see "No Products" in subscription screen**
- Make sure they're logged in with a **test user account** you created in RevenueCat
- The test user must have the **"pro" entitlement granted** in the dashboard

## ✨ You're All Set!

- Dev flavor: test key, local & TestFlight testing
- Prod flavor: real key, App Store/Play Store production
- Build commands in `FLAVORS.md` for every scenario
- Testers can now test pro features without being charged
