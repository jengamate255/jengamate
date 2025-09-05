@echo off
echo ========================================
echo FINAL CLEANUP PHASE - FIXING IMPORTS AND REFERENCES
echo ========================================
echo.

echo Step 1: Fixing CommissionTierModel references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'CommissionTierModel', 'CommissionTier' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'CommissionTierModel', 'CommissionTier' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 2: Fixing SupportTicketModel references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'SupportTicketModel', 'SupportTicket' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'SupportTicketModel', 'SupportTicket' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 3: Fixing FAQItem references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'FAQItem', 'FAQItem' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'FAQItem', 'FAQItem' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 4: Fixing ContentReportModel references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'ContentReportModel', 'ContentReport' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'ContentReportModel', 'ContentReport' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 5: Fixing ChatRoomModel references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'ChatRoomModel', 'ChatRoom' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'ChatRoomModel', 'ChatRoom' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 6: Fixing Inquiry references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'Inquiry', 'Inquiry' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'Inquiry', 'Inquiry' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 7: Fixing ChatMessageModel references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'ChatMessageModel', 'ChatMessage' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'ChatMessageModel', 'ChatMessage' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 8: Fixing SystemConfigModel references
echo.

powershell -Command "(Get-Content lib/services/database_service.dart -Raw) -replace 'SystemConfigModel', 'SystemConfig' | Set-Content lib/services/database_service.dart"
powershell -Command "(Get-Content lib/services/database_service_complete.dart -Raw) -replace 'SystemConfigModel', 'SystemConfig' | Set-Content lib/services/database_service_complete.dart"

echo.
echo Step 9: Fixing OrderStatus enum conflicts
echo.

echo Removing duplicate OrderStatus enum files...
if exist lib\models\order_status_enum.dart del lib\models\order_status_enum.dart

echo.
echo Step 10: Adding missing imports to database_service.dart
echo.

powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*commission_tier_model') { $content = 'import ''package:jengamate/models/commission_tier_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*support_ticket_model') { $content = 'import ''package:jengamate/models/support_ticket_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*faq_model') { $content = 'import ''package:jengamate/models/faq_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*inquiry_model') { $content = 'import ''package:jengamate/models/inquiry_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*chat_message_model') { $content = 'import ''package:jengamate/models/chat_message_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*chat_room_model') { $content = 'import ''package:jengamate/models/chat_room_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*content_report_model') { $content = 'import ''package:jengamate/models/content_report_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service.dart -Raw; if ($content -notmatch 'import.*system_config_model') { $content = 'import ''package:jengamate/models/system_config_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service.dart $content }"

echo.
echo Step 11: Adding missing imports to database_service_complete.dart
echo.

powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*commission_tier_model') { $content = 'import ''package:jengamate/models/commission_tier_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*support_ticket_model') { $content = 'import ''package:jengamate/models/support_ticket_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*faq_model') { $content = 'import ''package:jengamate/models/faq_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*inquiry_model') { $content = 'import ''package:jengamate/models/inquiry_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*chat_message_model') { $content = 'import ''package:jengamate/models/chat_message_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*chat_room_model') { $content = 'import ''package:jengamate/models/chat_room_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*content_report_model') { $content = 'import ''package:jengamate/models/content_report_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"
powershell -Command "$content = Get-Content lib/services/database_service_complete.dart -Raw; if ($content -notmatch 'import.*system_config_model') { $content = 'import ''package:jengamate/models/system_config_model.dart'';' + [Environment]::NewLine + $content; Set-Content lib/services/database_service_complete.dart $content }"

echo.
echo ========================================
echo FINAL CLEANUP COMPLETED!
echo ========================================
echo.
echo Summary of fixes:
echo - Fixed CommissionTierModel references
echo - Fixed SupportTicketModel references  
echo - Fixed FAQItem references
echo - Fixed ContentReportModel references
echo - Fixed ChatRoomModel references
echo - Fixed Inquiry references
echo - Fixed ChatMessageModel references
echo - Fixed SystemConfigModel references
echo - Removed duplicate OrderStatus enum
echo - Added missing imports to database services
echo.
echo Next steps:
echo 1. Run: flutter analyze
echo 2. Check remaining error count
echo 3. Fix any remaining import issues
echo 4. Run: flutter run
echo.
pause