@echo off
echo ========================================
echo MANUAL FIXES FOR REMAINING METHOD CALLS
echo ========================================
echo.

echo Step 1: Fixing commission_management_screen.dart
echo.

powershell -Command "$content = Get-Content lib/screens/admin/commission_management_screen.dart -Raw; $content = $content -replace 'await _dbService\.updateCommissionRules\(\s*commissionRate:\s*rate,\s*minPayoutThreshold:\s*minPayout,\s*\);', 'await _dbService.updateCommissionRules({''commissionRate'': rate, ''minPayoutThreshold'': minPayout});'; Set-Content lib/screens/admin/commission_management_screen.dart $content"

echo.
echo Step 2: Fixing commission_rules_screen.dart
echo.

powershell -Command "$content = Get-Content lib/screens/admin/commission_rules_screen.dart -Raw; $content = $content -replace 'await _dbService\.updateCommissionRules\(\s*commissionRate:\s*rate,\s*minPayoutThreshold:\s*minPayout,\s*\);', 'await _dbService.updateCommissionRules({''commissionRate'': rate, ''minPayoutThreshold'': minPayout});'; Set-Content lib/screens/admin/commission_rules_screen.dart $content"

echo.
echo Step 3: Fixing commission_settings_screen.dart
echo.

powershell -Command "$content = Get-Content lib/screens/admin/commission_settings_screen.dart -Raw; $content = $content -replace 'await _dbService\.updateCommissionRules\(\s*commissionRate:\s*rate,\s*minPayoutThreshold:\s*minPayout,\s*\);', 'await _dbService.updateCommissionRules({''commissionRate'': rate, ''minPayoutThreshold'': minPayout});'; Set-Content lib/screens/admin/commission_settings_screen.dart $content"

echo.
echo Step 4: Fixing send_commission_screen.dart searchUsers calls
echo.

powershell -Command "$content = Get-Content lib/screens/admin/send_commission_screen.dart -Raw; $content = $content -replace 'searchUsers\(query\)', 'searchUsers(query: query)'; Set-Content lib/screens/admin/send_commission_screen.dart $content"

echo.
echo ========================================
echo MANUAL FIXES COMPLETED!
echo ========================================
echo.
echo Summary of fixes:
echo - Fixed updateCommissionRules calls in all admin screens
echo - Fixed searchUsers calls in send_commission_screen.dart
echo.
echo Next steps:
echo 1. Run: flutter analyze
echo 2. Check remaining error count
echo 3. Fix any remaining issues
echo 4. Run: flutter run
echo.
pause