@echo off
echo 🚀 Deploying Firebase Functions for Supabase Integration
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found. Installing...
    npm install -g firebase-tools
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔐 Please login to Firebase:
    firebase login
)

REM Check if functions are initialized
if not exist "functions" (
    echo 📁 Initializing Firebase Functions...
    firebase init functions
)

REM Install dependencies
echo 📦 Installing dependencies...
cd functions
npm install
cd ..

REM Deploy functions
echo 🚀 Deploying functions...
firebase deploy --only functions

echo.
echo ✅ Firebase Functions deployed successfully!
echo.
echo 📋 Next steps:
echo 1. Go to Supabase Dashboard → Settings → Authentication → Third-Party Auth
echo 2. Add Firebase Auth integration with your Firebase Project ID
echo 3. Test the integration in your Flutter app
echo.
echo 🔗 Useful links:
echo - Firebase Console: https://console.firebase.google.com
echo - Supabase Dashboard: https://supabase.com/dashboard
echo - Function logs: https://console.firebase.google.com/project/_/functions/logs

pause
