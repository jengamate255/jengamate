@echo off
REM JengaMate Firebase Setup Script for Windows
REM This script helps configure Firebase for all platforms

echo 🚀 JengaMate Firebase Setup Script
echo ===================================

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Firebase CLI not found. Installing...
    npm install -g firebase-tools
)

REM Check if FlutterFire CLI is installed
flutterfire --version >nul 2>&1
if errorlevel 1 (
    echo ❌ FlutterFire CLI not found. Installing...
    dart pub global activate flutterfire_cli
)

echo ✅ Firebase tools installed

REM Create directories if they don't exist
if not exist "android\app\src\dev" mkdir "android\app\src\dev"
if not exist "android\app\src\staging" mkdir "android\app\src\staging"
if not exist "android\app\src\prod" mkdir "android\app\src\prod"
if not exist "ios\Config" mkdir "ios\Config"
if not exist "scripts" mkdir "scripts"

echo 📝 Starting Firebase configuration...
echo.
echo ⚠️  Manual configuration required!
echo.
echo Please run the following commands manually:
echo.
echo 1. For Development:
echo    flutterfire configure --project=your-dev-project-id --out=lib/firebase_options_dev.dart --platforms=android,ios,web,macos,windows --ios-bundle-id=com.jengamate.dev --android-package-name=com.jengamate.dev
echo.
echo 2. For Staging:
echo    flutterfire configure --project=your-staging-project-id --out=lib/firebase_options_staging.dart --platforms=android,ios,web,macos,windows --ios-bundle-id=com.jengamate.staging --android-package-name=com.jengamate.staging
echo.
echo 3. For Production:
echo    flutterfire configure --project=your-prod-project-id --out=lib/firebase_options_prod.dart --platforms=android,ios,web,macos,windows --ios-bundle-id=com.jengamate.app --android-package-name=com.jengamate.app
echo.
echo 🎯 After running the above commands:
echo 1. Update .env file with actual Firebase configuration values
echo 2. Test on Android and iOS devices
echo 3. Set up proper signing certificates for production
pause
