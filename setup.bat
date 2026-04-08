@echo off
echo ============================================
echo   LUXE Fashion App - Platform Setup
echo ============================================
echo.

echo [1/3] Getting Flutter packages...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: flutter pub get failed. Make sure Flutter is installed.
    pause
    exit /b 1
)

echo.
echo [2/3] Generating platform folders (android, web, windows)...
call flutter create --platforms=android,web,windows .
if %errorlevel% neq 0 (
    echo ERROR: flutter create failed.
    pause
    exit /b 1
)

echo.
echo [3/3] Getting packages again after platform generation...
call flutter pub get

echo.
echo ============================================
echo   Setup Complete! Run the app with:
echo.
echo   Android phone:  flutter run -d android
echo   Web browser:    flutter run -d chrome
echo   Windows app:    flutter run -d windows
echo ============================================
echo.
pause
