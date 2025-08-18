#!/bin/bash

# JengaMate Firebase Configuration Script
# This script sets up Firebase for all platforms (iOS, Android, Web)

echo "🚀 Starting JengaMate Firebase Configuration..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "📦 Installing Firebase CLI..."
    npm install -g firebase-tools
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "📦 Installing FlutterFire CLI..."
    dart pub global activate flutterfire_cli
fi

# Login to Firebase
echo "🔐 Logging into Firebase..."
firebase login

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file..."
    cat > .env << EOL
# Firebase Configuration
FIREBASE_API_KEY=your_web_api_key_here
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
FIREBASE_MEASUREMENT_ID=your_measurement_id

# Android Configuration
ANDROID_API_KEY=your_android_api_key
ANDROID_APP_ID=your_android_app_id

# iOS Configuration
IOS_API_KEY=your_ios_api_key
IOS_APP_ID=your_ios_app_id

# Environment
ENVIRONMENT=development
EOL
    echo "✅ .env file created. Please update with your actual Firebase credentials."
fi

# Configure Firebase for all platforms
echo "📱 Configuring Firebase for all platforms..."
flutterfire configure --project=jengamate-app --yes

# Install required dependencies
echo "📦 Installing Firebase dependencies..."
flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add firebase_storage
flutter pub add firebase_analytics
flutter pub add firebase_messaging
flutter pub add firebase_crashlytics

# Create platform-specific configuration files
echo "🔧 Creating platform configuration files..."

# Create Android configuration
mkdir -p android/app/src/main/res/values
cat > android/app/src/main/res/values/strings.xml << EOL
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_web_client_id">your_web_client_id</string>
</resources>
EOL

# Create iOS configuration
echo "🍎 Setting up iOS configuration..."
if [ -d "ios" ]; then
    cd ios
    pod install
    cd ..
fi

# Create Firebase configuration script for Flutter
echo "⚙️  Creating Firebase initialization script..."
cat > lib/firebase_options.dart << 'EOL'
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    measurementId: String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('ANDROID_API_KEY'),
    appId: String.fromEnvironment('ANDROID_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('IOS_API_KEY'),
    appId: String.fromEnvironment('IOS_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: 'com.jengamate.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: String.fromEnvironment('IOS_API_KEY'),
    appId: String.fromEnvironment('IOS_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosBundleId: 'com.jengamate.app',
  );
}
EOL

# Create security rules files
echo "🔒 Creating security rules..."
mkdir -p firestore_rules
cat > firestore_rules/firestore.rules << 'EOL'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products can be read by anyone, but only created/updated by authenticated users
    match /products/{productId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Orders can be read by buyer and seller
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || 
         request.auth.uid == resource.data.sellerId);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || 
         request.auth.uid == resource.data.sellerId);
    }
    
    // Categories are public
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.token.role == 'admin';
    }
    
    // Inquiries are private to participants
    match /inquiries/{inquiryId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid == resource.data.engineerId);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid == resource.data.engineerId);
    }
  }
}
EOL

# Create storage rules
cat > firestore_rules/storage.rules << 'EOL'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Product images
    match /products/{productId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Order documents
    match /orders/{orderId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
EOL

# Create deployment script
echo "🚀 Creating deployment script..."
cat > scripts/deploy.sh << 'EOL'
#!/bin/bash

# JengaMate Deployment Script

echo "🚀 Starting JengaMate deployment..."

# Build for web
echo "📱 Building for web..."
flutter build web --dart-define=ENVIRONMENT=production

# Build for Android
echo "📱 Building for Android..."
flutter build appbundle --release --dart-define=ENVIRONMENT=production

# Build for iOS
echo "📱 Building for iOS..."
flutter build ios --release --dart-define=ENVIRONMENT=production

echo "✅ Build complete! Ready for store submission."
echo "📋 Next steps:"
echo "   1. Upload Android App Bundle to Google Play Console"
echo "   2. Upload iOS build to App Store Connect"
echo "   3. Deploy web build to hosting platform"
EOL

chmod +x scripts/deploy.sh
chmod +x scripts/firebase_setup.sh

echo "✅ Firebase configuration complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Update .env file with your actual Firebase credentials"
echo "2. Run: ./scripts/firebase_setup.sh"
echo "3. Configure store accounts (Apple Developer, Google Play)"
echo "4. Run: ./scripts/deploy.sh"
echo ""
echo "📚 Documentation: See DEPLOYMENT_CHECKLIST.md for detailed instructions"
