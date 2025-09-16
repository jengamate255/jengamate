@echo off
echo 🔧 Firebase Custom Claims Setup Helper (Windows)
echo ================================================
echo.

REM Check if service account file is provided
if "%1"=="" (
    echo ❌ Please provide path to Firebase service account JSON file
    echo.
    echo Usage: setup_firebase_env.bat "C:\path\to\serviceAccountKey.json"
    echo.
    echo To get your service account JSON:
    echo 1. Go to Firebase Console → Project Settings → Service Accounts
    echo 2. Click 'Generate new private key'
    echo 3. Save the downloaded JSON file
    echo 4. Run: setup_firebase_env.bat "C:\path\to\serviceAccountKey.json"
    goto :error
)

set SERVICE_ACCOUNT_FILE=%1

REM Check if file exists
if not exist "%SERVICE_ACCOUNT_FILE%" (
    echo ❌ Service account JSON file not found: %SERVICE_ACCOUNT_FILE%
    goto :error
)

echo 📄 Reading Firebase service account JSON...

REM Extract values from JSON (simple parsing)
for /f "tokens=2 delims=:," %%a in ('findstr /C:"project_id" "%SERVICE_ACCOUNT_FILE%"') do (
    set PROJECT_ID=%%a
)
for /f "tokens=2 delims=:," %%a in ('findstr /C:"client_email" "%SERVICE_ACCOUNT_FILE%"') do (
    set CLIENT_EMAIL=%%a
)

REM Extract private key (more complex due to multiline)
echo 📝 Extracting private key...
setlocal enabledelayedexpansion
set PRIVATE_KEY=
set IN_KEY=0
for /f "tokens=*" %%a in ('type "%SERVICE_ACCOUNT_FILE%"') do (
    set line=%%a
    if !IN_KEY!==1 (
        if "!line!"=="-----END PRIVATE KEY-----"," (
            set PRIVATE_KEY=!PRIVATE_KEY!-----END PRIVATE KEY-----
            goto :key_done
        ) else (
            set PRIVATE_KEY=!PRIVATE_KEY!!line!
        )
    )
    if "!line!"=="  \"private_key\": \"-----BEGIN PRIVATE KEY-----\"" (
        set IN_KEY=1
        set PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
    )
)
:key_done
endlocal & set PRIVATE_KEY=%PRIVATE_KEY%

REM Clean up extracted values (remove quotes and spaces)
set PROJECT_ID=%PROJECT_ID:"=%
set CLIENT_EMAIL=%CLIENT_EMAIL:"=%
set PRIVATE_KEY=%PRIVATE_KEY:"=%

echo ✅ Credentials extracted successfully

REM Create .env file
echo 📝 Creating .env file with Firebase credentials...
(
echo # Firebase Service Account Credentials
echo FIREBASE_PROJECT_ID=%PROJECT_ID%
echo FIREBASE_PRIVATE_KEY=%PRIVATE_KEY%
echo FIREBASE_CLIENT_EMAIL=%CLIENT_EMAIL%
) > .env

REM Create batch loader
echo 📝 Creating environment loader script...
(
echo @echo off
echo REM Load Firebase environment variables
echo if exist .env (
echo   for /f "tokens=*" %%a in (.env) do (
echo     set %%a 2^>nul
echo   ^)
echo   echo ✅ Firebase environment variables loaded
echo ^) else (
echo   echo ❌ .env file not found. Run setup_firebase_env.bat first
echo ^)
) > load_firebase_env.bat

echo.
echo 🧪 Testing setup...
call load_firebase_env.bat

if "%FIREBASE_PROJECT_ID%"=="" (
    echo ❌ Environment variables not set correctly
    goto :error
)

echo ✅ Environment variables set successfully
echo.
echo 🚀 Next steps:
echo 1. Install dependencies: npm install firebase-admin
echo 2. Load environment: load_firebase_env.bat
echo 3. Set custom claims: node set_custom_claims.js
echo.
echo 📁 Files created:
echo   - .env (Firebase credentials)
echo   - load_firebase_env.bat (Environment loader)
echo.
echo ⚠️  Important: Keep .env file secure and don't commit to git!
echo.
echo Press any key to continue...
pause >nul
goto :end

:error
echo.
echo Setup failed. Please check your service account JSON file.
pause
exit /b 1

:end
