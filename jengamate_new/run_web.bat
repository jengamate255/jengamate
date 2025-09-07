@echo off
REM This script launches the JengaMate Flutter web app with Supabase configuration.

echo Starting JengaMate Flutter Web App with Supabase...
echo Supabase URL: https://ednovyqzrbaiyzlegbmy.supabase.co
echo.

cd jengamate_new
flutter run -d chrome --target lib/main.dart --dart-define=SUPABASE_URL=https://ednovyqzrbaiyzlegbmy.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbm92eXF6cmJhaXl6bGVnYm15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUxNTQ4NzQsImV4cCI6MjA3MDczMDg3NH0.G8kfMHO5mRCpgjAQXNV2tdJ8zzTn3zF9la80n3RODu8
