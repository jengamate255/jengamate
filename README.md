# Jengamate

Jengamate is a Flutter application designed to connect engineers, suppliers, and admins in the construction industry. The app provides a platform for engineers to submit inquiries, suppliers to provide quotes and manage products, and admins to oversee the entire process.

## Features

*   **Role-Based Access Control:** Separate UIs and permissions for Engineers, Suppliers, and Admins.
*   **Firebase Authentication:** Secure user authentication with email and password.
*   **Firestore Database:** Live data synchronization for inquiries, products, orders, and more.
*   **Firebase Storage:** File uploads for technical drawings and other documents.
*   **Dynamic UI:** The user interface adapts to the user's role and permissions.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
*   A Firebase project: [https://console.firebase.google.com/](https://console.firebase.google.com/)

### Installation

1.  Clone the repo
    ```sh
    git clone https://github.com/your_username_/jengamate.git
    ```
2.  Install packages
    ```sh
    flutter pub get
    ```
3.  Configure Firebase
    *   Follow the instructions to add Firebase to your Flutter app: [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)
    *   Make sure to enable Email/Password authentication in the Firebase console.
    *   Set up Firestore and Firebase Storage.
    *   IMPORTANT: We use environment variables via `--dart-define` (no secrets in source).
        - Copy `.env.example` to `.env` and fill in real values.
        - For native apps, download platform config files:
          - Android: place `google-services.json` in `android/app/`
          - iOS: add `GoogleService-Info.plist` to `ios/Runner/` and the Runner target in Xcode

### Secure Firebase configuration

This project reads all Firebase options from environment variables to avoid committing secrets.

Files and keys:

*   `lib/config/firebase_config.dart` and `lib/firebase_options.dart` map platforms to env keys:
    - Web: `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_MEASUREMENT_ID`, `FIREBASE_AUTH_DOMAIN`
    - Android: `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`
    - iOS: `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID`
    - Common: `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_STORAGE_BUCKET`

Helper script (Windows PowerShell):

```powershell
pwsh ./scripts/run_with_env.ps1 -Action run -Platform web -EnvFile .env -Device chrome
pwsh ./scripts/run_with_env.ps1 -Action run -Platform android -EnvFile .env
pwsh ./scripts/run_with_env.ps1 -Action run -Platform ios -EnvFile .env
```

Manual examples:

```bash
flutter run -d chrome \
  --dart-define-from-file=.env

flutter build apk \
  --dart-define-from-file=.env
```

### Running the App

You can run the app using the following command:

```sh
flutter run
```

To run a specific flavor, use the `--flavor` flag:

```sh
flutter run --flavor dev
flutter run --flavor prod
```

### Crashlytics & Error Reporting

Crashlytics is initialized in `lib/main.dart` and will collect errors outside of debug mode.

To verify setup, trigger a test crash in non-debug builds after confirming privacy/consent policies:

```dart
// Somewhere after app init (not committed to source in production)
// FirebaseCrashlytics.instance.crash();
```

Ensure the Google Services plugin is enabled and native config files are present:

*   `android/settings.gradle.kts` includes `com.google.gms.google-services` (apply false)
*   `android/app/build.gradle.kts` applies `com.google.gms.google-services`
*   `android/app/google-services.json` exists
*   `ios/Runner/GoogleService-Info.plist` exists

### Security Notes

*   Do not commit keystores, `key.properties`, or `.env`. `.gitignore` already excludes them.
*   If any keystore was previously committed, rotate it immediately and invalidate old artifacts.

## Project Structure

The project is structured as follows:

*   `lib/`: Contains the main application code.
    *   `auth/`: Authentication-related widgets and services.
    *   `config/`: Environment configuration.
    *   `models/`: Data models for the application.
    *   `screens/`: The different screens of the application.
    *   `services/`: Services for interacting with Firebase.
    *   `utils/`: Utility classes.
    *   `widgets/`: Reusable widgets.
*   `test/`: Contains the tests for the application.
*   `firestore.rules`: The security rules for Firestore.
