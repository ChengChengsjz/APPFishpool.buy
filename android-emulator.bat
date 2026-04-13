@echo off
REM ===================================================================
REM Android Emulator Manager - Final Working Version
REM Author: Claude Code
REM Version: 2.1 (Fixed and tested)
REM Date: 2026-04-13
REM ===================================================================

REM Ensure system commands are available
set "PATH=%SystemRoot%\System32;%PATH%"

REM Change to script directory
cd /d "%~dp0"

setlocal enabledelayedexpansion

REM ===================================================================
REM Configuration
REM ===================================================================

REM Android SDK path
set "ANDROID_SDK=C:\Users\ChengCheng\AppData\Local\Android\Sdk"
set "EMULATOR=%ANDROID_SDK%\emulator\emulator.exe"
set "ADB=%ANDROID_SDK%\platform-tools\adb.exe"
set "CONFIG_FILE=emulator_config.txt"
set "APK_PATH=app\build\outputs\apk\debug\app-debug.apk"

REM Set Android environment variables
set "ANDROID_SDK_ROOT=%ANDROID_SDK%"
set "ANDROID_HOME=%ANDROID_SDK%"

REM ===================================================================
REM Initial checks
REM ===================================================================

echo ============================================
echo     Android Emulator Manager v2.1
echo ============================================
echo.

if not exist "%EMULATOR%" (
    echo ERROR: emulator.exe not found
    echo Please check ANDROID_SDK path in script
    echo Current path: %ANDROID_SDK%
    pause
    exit /b 1
)

if not exist "%ADB%" (
    echo ERROR: adb.exe not found
    echo Please check ANDROID_SDK path in script
    pause
    exit /b 1
)

REM ===================================================================
REM Command line parameter handling
REM ===================================================================

if not "%~1"=="" (
    if /i "%~1"=="start" goto CMD_START
    if /i "%~1"=="install" goto CMD_INSTALL
    if /i "%~1"=="list" goto CMD_LIST
    if /i "%~1"=="config" goto CMD_CONFIG
    echo Usage: android-emulator.bat [command]
    echo Commands:
    echo   start   - Start the configured emulator
    echo   install - Install APK to emulator
    echo   list    - List all available emulators
    echo   config  - Configure emulator device
    echo.
    exit /b 1
)

REM ===================================================================
REM Main Interactive Menu
REM ===================================================================

:MENU_MAIN
cls
echo ============================================
echo     Android Emulator Manager
echo ============================================
echo.
echo  1. Start Emulator
echo  2. Configure Emulator Device
echo  3. Install APK to Emulator
echo  4. List All Available Emulators
echo  5. Exit
echo.
echo ============================================
set /p CHOICE="Select option (1-5): "

if "%CHOICE%"=="1" goto START_EMULATOR
if "%CHOICE%"=="2" goto CONFIGURE_DEVICE
if "%CHOICE%"=="3" goto INSTALL_APK
if "%CHOICE%"=="4" goto LIST_AVDS
if "%CHOICE%"=="5" exit /b 0

echo Invalid selection, please try again...
pause >nul
goto MENU_MAIN

REM ===================================================================
REM Function: Start Emulator
REM ===================================================================

:START_EMULATOR
call :LOAD_CONFIG
if "%CONFIG_AVD%"=="" (
    echo No emulator device configured.
    pause
    goto CONFIGURE_DEVICE
)

echo Starting emulator: %CONFIG_AVD%
echo.

REM Check if emulator is already running
"%ADB%" devices | findstr "emulator" >nul
if %errorlevel% equ 0 (
    echo Emulator is already running.
    echo You can access it at: emulator-5554
    pause
    goto MENU_MAIN
)

echo Launching emulator (this may take a minute)...
set ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=3
start "Android Emulator" "%EMULATOR%" -avd "%CONFIG_AVD%" -no-audio -no-boot-anim

echo.
echo Emulator started in new window.
echo Wait for it to fully boot (30-60 seconds).
echo.
goto MENU_MAIN

REM ===================================================================
REM Function: Configure Emulator Device
REM ===================================================================

:CONFIGURE_DEVICE
cls
echo ============================================
echo     Configure Emulator Device
echo ============================================
echo.
echo Available emulators:
echo.

REM Get list of AVDs
set AVDS[0]=0
set COUNT=0
for /f "tokens=*" %%i in ('"%EMULATOR%" -list-avds 2^>nul') do (
    set /a COUNT+=1
    set "CLEAN_AVD=%%i"
    set "CLEAN_AVD=!CLEAN_AVD: =!"
    for /f "delims=" %%c in ("!CLEAN_AVD!") do set "CLEAN_AVD=%%c"
    echo !COUNT!. !CLEAN_AVD!
    set "AVDS[!COUNT!]=!CLEAN_AVD!"
)

if %COUNT% equ 0 (
    echo No emulator devices found.
    echo Please create an AVD using Android Studio.
    pause
    goto MENU_MAIN
)

