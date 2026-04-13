@echo off
REM ===================================================================
REM Android Emulator Manager - Final Working Version
REM Author: Claude Code
REM Version: 2.2 (Hardware Configuration Enhanced)
REM Date: 2026-04-14
REM ===================================================================

REM Ensure system commands are available
set "PATH=%SystemRoot%\System32;%PATH%"

REM Change to script directory
cd /d "%~dp0"

setlocal enabledelayedexpansion

REM Check if running non-interactively (input redirected)

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
echo     Android Emulator Manager v2.2
echo ============================================
echo.

if not exist "%EMULATOR%" (
    echo ERROR: emulator.exe not found
    echo Please check ANDROID_SDK path in script
    echo Current path: %ANDROID_SDK%
    ping -n 2 127.0.0.1 >nul
    exit /b 1
)

if not exist "%ADB%" (
    echo ERROR: adb.exe not found
    echo Please check ANDROID_SDK path in script
    ping -n 2 127.0.0.1 >nul
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

REM Check if running non-interactively (no console)
<con echo. >nul 2>nul
if errorlevel 1 (
    echo This script requires an interactive console.
    echo Usage: android-emulator.bat [command]
    echo Commands: start, install, list, config
    exit /b 1
)

REM ===================================================================
REM Main Interactive Menu
REM ===================================================================

:MENU_MAIN
cls 2>nul
echo ============================================
echo     Android Emulator Manager
echo ============================================
echo.
echo  1. Start Emulator
echo  2. Configure Emulator Device
echo  3. Install APK to Emulator
echo  4. List All Available Emulators
echo  5. Configure Emulator Hardware
echo  6. Exit
echo.
echo ============================================
set /p CHOICE="Select option (1-6): "
if "!CHOICE!"=="" (
    echo Error: No input detected. Exiting.
    exit /b 1
)

if "%CHOICE%"=="1" goto START_EMULATOR
if "%CHOICE%"=="2" goto CONFIGURE_DEVICE
if "%CHOICE%"=="3" goto INSTALL_APK
if "%CHOICE%"=="4" goto LIST_AVDS
if "%CHOICE%"=="5" goto CONFIGURE_HARDWARE
if "%CHOICE%"=="6" exit /b 0

echo Invalid selection, please try again...
ping -n 2 127.0.0.1 >nul
goto MENU_MAIN

REM ===================================================================
REM Function: Start Emulator
REM ===================================================================

:START_EMULATOR
call :LOAD_CONFIG
if "%CONFIG_AVD%"=="" (
    echo No emulator device configured.
    ping -n 2 127.0.0.1 >nul
    goto CONFIGURE_DEVICE
)

echo Starting emulator: %CONFIG_AVD%
echo.

REM Check if emulator is already running
"%ADB%" devices | findstr "emulator" >nul
if %errorlevel% equ 0 (
    echo Emulator is already running.
    echo You can access it at: emulator-5554
    ping -n 2 127.0.0.1 >nul
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
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

echo.
set /p AVD_CHOICE="Select device (1-%COUNT%): "

if "%AVD_CHOICE%"=="" (
    echo No selection made.
    ping -n 2 127.0.0.1 >nul
    goto CONFIGURE_DEVICE
)

REM Validate selection
set /a AVD_CHOICE=%AVD_CHOICE% 2>nul
if %AVD_CHOICE% lss 1 (
    echo Invalid selection.
    ping -n 2 127.0.0.1 >nul
    goto CONFIGURE_DEVICE
)
if %AVD_CHOICE% gtr %COUNT% (
    echo Invalid selection.
    ping -n 2 127.0.0.1 >nul
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

ping -n 2 127.0.0.1 >nul
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
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

echo Checking device connection...
"%ADB%" devices | findstr "device$" >nul
if %errorlevel% neq 0 (
    echo No Android device connected.
    echo Please start emulator first.
    ping -n 2 127.0.0.1 >nul
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

ping -n 2 127.0.0.1 >nul
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
ping -n 2 127.0.0.1 >nul
goto MENU_MAIN

REM ===================================================================
REM Function: Configure Emulator Hardware
REM ===================================================================

:CONFIGURE_HARDWARE
cls
echo ============================================
echo     Configure Emulator Hardware
echo ============================================

REM Get device list
set /a "N=0"
for /f "delims=" %%i in ('"%EMULATOR%" -list-avds 2^>nul') do (
    set /a N+=1
    set "DEV_!N!=%%i"
)
if !N! equ 0 (
    echo No emulator devices found.
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

echo.
for /l %%i in (1,1,%N%) do echo   %%i. !DEV_%%i!
echo.

:hw_sel_dev
set /p "C=Select device (1-%N%): "
set /a C=%C% 2>nul
if !C! lss 1 goto hw_sel_dev
if !C! gtr %N% goto hw_sel_dev
set "SELECTED=!DEV_%C%!"
echo Selected: !SELECTED!

REM Read config
set "CFG=%USERPROFILE%\.android\avd\!SELECTED!.avd\config.ini"
set "CUR_CPU=2"
set "CUR_RAM=2048"
set "CUR_VRAM=64"
if exist "%CFG%" (
    for /f "tokens=1,2 delims==" %%a in ('type "%CFG%"') do (
        if "%%a"=="hw.cpu.ncore" set "CUR_CPU=%%b"
        if "%%a"=="hw.ramSize" set "CUR_RAM=%%b"
        if "%%a"=="hw.gpu.vramSize" set "CUR_VRAM=%%b"
    )
)
echo Current: CPU=!CUR_CPU!, RAM=!CUR_RAM!MB, VRAM=!CUR_VRAM!MB
echo.

REM Input CPU
:hw_in_cpu
set /p "V=CPU cores (1-16) [!CUR_CPU!]: "
if "!V!"=="" set "V=!CUR_CPU!"
call :check_num !V! 1 16 CPU || goto hw_in_cpu
set "F_CPU=!RET!"

REM Input RAM
:hw_in_ram
set /p "V=RAM MB (512-24576) [!CUR_RAM!]: "
if "!V!"=="" set "V=!CUR_RAM!"
call :check_num !V! 512 24576 RAM || goto hw_in_ram
set "F_RAM=!RET!"

REM Input VRAM
:hw_in_vram
set /p "V=VRAM MB (16-8192) [!CUR_VRAM!]: "
if "!V!"=="" set "V=!CUR_VRAM!"
call :check_num !V! 16 8192 VRAM || goto hw_in_vram
set "F_VRAM=!RET!"

echo.
echo Apply: CPU=!F_CPU!, RAM=!F_RAM!MB, VRAM=!F_VRAM!MB
set /p "OK=Apply? (Y/N): "
if /i "!OK!"=="Y" (
    call :save_avd "!SELECTED!" "hw.cpu.ncore" "!F_CPU!"
    call :save_avd "!SELECTED!" "hw.ramSize" "!F_RAM!"
    call :save_avd "!SELECTED!" "hw.gpu.vramSize" "!F_VRAM!"
    echo Hardware configuration updated!
    echo Please restart the emulator for changes to take effect.
) else (
    echo Cancelled.
)
ping -n 2 127.0.0.1 >nul
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

:UPDATE_CONFIG
REM Parameters: %1 = config file path, %2 = key, %3 = value
REM Updates or adds the specified key in the config file
set "CONFIG_FILE_TEMP=%~1.tmp"
set "KEY_FOUND=0"

REM Create temporary file
if exist "!CONFIG_FILE_TEMP!" del "!CONFIG_FILE_TEMP!"

REM Process each line
for /f "tokens=1* delims==" %%a in ('type "%~1" 2^>nul') do (
    if "%%a"=="%~2" (
        echo %~2=%~3 >> "!CONFIG_FILE_TEMP!"
        set "KEY_FOUND=1"
    ) else (
        echo %%a=%%b >> "!CONFIG_FILE_TEMP!"
    )
)

REM If key not found, add it
if "!KEY_FOUND!"=="0" (
    echo %~2=%~3 >> "!CONFIG_FILE_TEMP!"
)

REM Replace original file
move /y "!CONFIG_FILE_TEMP!" "%~1" >nul
exit /b

:check_num
REM Usage: call :check_num VALUE MIN MAX NAME
REM Returns: RET=validated number, or error + exit 1
set "X=%~1"
if "%X%"=="" (echo ERROR: %~4 is empty&exit /b 1)
set "X=%X: =%"
set "ISNUM=1"
for /f "delims=0123456789" %%c in ("%X%") do set "ISNUM=0"
if "!ISNUM!"=="0" (echo ERROR: %~4 must be a number: %X%&exit /b 1)
set /a "NUM=%X%" 2>nul
if errorlevel 1 (echo ERROR: %~4 conversion failed: %X%&exit /b 1)
if %NUM% lss %~2 (echo ERROR: %~4 must be ^>= %~2&exit /b 1)
if %NUM% gtr %~3 (echo ERROR: %~4 must be ^<= %~3&exit /b 1)
set "RET=%NUM%"
exit /b 0

:save_avd
REM Usage: call :save_avd AVD_NAME KEY VALUE
set "S_CFG=%USERPROFILE%\.android\avd\%~1.avd\config.ini"
set "S_KEY=%~2"
set "S_VAL=%~3"
set "S_TMP=%S_CFG%.tmp"
set "S_FOUND=0"
(
    for /f "tokens=1* delims==" %%a in ('type "%S_CFG%"') do (
        if "%%a"=="%S_KEY%" (echo %S_KEY%=%S_VAL%&set "S_FOUND=1") else (echo %%a=%%b)
    )
    if "!S_FOUND!"=="0" echo %S_KEY%=%S_VAL%
) > "%S_TMP%"
move /y "%S_TMP%" "%S_CFG%" >nul
exit /b 0

REM ===================================================================
REM End of Script
REM ===================================================================