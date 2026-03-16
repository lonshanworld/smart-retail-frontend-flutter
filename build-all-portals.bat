@echo off
setlocal

set PLATFORMS=%*
if "%PLATFORMS%"=="" set PLATFORMS=web
if /I "%PLATFORMS%"=="all" set PLATFORMS=web apk appbundle windows

for %%P in (public admin merchant staff) do (
  echo.
  echo ===== Building portal %%P =====
  call build-portal.bat %%P %PLATFORMS%
  if errorlevel 1 exit /b 1
)

echo.
echo All portal builds completed.
exit /b 0
