# iOS Setup Checklist (JengaMate)

Use this checklist to prepare the iOS app for development and App Store release.

## 1) Prerequisites
- Xcode latest stable installed
- CocoaPods updated: `sudo gem install cocoapods` (macOS)
- Apple Developer Program access
- Firebase project ready

## 2) Bundle Identifier and Project Settings
- In Xcode, open `ios/Runner.xcworkspace`
- Select `Runner` target → General:
  - Set Bundle Identifier: `app.jengamate.kinglion`
  - Set Display Name (optional): `JengaMate`
  - Set Version / Build (should match `pubspec.yaml`)
- Signing & Capabilities:
  - Select your Team
  - Signing Certificate: Automatically manage signing (recommended for dev)
  - Ensure a valid Provisioning Profile is generated

## 3) Firebase iOS Configuration
- In Firebase Console → iOS app → Download `GoogleService-Info.plist`
- Add to Xcode project:
  - Drag `GoogleService-Info.plist` into `Runner/` in Xcode
  - Ensure "Copy items if needed" is checked
  - Ensure the file is added to the `Runner` target
- Confirm Pods install by running in `ios/` directory:
  ```bash
  pod repo update
  pod install
  ```

## 4) Env-driven Firebase Options
- Ensure `.env` is filled with values for iOS:
  - `FIREBASE_IOS_API_KEY`
  - `FIREBASE_IOS_APP_ID`
  - `FIREBASE_IOS_BUNDLE_ID=app.jengamate.kinglion`
  - Common: `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_AUTH_DOMAIN`
- Run with the helper script (macOS Terminal / PowerShell):
  ```powershell
  pwsh ./scripts/run_with_env.ps1 -Action run -Platform ios -EnvFile .env
  ```

## 5) Crashlytics Verification (non-debug build)
- Ensure Crashlytics SDK is integrated (already wired in `lib/main.dart`)
- In Xcode, add a "Run Script" Build Phase for Crashlytics (Runner target → Build Phases):
  - Position after "Embed Pods Frameworks"
  - Script:
    ```bash
    "${PODS_ROOT}/FirebaseCrashlytics/run"
    ```
  - Ensure "Based on Dependency Analysis" is disabled to always run on archive
- Build a release or profile build and enable test crash flag:
  ```powershell
  pwsh ./scripts/run_with_env.ps1 -Action run -Platform ios -EnvFile .env -TestCrash
  ```
- After the app starts, a test crash will be triggered (once). Confirm events appear in Firebase → Crashlytics dashboard (may take a few minutes).

## 6) App Capabilities (as needed)
- Background Modes (for notifications / messaging)
- Push Notifications + APNs key in Firebase (if using FCM)
- Keychain Sharing (if required)
- Associated Domains (if using universal links)

## 7) Build Settings for Release
- Set `Build Configuration` to `Release` for App Store builds
- Increment `Version` and `Build` consistently with `pubspec.yaml`
- Archive: Product → Archive
- Distribute via the Organizer to TestFlight/App Store

## 8) Store Setup
- App Store Connect listing: name, subtitle, description, keywords, screenshots, privacy policy URL
- App Privacy: data collection and usage aligned with Firebase services
- Review Guidelines compliance

## 9) QA Checklist
- Authentication and primary flows
- Push notifications (if applicable)
- Crashlytics receiving errors
- Analytics events (if enabled)
- Performance monitoring

## Notes
- Do not commit secrets (keystores, provisioning profiles with private content, `.env`).
- Bundle ID `app.jengamate.kinglion` must match the Firebase iOS app configuration.
