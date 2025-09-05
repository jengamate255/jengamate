@echo off
echo ========================================
echo FIXING SPECIFIC METHOD CALL ISSUES
echo ========================================
echo.

echo Step 1: Fixing login_screen.dart createAuditLog call
echo.

powershell -Command "$content = Get-Content lib/auth/login_screen.dart -Raw; $content = $content -replace 'await databaseService\.createAuditLog\(\s*actorId:\s*result\.user!\.uid,\s*actorName:\s*result\.user!\.displayName \?\? result\.user!\.email \?\? ''Unknown User'',\s*targetUserId:\s*result\.user!\.uid,\s*targetUserName:\s*result\.user!\.displayName \?\? result\.user!\.email \?\? ''Unknown User'',\s*action:\s*''login'',\s*details:\s*\{\s*''message'':\s*''User logged into the system'',\s*''email'':\s*result\.user!\.email,\s*''timestamp'':\s*DateTime\.now\(\)\.toIso8601String\(\),\s*\},\s*\);', 'final auditLog = AuditLogModel(id: '''', actorId: result.user!.uid, actorName: result.user!.displayName ?? result.user!.email ?? ''Unknown User'', action: ''LOGIN'', targetType: ''USER'', targetId: result.user!.uid, targetName: result.user!.displayName ?? result.user!.email ?? ''Unknown User'', timestamp: DateTime.now(), details: ''User logged into the system'', metadata: {''email'': result.user!.email, ''loginMethod'': ''email''}); await databaseService.createAuditLog(auditLog);'; Set-Content lib/auth/login_screen.dart $content"

echo.
echo Step 2: Fixing commission management screen updateCommissionRules calls
echo.

powershell -Command "$content = Get-Content lib/screens/admin/commission_management_screen.dart -Raw; $content = $content -replace 'updateCommissionRules\(commissionRate: rate, minPayoutThreshold: minPayout\)', 'updateCommissionRules({''commissionRate'': rate, ''minPayoutThreshold'': minPayout})'; Set-Content lib/screens/admin/commission_management_screen.dart $content"

powershell -Command "$content = Get-Content lib/screens/admin/commission_rules_screen.dart -Raw; $content = $content -replace 'updateCommissionRules\(commissionRate: rate, minPayoutThreshold: minPayout\)', 'updateCommissionRules({''commissionRate'': rate, ''minPayoutThreshold'': minPayout})'; Set-Content lib/screens/admin/commission_rules_screen.dart $content"

powershell -Command "$content = Get-Content lib/screens/admin/commission_settings_screen.dart -Raw; $content = $content -replace 'updateCommissionRules\(commissionRate: rate, minPayoutThreshold: minPayout\)', 'updateCommissionRules({''commissionRate'': rate, ''minPayoutThreshold'': minPayout})'; Set-Content lib/screens/admin/commission_settings_screen.dart $content"

echo.
echo Step 3: Fixing send commission screen searchUsers calls
echo.

powershell -Command "$content = Get-Content lib/screens/admin/send_commission_screen.dart -Raw; $content = $content -replace 'searchUsers\(query\)', 'searchUsers(query)'; Set-Content lib/screens/admin/send_commission_screen.dart $content"

echo.
echo ========================================
echo SPECIFIC ISSUES FIXED!
echo ========================================
echo.
echo Summary of fixes:
echo - Fixed createAuditLog call in login_screen.dart
echo - Fixed updateCommissionRules calls in admin screens
echo - Fixed searchUsers calls in send_commission_screen.dart
echo.
echo Next steps:
echo 1. Run: flutter analyze
echo 2. Check remaining error count
echo 3. Fix any remaining issues
echo 4. Run: flutter run
echo.
pause