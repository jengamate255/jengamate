@echo off
echo ========================================
echo FIXING METHOD CALL SIGNATURE ISSUES
echo ========================================
echo.

echo Step 1: Fixing createAuditLog method calls
echo.

powershell -Command "(Get-Content lib/auth/login_screen.dart -Raw) -replace 'createAuditLog\(\)', 'createAuditLog(actorId: currentUser.uid, actorName: currentUser.displayName ?? ''Unknown User'', action: ''LOGIN'', targetType: ''USER'', targetId: currentUser.uid, targetName: currentUser.displayName ?? ''Unknown User'', details: ''User logged in'')' | Set-Content lib/auth/login_screen.dart"

echo.
echo Step 2: Fixing updateCommissionRules method calls
echo.

powershell -Command "(Get-Content lib/screens/admin/commission_management_screen.dart -Raw) -replace 'updateCommissionRules\(commissionRate: rate, minPayoutThreshold: minPayout\)', 'updateCommissionRules(rate, minPayout)' | Set-Content lib/screens/admin/commission_management_screen.dart"

powershell -Command "(Get-Content lib/screens/admin/commission_rules_screen.dart -Raw) -replace 'updateCommissionRules\(commissionRate: rate, minPayoutThreshold: minPayout\)', 'updateCommissionRules(rate, minPayout)' | Set-Content lib/screens/admin/commission_rules_screen.dart"

powershell -Command "(Get-Content lib/screens/admin/commission_settings_screen.dart -Raw) -replace 'updateCommissionRules\(commissionRate: rate, minPayoutThreshold: minPayout\)', 'updateCommissionRules(rate, minPayout)' | Set-Content lib/screens/admin/commission_settings_screen.dart"

echo.
echo Step 3: Fixing searchUsers method calls
echo.

powershell -Command "(Get-Content lib/screens/admin/send_commission_screen.dart -Raw) -replace 'searchUsers\(query\)', 'searchUsers(query: query)' | Set-Content lib/screens/admin/send_commission_screen.dart"

echo.
echo Step 4: Fixing OrderStatus enum conflicts
echo.

echo Removing conflicting OrderStatus definitions...
if exist lib\models\enums\order_status.dart del lib\models\enums\order_status.dart
if exist lib\models\order_status_enum.dart del lib\models\order_status_enum.dart

echo.
echo Step 5: Adding OrderStatus enum to main order_model.dart
echo.

powershell -Command "$content = Get-Content lib/models/order_model.dart -Raw; if ($content -notmatch 'enum OrderStatus') { $enumDef = 'enum OrderStatus { pending, confirmed, processing, shipped, delivered, cancelled, refunded }'; $content = $enumDef + [Environment]::NewLine + [Environment]::NewLine + $content; Set-Content lib/models/order_model.dart $content }"

echo.
echo Step 6: Fixing OrderStatus.fromString usage
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'OrderStatus.fromString', 'OrderStatus.values.firstWhere' | Set-Content lib/services/database_service.dart"

powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'OrderStatus.fromString', 'OrderStatus.values.firstWhere' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 7: Fixing UserModel.id to UserModel.uid references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace '\.id', '.uid' | Set-Content lib/services/database_service.dart"

powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace '\.id', '.uid' | Set-Content lib/services/database_service_complete.dart"

echo.
echo ========================================
echo METHOD CALL FIXES COMPLETED!
echo ========================================
echo.
echo Summary of fixes:
echo - Fixed createAuditLog method calls with proper parameters
echo - Fixed updateCommissionRules method calls with positional arguments
echo - Fixed searchUsers method calls with named parameters
echo - Removed conflicting OrderStatus enum definitions
echo - Added OrderStatus enum to order_model.dart
echo - Fixed OrderStatus.fromString usage
echo - Fixed UserModel.id to UserModel.uid references
echo.
echo Next steps:
echo 1. Run: flutter analyze
echo 2. Check remaining error count
echo 3. Fix any remaining issues
echo 4. Run: flutter run
echo.
pause