@echo off
REM Smart Retail Portal Builder for Windows
REM Usage: build-portal.bat [admin|customer] [web|apk|ios]

set PORTAL_TYPE=%1
set BUILD_TYPE=%2

if "%PORTAL_TYPE%"=="" goto usage
if "%BUILD_TYPE%"=="" goto usage

if not "%PORTAL_TYPE%"=="admin" if not "%PORTAL_TYPE%"=="customer" (
    echo Error: Portal type must be 'admin' or 'customer'
    exit /b 1
)

if not "%BUILD_TYPE%"=="web" if not "%BUILD_TYPE%"=="apk" if not "%BUILD_TYPE%"=="ios" (
    echo Error: Build type must be 'web', 'apk', or 'ios'
    exit /b 1
)

echo ================================================
echo   Smart Retail Portal Builder
echo ================================================
echo Portal: %PORTAL_TYPE%
echo Build Type: %BUILD_TYPE%
echo.

REM Copy the appropriate .env file
echo Copying .env.%PORTAL_TYPE% to .env...
copy /Y .env.%PORTAL_TYPE% .env

if errorlevel 1 (
    echo Error: Failed to copy .env.%PORTAL_TYPE%
    exit /b 1
)

echo Environment configured for %PORTAL_TYPE% portal
echo.

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean

REM Get dependencies
echo Getting dependencies...
call flutter pub get

REM Build based on type
echo.
echo Building %PORTAL_TYPE% portal for %BUILD_TYPE%...
echo.

if "%BUILD_TYPE%"=="web" (
    call flutter build web --release
    set BUILD_OUTPUT=build\web
)

if "%BUILD_TYPE%"=="apk" (
    call flutter build apk --release
    set BUILD_OUTPUT=build\app\outputs\flutter-apk\app-release.apk
)

if "%BUILD_TYPE%"=="ios" (
    call flutter build ios --release
    set BUILD_OUTPUT=build\ios
)

if errorlevel 1 (
    echo.
    echo BUILD FAILED!
    exit /b 1
)

echo.
echo ================================================
echo BUILD SUCCESSFUL!
echo ================================================
echo Portal: %PORTAL_TYPE%
echo Build Type: %BUILD_TYPE%
echo Output: %BUILD_OUTPUT%
echo.

REM Rename output for clarity
if "%BUILD_TYPE%"=="apk" (
    move /Y %BUILD_OUTPUT% build\smart-retail-%PORTAL_TYPE%.apk
    echo APK renamed to: build\smart-retail-%PORTAL_TYPE%.apk
)

if "%BUILD_TYPE%"=="web" (
    if exist build\%PORTAL_TYPE%-portal rmdir /s /q build\%PORTAL_TYPE%-portal
    move build\web build\%PORTAL_TYPE%-portal
    echo Web build moved to: build\%PORTAL_TYPE%-portal
)

echo.
goto end

:usage
echo Usage: build-portal.bat [admin^|customer] [web^|apk^|ios]
echo.
echo Examples:
echo   build-portal.bat admin web      # Build admin portal for web
echo   build-portal.bat customer apk   # Build customer portal for Android
exit /b 1

:end
