#!/bin/bash

# JengaMate Firebase Setup Script
# This script helps configure Firebase for all platforms

echo "🚀 JengaMate Firebase Setup Script"
echo "=================================="

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI not found. Installing..."
    dart pub global activate flutterfire_cli
fi

echo "✅ Firebase tools installed"

# Create directories if they don't exist
mkdir -p android/app/src/{dev,staging,prod}
mkdir -p ios/Config
mkdir -p scripts

# Function to configure Firebase for a specific environment
configure_firebase() {
    local env=$1
    local project_id=$2
    
    echo "🔧 Configuring Firebase for $env environment..."
    
    # Configure with FlutterFire CLI
    flutterfire configure \
        --project=$project_id \
        --out=lib/firebase_options_$env.dart \
        --platforms=android,ios,web,macos,windows \
        --ios-bundle-id=com.jengamate.$env \
        --android-package-name=com.jengamate.$env
    
    echo "✅ $env environment configured"
}

# Main setup process
echo "📝 Starting Firebase configuration..."

# Prompt for project IDs
echo "Enter your Firebase project IDs:"
read -p "Development project ID: " DEV_PROJECT_ID
read -p "Staging project ID: " STAGING_PROJECT_ID
read -p "Production project ID: " PROD_PROJECT_ID

# Configure each environment
configure_firebase "dev" "$DEV_PROJECT_ID"
configure_firebase "staging" "$STAGING_PROJECT_ID"
configure_firebase "prod" "$PROD_PROJECT_ID"

echo "🎯 Creating environment-specific configuration..."

# Create environment-specific config files
cat > lib/config/firebase_config.dart << 'EOF'
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_prod.dart' as prod;

class FirebaseConfig {
  static FirebaseOptions getOptions(String flavor) {
    switch (flavor) {
      case 'dev':
        return dev.DefaultFirebaseOptions.currentPlatform;
      case 'staging':
        return staging.DefaultFirebaseOptions.currentPlatform;
      case 'prod':
        return prod.DefaultFirebaseOptions.currentPlatform;
      default:
        return dev.DefaultFirebaseOptions.currentPlatform;
    }
  }
}
EOF

echo "✅ Firebase configuration completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'flutterfire configure' for each environment"
echo "2. Update .env file with actual Firebase configuration values"
echo "3. Test on Android and iOS devices"
echo "4. Set up proper signing certificates for production"