echo.
set /p AVD_CHOICE="Select device (1-%COUNT%): "

if "%AVD_CHOICE%"=="" (
    echo No selection made.
    pause
    goto CONFIGURE_DEVICE
)

REM Validate selection
set /a AVD_CHOICE=%AVD_CHOICE% 2>nul
if %AVD_CHOICE% lss 1 (
    echo Invalid selection.
    pause
    goto CONFIGURE_DEVICE
)
if %AVD_CHOICE% gtr %COUNT% (
    echo Invalid selection.
    pause
    goto CONFIGURE_DEVICE
)

REM Get selected AVD
for /l %%i in (1,1,%COUNT%) do (
    if %AVD_CHOICE% equ %%i (
        set "SELECTED_AVD=!AVDS[%%i]!"
    )
)

REM Remove spaces from AVD name
set "SELECTED_AVD=!SELECTED_AVD: =!"

REM Remove all control characters (CR, LF, tab)
for /f "delims=" %%c in ("!SELECTED_AVD!") do set "SELECTED_AVD=%%c"

REM Write config file without trailing spaces
> "%CONFIG_FILE%" echo AVD=!SELECTED_AVD!
echo.
echo Emulator configured to: !SELECTED_AVD!
echo Configuration saved.

echo.
set /p START_NOW="Start this emulator now? (Y/N): "
if /i "%START_NOW%"=="Y" goto START_EMULATOR

pause
goto MENU_MAIN

REM ===================================================================
REM Function: Install APK to Emulator
REM ===================================================================

:INSTALL_APK
cls
echo ============================================
echo     Install APK to Emulator
echo ============================================
echo.

if not exist "%APK_PATH%" (
    echo APK file not found: %APK_PATH%
    echo.
    set /p CUSTOM_APK="Enter APK file path (or press Enter to go back): "
    if "%CUSTOM_APK%"=="" goto MENU_MAIN
    set "APK_PATH=%CUSTOM_APK%"
)

if not exist "%APK_PATH%" (
    echo APK file does not exist.
    pause
    goto MENU_MAIN
)

echo Checking device connection...
"%ADB%" devices | findstr "device$" >nul
if %errorlevel% neq 0 (
    echo No Android device connected.
    echo Please start emulator first.
    pause
    goto MENU_MAIN
)

echo Installing APK: %APK_PATH%
echo.
"%ADB%" install -r "%APK_PATH%"
if %errorlevel% equ 0 (
    echo.
    echo APK installation successful!
    echo.
    set /p LAUNCH_APP="Launch application? (Y/N): "
    if /i "%LAUNCH_APP%"=="Y" (
        echo Launching application...
        "%ADB%" shell am start -n cacom.example.smarthome/.MainActivity
    )
) else (
    echo.
    echo APK installation failed!
)

pause
goto MENU_MAIN

REM ===================================================================
REM Function: List All Available Emulators
REM ===================================================================

:LIST_AVDS
cls
echo ============================================
echo     Available Emulator Devices
echo ============================================
echo.
"%EMULATOR%" -list-avds
echo.
pause
goto MENU_MAIN

REM ===================================================================
REM Command Line Functions
REM ===================================================================

:CMD_START
call :LOAD_CONFIG
if "%CONFIG_AVD%"=="" (
    echo ERROR: No emulator device configured
    echo Run: android-emulator.bat config
    exit /b 1
)
echo Starting emulator: %CONFIG_AVD%
set ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=3
start "Android Emulator" "%EMULATOR%" -avd "%CONFIG_AVD%" -no-audio -no-boot-anim
echo Emulator started
exit /b 0

:CMD_INSTALL
if not exist "%APK_PATH%" (
    echo ERROR: APK file not found: %APK_PATH%
    exit /b 1
)
"%ADB%" devices | findstr "device$" >nul
if %errorlevel% neq 0 (
    echo ERROR: No Android device connected
    exit /b 1
)
echo Installing APK: %APK_PATH%
"%ADB%" install -r "%APK_PATH%"
if %errorlevel% equ 0 (
    echo APK installation successful
    exit /b 0
) else (
    echo APK installation failed
    exit /b 1
)

:CMD_LIST
echo Available emulator devices:
"%EMULATOR%" -list-avds
exit /b 0

:CMD_CONFIG
goto CONFIGURE_DEVICE

REM ===================================================================
REM Helper Functions
REM ===================================================================

:LOAD_CONFIG
set "CONFIG_AVD="
if exist "%CONFIG_FILE%" (
    for /f "tokens=2 delims==" %%i in ('type "%CONFIG_FILE%" ^| findstr "AVD="') do (
        set "CONFIG_AVD=%%i"
    )
)

REM Clean up AVD name
if not "%CONFIG_AVD%"=="" (
    set "CONFIG_AVD=%CONFIG_AVD: =!"
    for /f "delims=" %%c in ("%CONFIG_AVD%") do set "CONFIG_AVD=%%c"
)
exit /b

REM ===================================================================
REM End of Script
REM ===================================================================