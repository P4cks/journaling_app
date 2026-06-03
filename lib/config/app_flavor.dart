/// App flavor configuration.
///
/// Flavors define environment-specific settings like RevenueCat API keys.
/// Values are passed at build time via --dart-define flags.
class AppFlavor {
  /// Current flavor's RevenueCat API key.
  ///
  /// Passed via: `flutter build --dart-define=REVENUECAT_API_KEY=...`
  /// Defaults to the test key if not provided (safe fallback for local dev).
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'test_UHarMPzXLEUHFTZqqcFVHqhtKhF', // test key
  );

  /// Current flavor name ('dev' or 'prod').
  ///
  /// Passed via: `flutter build --flavor prod`
  /// Defaults to 'dev' if not explicitly set.
  static const String flavorName = String.fromEnvironment(
    'FLAVOR_NAME',
    defaultValue: 'dev',
  );

  /// Whether this is a production build.
  static bool get isProd => flavorName == 'prod';

  /// Whether this is a development build.
  static bool get isDev => flavorName == 'dev';
}
