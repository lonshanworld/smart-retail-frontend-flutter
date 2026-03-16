@echo off
setlocal EnableDelayedExpansion

REM Smart Retail Portal Builder for Windows
REM Usage: build-portal.bat [public|admin|merchant|staff|shop|customer] [platform ...]
REM Platforms: web apk appbundle windows linux macos ios all

set PORTAL=%~1
if "%PORTAL%"=="" goto usage

if /I "%PORTAL%"=="customer" set PORTAL=public

set VALID_PORTAL=
if /I "%PORTAL%"=="public" set VALID_PORTAL=1
if /I "%PORTAL%"=="admin" set VALID_PORTAL=1
if /I "%PORTAL%"=="merchant" set VALID_PORTAL=1
if /I "%PORTAL%"=="staff" set VALID_PORTAL=1
if /I "%PORTAL%"=="shop" set VALID_PORTAL=1
if not defined VALID_PORTAL (
    echo Error: Invalid portal '%PORTAL%'.
    goto usage
)

for /f "tokens=1*" %%A in ("%*") do set PLATFORMS=%%B
if "%PLATFORMS%"=="" set PLATFORMS=web
if /I "%PLATFORMS%"=="all" set PLATFORMS=web apk appbundle windows

set ENV_FILE=.env.%PORTAL%
if not exist "%ENV_FILE%" (
    echo Error: %ENV_FILE% not found.
    exit /b 1
)

echo ================================================
echo Smart Retail Portal Builder
echo ================================================
echo Portal: %PORTAL%
echo Platforms: %PLATFORMS%
echo.

echo Configuring environment from %ENV_FILE% ...
copy /Y "%ENV_FILE%" .env >nul
if errorlevel 1 (
    echo Failed to copy environment file.
    exit /b 1
)

set TARGET_FILE=lib\main_%PORTAL%.dart
if not exist "%TARGET_FILE%" (
    echo Error: %TARGET_FILE% not found.
    exit /b 1
)

echo Getting dependencies...
call flutter pub get
if errorlevel 1 exit /b 1

if not exist build\artifacts mkdir build\artifacts

for %%P in (%PLATFORMS%) do (
    call :buildOne %%P
    if errorlevel 1 exit /b 1
)

echo.
echo ================================================
echo BUILD MATRIX COMPLETE
echo Artifacts folder: build\artifacts\%PORTAL%
echo ================================================
exit /b 0

:buildOne
set PLATFORM=%~1
set OUT_DIR=build\artifacts\%PORTAL%\%PLATFORM%
if exist "!OUT_DIR!" rmdir /s /q "!OUT_DIR!"
mkdir "!OUT_DIR!"

echo.
echo ---- Building %PORTAL% / %PLATFORM% ----

if /I "%PLATFORM%"=="web" (
    call flutter build web --release --target="%TARGET_FILE%"
    if errorlevel 1 exit /b 1
    xcopy /E /I /Y build\web "!OUT_DIR!\web" >nul
    exit /b 0
)

if /I "%PLATFORM%"=="apk" (
    call flutter build apk --release --target="%TARGET_FILE%"
    if errorlevel 1 exit /b 1
    copy /Y build\app\outputs\flutter-apk\app-release.apk "!OUT_DIR!\smart-retail-%PORTAL%-release.apk" >nul
    exit /b 0
)

if /I "%PLATFORM%"=="appbundle" (
    call flutter build appbundle --release --target="%TARGET_FILE%"
    if errorlevel 1 exit /b 1
    copy /Y build\app\outputs\bundle\release\app-release.aab "!OUT_DIR!\smart-retail-%PORTAL%-release.aab" >nul
    exit /b 0
)

if /I "%PLATFORM%"=="windows" (
    call flutter build windows --release --target="%TARGET_FILE%"
    if errorlevel 1 exit /b 1
    xcopy /E /I /Y build\windows\x64\runner\Release "!OUT_DIR!\windows-release" >nul
    exit /b 0
)

if /I "%PLATFORM%"=="linux" (
    echo Skipping linux build on Windows host.
    exit /b 0
)

if /I "%PLATFORM%"=="macos" (
    echo Skipping macos build on Windows host.
    exit /b 0
)

if /I "%PLATFORM%"=="ios" (
    echo Skipping ios build on Windows host.
    exit /b 0
)

echo Error: Unsupported platform '%PLATFORM%'.
exit /b 1

:usage
echo Usage: build-portal.bat [public^|admin^|merchant^|staff^|shop^|customer] [platform ...]
echo Platforms: web apk appbundle windows linux macos ios all
echo Examples:
echo   build-portal.bat public web
echo   build-portal.bat admin web windows
echo   build-portal.bat merchant all
exit /b 1
