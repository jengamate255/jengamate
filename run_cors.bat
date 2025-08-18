@echo off
cd /d "F:\Dave\Jenga\jengamate"
"F:\Dave\google cloud cli\google-cloud-sdk\bin\gcloud.cmd" storage buckets update gs://jengamate.appspot.com --cors-file=cors.json
echo CORS configuration applied successfully!
pause
