@echo off
setlocal enabledelayedexpansion
set GCLOUD_PATH=F:\Dave\google cloud cli\google-cloud-sdk\bin\gcloud.cmd
set CORS_FILE=F:\Dave\Jenga\jengamate\cors.json
set BUCKET=gs://jengamate.appspot.com

echo Applying CORS configuration to Firebase Storage...
"!GCLOUD_PATH!" storage buckets update !BUCKET! --cors-file="!CORS_FILE!"
echo.
echo CORS configuration completed!
pause
