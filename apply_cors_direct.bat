@echo off
setlocal enabledelayedexpansion

:: Try common Google Cloud SDK paths
set "GCLOUD_PATH="

if exist "C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" (
    set "GCLOUD_PATH=C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
) else if exist "C:\Users\%USERNAME%\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" (
    set "GCLOUD_PATH=C:\Users\%USERNAME%\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"
) else if exist "C:\google-cloud-sdk\bin\gcloud.cmd" (
    set "GCLOUD_PATH=C:\google-cloud-sdk\bin\gcloud.cmd"
) else (
    echo Google Cloud SDK not found in common locations.
    echo Please install it from: https://cloud.google.com/sdk/docs/install
    pause
    exit /b 1
)

echo Using Google Cloud SDK at: !GCLOUD_PATH!
echo Applying CORS configuration to gs://jengamate.firebasestorage.app...

"!GCLOUD_PATH!" storage buckets update gs://jengamate.firebasestorage.app --cors-file="cors.json"

if %errorlevel% neq 0 (
    echo Failed to apply CORS configuration.
    echo Error: %errorlevel%
) else (
    echo CORS configuration applied successfully!
)

pause
