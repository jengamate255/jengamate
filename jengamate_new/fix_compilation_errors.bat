@echo off
echo ========================================
echo FIXING FLUTTER COMPILATION ERRORS
echo ========================================
echo.
echo Step 1: Adding missing imports to database_service.dart
echo.

echo Adding imports after line 20 in database_service.dart...
powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'import ''package:jengamate/utils/logger.dart'';', 'import ''package:jengamate/utils/logger.dart'';import ''package:jengamate/models/inquiry_model.dart'';import ''package:jengamate/models/chat_message_model.dart'';import ''package:jengamate/models/payment_model.dart'';import ''package:jengamate/models/faq_model.dart'';import ''package:jengamate/models/order_status.dart'';' | Set-Content lib/services/database_service.dart"

echo.
echo Step 2: Fixing UserModel.id to UserModel.uid
echo.

echo Fixing UserModel.id issue in line 75...
powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'await _firestore.collection\(''users''\).doc\(user\.id\)\.update\(user\.toMap\(\)\);', 'await _firestore.collection(''users'').doc(user.uid).update(user.toMap());' | Set-Content lib/services/database_service.dart"

echo.
echo Step 3: Removing duplicate PaymentModel
echo.

echo Removing duplicate PaymentModel class at the end of database_service.dart...
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; $lines = $content -split '`n'; $newContent = $lines[0..700] -join '`n'; $newContent | Set-Content lib/services/database_service.dart"

echo.
echo Step 4: Adding missing methods from integration guide
echo.

echo Please manually copy all methods from lib/services/database_service_integration_guide.dart
echo and paste them into the DatabaseService class before the closing brace.
echo.

echo Step 5: Fixing OrderModel OrderStatus usage
echo.

echo Adding OrderStatus import to order_model.dart...
powershell -Command "if (!(Get-Content lib/models/order_model.dart | Select-String 'order_status')) { Add-Content lib/models/order_model.dart 'import ''package:jengamate/models/order_status.dart'';' }"

echo Fixing OrderStatus.fromString usage in order_model.dart...
powershell -Command "(Get-Content lib/models/order_model.dart -Raw) -replace 'status: OrderStatus\.fromString\(map\[''status''] \?\? ''pending''\),', 'status: OrderStatus.values.firstWhere((e) => e.value == (map[''status''] ?? ''pending''), orElse: () => OrderStatus.pending),' | Set-Content lib/models/order_model.dart"

echo.
echo Step 6: Adding OrderStatus import to analytics_service.dart
echo.

echo Adding OrderStatus import to analytics_service.dart...
powershell -Command "if (!(Get-Content lib/services/analytics_service.dart | Select-String 'order_status')) { Add-Content lib/services/analytics_service.dart 'import ''package:jengamate/models/order_status.dart'';' }"

echo.
echo ========================================
echo MANUAL STEPS REQUIRED:
echo ========================================
echo.
echo 1. Open lib/services/database_service_integration_guide.dart
echo 2. Copy ALL methods from that file
echo 3. Paste them into DatabaseService class in database_service.dart BEFORE the closing brace
echo.
echo 4. Run: flutter clean
echo 5. Run: flutter pub get
echo 6. Run: flutter analyze
echo 7. Fix any remaining errors
echo 8. Run: flutter run
echo.
echo ========================================
echo Press any key to continue...
pause >nul