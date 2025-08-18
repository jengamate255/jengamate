@echo off
"C:\Program Files\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd" storage buckets update gs://jengamate.firebasestorage.app --cors-file="cors.json"
echo CORS configuration completed!
pause
