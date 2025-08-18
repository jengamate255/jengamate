@echo off
cd /d "F:\Dave\google cloud cli\google-cloud-sdk\bin"
gsutil.cmd cors set "F:\Dave\Jenga\jengamate\cors.json" gs://jengamate.appspot.com
pause
