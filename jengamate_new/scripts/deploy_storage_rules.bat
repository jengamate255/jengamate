@echo off
REM JengaMate Firebase Storage Rules Deployment Script
REM This script deploys the updated Firebase Storage security rules

echo 🚀 JengaMate Firebase Storage Rules Deployment
echo =================================================

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Firebase CLI not found. Installing...
    npm install -g firebase-tools
)

REM Check if user is logged in
firebase projects:list >nul 2>&1
if errorlevel 1 (
    echo ❌ Please login to Firebase first:
    echo firebase login
    pause
    exit /b 1
)

echo 📤 Deploying Firebase Storage rules...
firebase deploy --only storage

if errorlevel 1 (
    echo ❌ Deployment failed. Please check the error messages above.
    pause
    exit /b 1
)

echo ✅ Firebase Storage rules deployed successfully!
echo 🔄 The identity document upload should now work properly.
echo.
echo 📝 Note: If you're still getting authorization errors, make sure:
echo    1. The user is properly authenticated
echo    2. The Firebase project matches your app's configuration
echo    3. The storage bucket name is correct
echo.
pause
