# Sentry Setup for JengaMate

Sentry has been successfully integrated into your JengaMate Flutter application for error monitoring and performance tracking.

## 🚀 What's Been Installed

- ✅ **Sentry Flutter SDK** (`sentry_flutter: ^8.9.0`)
- ✅ **Error Monitoring** - Automatic crash reporting
- ✅ **Performance Monitoring** - Transaction and performance tracking
- ✅ **Debug Tools** - Test widgets for verification
- ✅ **Dual Reporting** - Both Sentry and Firebase Crashlytics

## 📋 Setup Instructions

### 1. Get Your Sentry DSN

1. Go to [https://sentry.io/](https://sentry.io/)
2. Login to your account (or create one)
3. Navigate to your organization: `devtek-tt`
4. Go to the project: `jengamate`
5. Navigate to **Settings > Projects > jengamate > Client Keys (DSN)**
6. Copy the DSN (it looks like: `https://abc123@o123456.ingest.sentry.io/123456`)

### 2. Configure the DSN

Open `lib/config/sentry_config.dart` and replace:
```dart
static const String dsn = 'YOUR_SENTRY_DSN_HERE';
```

With your actual DSN:
```dart
static const String dsn = 'https://your-actual-dsn@sentry.io/project-id';
```

### 3. Test the Integration

1. Run your Flutter app in debug mode
2. Navigate to the Dashboard
3. Scroll down to find the "Sentry Error Monitoring Test" card
4. Use the test buttons to verify Sentry is working:
   - **Test Handled Error** - Sends a handled exception
   - **Test Unhandled Error** - Triggers an unhandled exception
   - **Send Test Message** - Sends a custom message

### 4. Verify in Sentry Dashboard

1. Go to your Sentry project dashboard
2. Check the **Issues** tab for error reports
3. Check the **Performance** tab for transaction data
4. Verify that test events are appearing

## 🔧 Configuration Options

### Environment Settings

You can configure Sentry behavior using environment variables:

```bash
# Enable/disable Sentry
flutter run --dart-define=ENABLE_SENTRY=true

# Set environment
flutter run --dart-define=SENTRY_ENVIRONMENT=production

# Set release version
flutter run --dart-define=SENTRY_RELEASE=1.0.1
```

### Production Settings

For production builds, consider adjusting these settings in `sentry_config.dart`:

```dart
// Reduce sampling rates for production
static const double tracesSampleRate = 0.1; // 10% sampling
static const double profilesSampleRate = 0.1; // 10% profiling
```

## 📊 What's Being Monitored

- ✅ **Unhandled Exceptions** - Automatic crash reporting
- ✅ **Flutter Framework Errors** - Widget and rendering errors
- ✅ **Platform Errors** - Native platform exceptions
- ✅ **Performance Transactions** - App performance metrics
- ✅ **Custom Events** - Manual error and message reporting

## 🛡️ Privacy & Security

- **PII Protection**: `sendDefaultPii` is set to `false` by default
- **Debug Mode**: Detailed logging only in debug builds
- **Dual Reporting**: Errors go to both Sentry and Firebase Crashlytics
- **Configurable**: Easy to disable or adjust sampling rates

## 🚨 Remove Test Widget

Once you've verified Sentry is working, remove the test widget by:

1. Open `lib/screens/dashboard/dashboard_tab_screen.dart`
2. Remove the Sentry test widget section (lines with `SentryTestWidget`)
3. Delete `lib/utils/sentry_test.dart` if no longer needed

## 📞 Support

If you encounter issues:
1. Check the Sentry documentation: [https://docs.sentry.io/platforms/flutter/](https://docs.sentry.io/platforms/flutter/)
2. Verify your DSN is correct
3. Check that your Sentry project has the correct permissions
4. Ensure you're on a supported Sentry plan

---

**Your JengaMate app now has professional error monitoring and performance tracking! 🎉**
