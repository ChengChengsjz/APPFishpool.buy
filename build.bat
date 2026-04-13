@echo off
echo Building Android Smart Fish Tank App...
echo.

REM Check if gradlew.bat exists
if not exist "gradlew.bat" (
    echo Error: gradlew.bat not found!
    pause
    exit /b 1
)

REM Run gradle build
echo Running gradle build...
gradlew.bat assembleDebug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build successful!
    echo APK location: app\build\outputs\apk\debug\app-debug.apk
) else (
    echo.
    echo Build failed!
)

echo.
pause