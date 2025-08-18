# JengaMate Firebase Configuration Guide

## 🚨 Critical Firebase Issues Fixed

### ✅ **Issue 1: API Keys Secured**
- **Fixed**: API keys are now read from environment variables using `String.fromEnvironment()`
- **Location**: `lib/firebase_options.dart`
- **Security**: Keys are no longer hardcoded in source code

### ✅ **Issue 2: Environment Variables Setup**
- **Created**: `.env` file for local development
- **Created**: `.env.example` template for team members
- **Updated**: `.gitignore` to exclude sensitive files

### ✅ **Issue 3: Multi-Platform Support**
- **Added**: Configuration for Android, iOS, macOS, Windows, and Web
- **Structure**: Environment variables for each platform

## 🚀 Quick Setup Steps

### **Step 1: Configure Firebase Projects**

#### **Option A: Automated Setup (Recommended)**
```bash
# Make scripts executable (Linux/Mac)
chmod +x scripts/setup_firebase.sh

# Run setup script
./scripts/setup_firebase.sh
```

#### **Option B: Manual Setup (Windows)**
```cmd
# Run Windows batch script
scripts\setup_firebase.bat
```

#### **Option C: Direct FlutterFire CLI**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure for each environment
flutterfire configure --project=your-dev-project-id --out=lib/firebase_options_dev.dart --platforms=android,ios,web,macos,windows --ios-bundle-id=com.jengamate.dev --android-package-name=com.jengamate.dev

flutterfire configure --project=your-prod-project-id --out=lib/firebase_options_prod.dart --platforms=android,ios,web,macos,windows --ios-bundle-id=com.jengamate.app --android-package-name=com.jengamate.app
```

### **Step 2: Update Environment Variables**

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Fill in your actual Firebase values** in `.env`:
   - Get values from Firebase Console → Project Settings → Your Apps
   - Update Android API keys from Firebase Console → Project Settings → Android App
   - Update iOS API keys from Firebase Console → Project Settings → iOS App

### **Step 3: Update main.dart for Environment Support**

Replace the Firebase initialization in `main.dart`:

```dart
// Before:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// After:
await Firebase.initializeApp(
  options: FirebaseConfig.getOptions(const String.fromEnvironment('FLAVOR', defaultValue: 'dev')),
);
```

### **Step 4: Run with Environment Variables**

#### **Development**:
```bash
flutter run --dart-define=FLAVOR=dev --dart-define=FIREBASE_WEB_API_KEY=your_dev_key
```

#### **Production**:
```bash
flutter run --dart-define=FLAVOR=prod --dart-define=FIREBASE_WEB_API_KEY=your_prod_key
```

## 📱 Platform-Specific Setup

### **Android Setup**
1. **Update package name** in `android/app/build.gradle`:
   ```gradle
   applicationId "com.jengamate.app"
   ```

2. **Add signing configuration**:
   ```gradle
   signingConfigs {
       release {
           storeFile file("../keystore.jks")
           storePassword System.getenv("KEYSTORE_PASSWORD")
           keyAlias "jengamate"
           keyPassword System.getenv("KEY_PASSWORD")
       }
   }
   ```

### **iOS Setup**
1. **Update bundle identifier** in `ios/Runner.xcodeproj/project.pbxproj`:
   ```
   PRODUCT_BUNDLE_IDENTIFIER = com.jengamate.app;
   ```

2. **Configure signing certificates** in Xcode

## 🔧 Environment Variable Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `FIREBASE_WEB_API_KEY` | Web platform API key | `AIzaSy...` |
| `FIREBASE_ANDROID_API_KEY` | Android platform API key | `AIzaSy...` |
| `FIREBASE_IOS_API_KEY` | iOS platform API key | `AIzaSy...` |
| `FIREBASE_PROJECT_ID` | Firebase project ID | `jengamate-prod` |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID | `123456789` |

## ✅ **Verification Checklist**

- [ ] All platform configurations generated
- [ ] Environment variables properly set
- [ ] .env file created and populated
- [ ] .gitignore updated to exclude sensitive files
- [ ] Android/iOS package names updated
- [ ] Signing certificates configured
- [ ] Firebase projects created for each environment
- [ ] Test app on Android device
- [ ] Test app on iOS device
- [ ] Verify Firebase services work correctly

## 🚨 **Security Reminders**

- **Never commit** `.env` files to version control
- **Use different Firebase projects** for dev/staging/prod
- **Rotate API keys** regularly
- **Use Firebase App Check** for additional security
- **Enable Firestore security rules**

## 📞 **Support**

If you encounter issues:
1. Check Firebase Console for correct project settings
2. Verify package names/bundle IDs match exactly
3. Ensure Google Services JSON/plist files are properly placed
4. Check environment variables are correctly loaded
