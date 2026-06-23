# Play Store internal-test pipeline — one-time setup

`scripts/release.sh --play` builds a signed prod App Bundle and uploads it to
the Play Store **internal testing** track via [fastlane](https://fastlane.tools)
`supply`. This mirrors the Apple side, where pushing `release/stage` triggers
Xcode Cloud → TestFlight. The Android upload runs **locally** (there is no cloud
trigger), so the steps below run on the Mac that does releases.

```
./scripts/release.sh --minor --push --play   # bump, merge, push (→ Apple), ship Android
./scripts/release.sh --play                  # merge, then ship only Android internal
./scripts/release.sh --play --dry-run        # print the build + upload commands, do nothing
```

You only need this setup once. After it, `--play` is fully automated.

---

## 1. App Bundle signing (likely already done)

The build is signed with the upload keystore via `android/key.properties`
(see [android/app/build.gradle.kts](android/app/build.gradle.kts)). That file
and the `.jks`/`.keystore` are gitignored. If `android/key.properties` is
missing, `--play` aborts before merging. Create it with:

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

The app must already exist in the Play Console (package
`com.gusto.journal`) with this upload key registered, and the **first** AAB for
each track usually has to be promoted manually in the console once.

## 2. Google Play service account (the new piece)

fastlane authenticates to the Play Developer API with a service-account JSON.

1. **Enable the API + create the account.** Play Console → **Setup → API
   access**. Link a Google Cloud project if prompted, then **Create new service
   account** → it sends you to Google Cloud IAM. There, create a service
   account and a **JSON key** — download it.
2. **Grant permissions.** Back in Play Console → API access → the new service
   account → **Grant access**. Give it at minimum **Release to testing tracks**
   (or "Release manager") for this app. App-scoped is enough; no admin needed.
3. **Place the JSON.** Save the downloaded key as
   `android/play-service-account.json` (gitignored), **or** put it anywhere and
   point the pipeline at it:
   ```bash
   export PLAY_SERVICE_ACCOUNT_JSON=/absolute/path/to/key.json
   ```
4. **Verify** (optional, from `android/`):
   ```bash
   bundle exec fastlane run validate_play_store_json_key \
     json_key:play-service-account.json
   ```

## 3. fastlane

```bash
cd android
bundle install        # installs fastlane from android/Gemfile, writes Gemfile.lock
```

`scripts/release.sh` prefers `bundle exec fastlane` when `android/Gemfile.lock`
exists, and falls back to a `fastlane` already on `PATH` otherwise. Commit the
generated `Gemfile.lock` for reproducible runs.

---

## What `--play` does

1. Runs after the `main → release/stage` merge (and `--push`), so it ships the
   merged code. Prerequisites (flutter, `key.properties`, the service-account
   JSON, fastlane) are checked **up front** so it never merges/pushes and then
   fails with nothing shipped.
2. `flutter build appbundle --flavor prod --release --build-number=<N>` where
   `N = git rev-list --count HEAD`. Deriving the **versionCode** from the commit
   count guarantees it strictly increases on every upload — Play rejects a
   duplicate versionCode, and `release.sh` intentionally never touches the
   `+build` suffix in `pubspec.yaml`. The prod flavor uses the production
   RevenueCat `goog_` key automatically (release builds are key-aware in
   [lib/data/services/subscription_service.dart](lib/data/services/subscription_service.dart)),
   so no `--dart-define` is needed.
3. `fastlane internal` (see [android/fastlane/Fastfile](android/fastlane/Fastfile))
   uploads `build/app/outputs/bundle/prodRelease/app-prod-release.aab` to the
   **internal** track with `release_status: completed`, so it is immediately
   available to your internal testers. Store listing / screenshots / changelogs
   are left to the Play Console (the lane skips them).

## Files

- [android/fastlane/Appfile](android/fastlane/Appfile) — package name + service-account JSON path.
- [android/fastlane/Fastfile](android/fastlane/Fastfile) — the `internal` upload lane.
- [android/Gemfile](android/Gemfile) — pins fastlane for `bundle exec`.
- [scripts/release.sh](scripts/release.sh) — `--play` flag, preflight, build + upload.

## Troubleshooting

- **"service-account JSON not found"** — create it (step 2) or set
  `PLAY_SERVICE_ACCOUNT_JSON`.
- **"key.properties not found"** — set up signing (step 1).
- **"fastlane not found"** — `cd android && bundle install`.
- **API error: app not found / not enough permissions** — the service account
  needs *Release to testing tracks* for `com.gusto.journal` (step 2.2), and the
  API must be enabled (step 2.1).
- **"Version code N has already been used"** — only happens if you rewind git
  history; the commit count normally only grows. Push your commits first.
- **First upload rejected / track empty** — Play sometimes requires the very
  first release on a track to be created manually in the console; do that once,
  then `--play` works thereafter.
