@echo off
REM This script launches the JengaMate Flutter web app with the necessary Firebase configuration.

flutter run -d chrome --dart-define=FIREBASE_API_KEY=AIzaSyCZku_umeY0AXt_IyG6Y898RKHfpL2rw7E --dart-define=FIREBASE_AUTH_DOMAIN=jengamate.firebaseapp.com --dart-define=FIREBASE_PROJECT_ID=jengamate --dart-define=FIREBASE_STORAGE_BUCKET=jengamate.firebasestorage.app --dart-define=FIREBASE_MESSAGING_SENDER_ID=546254001513 --dart-define=FIREBASE_APP_ID=1:546254001513:web:c9b63734564a66474899f8 --dart-define=FIREBASE_MEASUREMENT_ID=G-F1FP84T3E7
