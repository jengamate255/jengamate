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
