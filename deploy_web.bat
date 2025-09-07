@echo off
echo Building Flutter web app...
cd /d "%~dp0jengamate_new"
flutter clean
flutter pub get
flutter build web --release

echo.
echo Build complete! The web files are in jengamate_new\build\web
echo You can now deploy the contents of this directory to any web server.
pause
