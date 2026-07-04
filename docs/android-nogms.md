# Android noGms Build

This build target produces an Android APK that does not package the Firebase,
Google Play Billing, Google Play in-app review, Shorebird, or ML Kit scanner
plugins.

Disabled features:

- Firebase Cloud Messaging push notifications
- RevenueCat / Google Play purchases and restore
- Google Play in-app review prompts
- Shorebird code push checks
- Firebase/ML Kit is not used for push notifications or other Google services.
  QR camera scanning remains enabled for pairing with Bridge URLs.

Build from `apps/mobile`:

```bash
scripts/build-android-nogms.sh --release
```

The script temporarily copies `pubspec_overrides.nogms.yaml` to
`pubspec_overrides.yaml`, runs `flutter pub get`, and builds:

```bash
flutter build apk --flavor noGms --dart-define=NO_GMS=true --release
```

Normal Google Play builds use the `play` flavor:

```bash
scripts/build-android-play.sh --release
```

Notes:

- The noGms app ID is `com.k9i.ccpocket.nogms`, so it can be installed beside
  the Play build.
- `pubspec_overrides.nogms.yaml` points Google-dependent Flutter plugins to
  local Dart-only stubs under `apps/mobile/stubs/`.
- Keep `pubspec_overrides.yaml` out of commits unless intentionally changing the
  active local dependency override.
