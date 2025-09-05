@echo off
echo ===============================================================================
echo 🚀 Firebase Firestore Indexes Deployment Script
echo ===============================================================================
echo.

echo 📋 Checking Firebase CLI installation...
echo.

firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found.
    echo 📦 Please install Firebase CLI first:
    echo npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

echo ✅ Firebase CLI found
echo.

cd jengamate_new

echo 🔐 Checking Firebase authentication...
echo.

firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Firebase CLI not authenticated.
    echo 🔑 Please login to Firebase:
    echo.
    firebase login --no-localhost
    echo.
)

echo 🎯 Deploying Firebase Firestore indexes...
echo.

firebase deploy --only firestore:indexes --project jengamate

if %errorlevel% equ 0 (
    echo.
    echo ✅ SUCCESS: Firebase indexes deployed successfully!
    echo.
) else (
    echo.
    echo ❌ DEPLOY FAILED
    echo.
    echo 💡 Alternative: Create index manually in Firebase Console
    echo 🌐 Copy this link to your browser:
    echo https://console.firebase.google.com/v1/r/project/jengamate/firestore/indexes?create_composite=Ckhwcm9qZWN0cy9qZW5nYW1hdGUvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3F1b3Rlcy9pbmRleGVzL18QAROJCgVyZnFJZBABGg0KCWNyZWFOZWRBdBACGgwKCF9f
    echo.
)

echo 🔍 Current firestore.indexes.json file content:
echo ===============================================================================
type firestore.indexes.json
echo ===============================================================================
echo.

echo 📋 Index Details:
echo ------------------------------------------------------------------------------
echo Collection: quotes
echo Query Scope: COLLECTION
echo Fields: rfqId (ASC) + createdAt (DESC)
echo ------------------------------------------------------------------------------
echo.

echo 💡 Timeline:
echo 📦 Index creation typically takes 5-10 minutes in Firebase
echo ✅ You'll see "Enabled" status in Firebase Console when complete
echo 🧪 Restart Flutter app to test the fix
echo.

if %errorlevel% neq 0 (
    echo ⏳ If deploy still fails, use the Firebase Console link above
    echo.
)

pause
