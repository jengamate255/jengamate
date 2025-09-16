@echo off
REM Quick Fix Script Runner for JengaMate Database
REM This script applies the quick database fixes

echo ============================================
echo JengaMate Database Quick Fix
echo ============================================
echo.

echo This script will:
echo 1. Create missing enum types
echo 2. Add missing columns
echo 3. Fix RLS policies
echo 4. Create indexes
echo.

echo IMPORTANT: Make sure you have:
echo - Supabase CLI installed
echo - Logged into your Supabase account
echo - Linked to your project
echo.

echo Please copy the following SQL and run it in your Supabase SQL Editor:
echo.
echo ============================================================================
type "quick_fix.sql"
echo ============================================================================
echo.

echo After running the SQL script in Supabase:
echo 1. Test your payment submission
echo 2. Check admin dashboard
echo 3. Verify all database operations work
echo.

pause







