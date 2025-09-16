@echo off
REM JengaMate Supabase Backend Setup Script
REM This script sets up the complete Supabase backend for JengaMate

echo 🚀 Setting up JengaMate Supabase Backend...

REM Check if Supabase CLI is installed
where supabase >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ Supabase CLI is not installed. Please install it first:
    echo    npm install supabase --save-dev
    echo    or visit: https://supabase.com/docs/guides/cli
    pause
    exit /b 1
)

REM Check if we're in a Supabase project
if not exist "supabase\config.toml" (
    echo ❌ Not in a Supabase project directory. Please run this from your Supabase project root.
    pause
    exit /b 1
)

echo 📦 Applying database schema...
supabase db push

echo 🔒 Applying Row Level Security policies...
supabase db push --include-all

echo 🪣 Setting up storage buckets...
REM Create storage buckets
supabase storage create payment_proofs --public=false
supabase storage create product_images --public=true
supabase storage create profile_images --public=false

REM Set up bucket policies
echo 📋 Configuring storage policies...
supabase storage update payment_proofs --file-size-limit="10MiB" --allowed-mime-types="image/jpeg,image/jpg,image/png,application/pdf"
supabase storage update product_images --file-size-limit="5MiB" --allowed-mime-types="image/jpeg,image/jpg,image/png,image/webp"
supabase storage update profile_images --file-size-limit="2MiB" --allowed-mime-types="image/jpeg,image/jpg,image/png,image/webp"

echo ⚡ Deploying Edge Functions...
REM Deploy Edge Functions
supabase functions deploy exchange-firebase-token
supabase functions deploy order-webhook

echo 🌱 Seeding initial data...
REM Apply seed data
supabase db seed

echo 🔑 Setting up authentication...
REM Configure auth settings
supabase auth update --enable-signup=true --enable-anonymous-sign-ins=false --minimum-password-length=6

echo 📊 Setting up real-time subscriptions...
REM Enable real-time for key tables
supabase db push --enable-realtime

echo ✅ Supabase backend setup completed!
echo.
echo 🎯 Next steps:
echo 1. Configure your environment variables in Supabase Dashboard
echo 2. Set up authentication providers ^(if needed^)
echo 3. Configure email templates
echo 4. Set up monitoring and alerts
echo 5. Test the Edge Functions
echo.
echo 🔗 Useful commands:
echo    supabase status              # Check project status
echo    supabase db diff             # Check database changes
echo    supabase functions logs      # View function logs
echo    supabase storage ls          # List storage buckets
echo.
echo 📚 Documentation:
echo    - Supabase Dashboard: https://supabase.com/dashboard
echo    - Edge Functions: https://supabase.com/docs/guides/functions
echo    - Database: https://supabase.com/docs/guides/database
echo.
pause
