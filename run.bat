@echo off
echo Installing Android Smart Fish Tank App...
echo.

REM Set Android SDK path
set ANDROID_SDK=C:\Users\ChengCheng\AppData\Local\Android\Sdk
set ADB=%ANDROID_SDK%\platform-tools\adb.exe

REM Check if gradlew.bat exists
if not exist "gradlew.bat" (
    echo Error: gradlew.bat not found!
    pause
    exit /b 1
)

REM Check if ADB exists
if not exist "%ADB%" (
    echo Error: ADB not found at %ADB%
    echo Please check Android SDK installation.
    pause
    exit /b 1
)

REM Check ADB devices
echo Checking connected devices...
"%ADB%" devices

echo.
echo Installing app to device...
gradlew.bat installDebug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Installation successful!
    echo.
    echo To launch the app, run:
    echo adb shell am start -n cacom.example.smarthome/.MainActivity
) else (
    echo.
    echo Installation failed!
)

echo.
pause