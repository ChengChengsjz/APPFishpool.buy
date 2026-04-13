@echo off
REM ===================================================================
REM Android Emulator Manager - Final Working Version
REM Author: Claude Code
REM Version: 2.3 (Bug Fix: CPU Input Crash)
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
echo.

call :LOAD_CONFIG
if "%CONFIG_AVD%"=="" (
    echo No emulator device configured.
    echo Please configure an emulator device first.
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

echo Currently configured emulator: %CONFIG_AVD%
echo.
set /p MODIFY_CURRENT="Modify this emulator? (Y/N): "
if /i not "%MODIFY_CURRENT%"=="Y" (
    goto SELECT_AVD_FOR_HARDWARE
)
set "SELECTED_AVD=%CONFIG_AVD%"
goto LOAD_AVD_CONFIG

:SELECT_AVD_FOR_HARDWARE
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
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

echo.
set /p AVD_CHOICE="Select device (1-%COUNT%): "

if "%AVD_CHOICE%"=="" (
    echo No selection made.
    ping -n 2 127.0.0.1 >nul
    goto SELECT_AVD_FOR_HARDWARE
)

REM Validate selection
set /a AVD_CHOICE=%AVD_CHOICE% 2>nul
if %AVD_CHOICE% lss 1 (
    echo Invalid selection.
    ping -n 2 127.0.0.1 >nul
    goto SELECT_AVD_FOR_HARDWARE
)
if %AVD_CHOICE% gtr %COUNT% (
    echo Invalid selection.
    ping -n 2 127.0.0.1 >nul
    goto SELECT_AVD_FOR_HARDWARE
)

REM Get selected AVD
for /l %%i in (1,1,%COUNT%) do (
    if %AVD_CHOICE% equ %%i (
        set "SELECTED_AVD=!AVDS[%%i]!"
    )
)

REM Remove spaces from AVD name
set "SELECTED_AVD=!SELECTED_AVD: =!"
REM Remove all control characters
for /f "delims=" %%c in ("!SELECTED_AVD!") do set "SELECTED_AVD=%%c"

:LOAD_AVD_CONFIG
echo.
echo Selected emulator: !SELECTED_AVD!
echo.

REM Build config.ini path
set "AVD_CONFIG_PATH=%USERPROFILE%\.android\avd\!SELECTED_AVD!.avd\config.ini"
if not exist "!AVD_CONFIG_PATH!" (
    echo Config file not found: !AVD_CONFIG_PATH!
    echo Please ensure the emulator exists.
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

REM Read current values with safe validation
set "CURRENT_CPU=2"
set "CURRENT_RAM=2048"
set "CURRENT_VRAM=64"

if exist "!AVD_CONFIG_PATH!" (
    echo [DEBUG] Reading config file: !AVD_CONFIG_PATH!
    for /f "tokens=1,2 delims==" %%a in ('type "!AVD_CONFIG_PATH!" 2^>nul') do (
        if "%%a"=="hw.cpu.ncore" (
            set "TEMP_CPU=%%b"
            REM Clean value: remove spaces, CR, LF
            set "TEMP_CPU=!TEMP_CPU: =!"
            set "TEMP_CPU=!TEMP_CPU: =!"
            REM Simple numeric check without pipes
            set "IS_NUM=1"
            for /f "delims=0123456789" %%c in ("!TEMP_CPU!") do set "IS_NUM=0"
            if "!IS_NUM!"=="1" (
                set /a "TEST_VAL=!TEMP_CPU!" 2>nul
                if "!TEST_VAL!" neq "" (
                    if !TEST_VAL! geq 1 if !TEST_VAL! leq 16 (
                        set "CURRENT_CPU=!TEMP_CPU!"
                    )
                )
            )
        )
        if "%%a"=="hw.ramSize" (
            set "TEMP_RAM=%%b"
            REM Clean value: remove spaces, CR, LF
            set "TEMP_RAM=!TEMP_RAM: =!"
            set "TEMP_RAM=!TEMP_RAM: =!"
            REM Simple numeric check without pipes
            set "IS_NUM=1"
            for /f "delims=0123456789" %%c in ("!TEMP_RAM!") do set "IS_NUM=0"
            if "!IS_NUM!"=="1" (
                set /a "TEST_VAL=!TEMP_RAM!" 2>nul
                if "!TEST_VAL!" neq "" (
                    if !TEST_VAL! geq 512 if !TEST_VAL! leq 24576 (
                        set "CURRENT_RAM=!TEMP_RAM!"
                    )
                )
            )
        )
        if "%%a"=="hw.gpu.vramSize" (
            set "TEMP_VRAM=%%b"
            REM Clean value: remove spaces, CR, LF
            set "TEMP_VRAM=!TEMP_VRAM: =!"
            set "TEMP_VRAM=!TEMP_VRAM: =!"
            REM Simple numeric check without pipes
            set "IS_NUM=1"
            for /f "delims=0123456789" %%c in ("!TEMP_VRAM!") do set "IS_NUM=0"
            if "!IS_NUM!"=="1" (
                set /a "TEST_VAL=!TEMP_VRAM!" 2>nul
                if "!TEST_VAL!" neq "" (
                    if !TEST_VAL! geq 16 if !TEST_VAL! leq 8192 (
                        set "CURRENT_VRAM=!TEMP_VRAM!"
                    )
                )
            )
        )
    )
    REM Final defaults configured above
)

echo Current hardware configuration:
echo   CPU Cores: !CURRENT_CPU!
echo   RAM Size (MB): !CURRENT_RAM!
echo   VRAM Size (MB): !CURRENT_VRAM!
echo.

REM Input CPU cores
:INPUT_CPU
set /p NEW_CPU="Enter CPU cores (1-16, default !CURRENT_CPU!): "
if "!NEW_CPU!"=="" set "NEW_CPU=!CURRENT_CPU!"

REM Remove leading/trailing spaces
set "NEW_CPU=!NEW_CPU: =!"

REM Check if input contains only digits (safe method without pipes)
set "IS_NUMERIC=1"
for /f "delims=0123456789" %%c in ("!NEW_CPU!") do set "IS_NUMERIC=0"

if "!IS_NUMERIC!"=="0" (
    echo Invalid CPU cores. Must contain only numbers (0-9).
    ping -n 2 127.0.0.1 >nul
    goto INPUT_CPU
)

REM Convert to number safely
set /a "CPU_VALUE=!NEW_CPU!" 2>nul
if "!CPU_VALUE!"=="" (
    echo Invalid CPU cores. Cannot convert to number.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_CPU
)

REM Check range
if !CPU_VALUE! lss 1 (
    echo CPU cores must be at least 1.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_CPU
)
if !CPU_VALUE! gtr 16 (
    echo CPU cores must not exceed 16.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_CPU
)

REM Use validated value
set "NEW_CPU=!CPU_VALUE!"

REM Input RAM size
:INPUT_RAM
set /p NEW_RAM="Enter RAM size in MB (512-24576, default !CURRENT_RAM!): "
if "!NEW_RAM!"=="" set "NEW_RAM=!CURRENT_RAM!"

REM Remove leading/trailing spaces
set "NEW_RAM=!NEW_RAM: =!"

REM Check if input contains only digits (safe method without pipes)
set "IS_NUMERIC=1"
for /f "delims=0123456789" %%c in ("!NEW_RAM!") do set "IS_NUMERIC=0"

if "!IS_NUMERIC!"=="0" (
    echo Invalid RAM size. Must contain only numbers (0-9).
    ping -n 2 127.0.0.1 >nul
    goto INPUT_RAM
)

REM Convert to number safely
set /a "RAM_VALUE=!NEW_RAM!" 2>nul
if "!RAM_VALUE!"=="" (
    echo Invalid RAM size. Cannot convert to number.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_RAM
)

REM Check range
if !RAM_VALUE! lss 512 (
    echo RAM size must be at least 512 MB.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_RAM
)
if !RAM_VALUE! gtr 24576 (
    echo RAM size must not exceed 24576 MB (24GB).
    ping -n 2 127.0.0.1 >nul
    goto INPUT_RAM
)

REM Use validated value
set "NEW_RAM=!RAM_VALUE!"

REM Input VRAM size
:INPUT_VRAM
set /p NEW_VRAM="Enter VRAM size in MB (16-8192, default !CURRENT_VRAM!): "
if "!NEW_VRAM!"=="" set "NEW_VRAM=!CURRENT_VRAM!"

REM Remove leading/trailing spaces
set "NEW_VRAM=!NEW_VRAM: =!"

REM Check if input contains only digits (safe method without pipes)
set "IS_NUMERIC=1"
for /f "delims=0123456789" %%c in ("!NEW_VRAM!") do set "IS_NUMERIC=0"

if "!IS_NUMERIC!"=="0" (
    echo Invalid VRAM size. Must contain only numbers (0-9).
    ping -n 2 127.0.0.1 >nul
    goto INPUT_VRAM
)

REM Convert to number safely
set /a "VRAM_VALUE=!NEW_VRAM!" 2>nul
if "!VRAM_VALUE!"=="" (
    echo Invalid VRAM size. Cannot convert to number.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_VRAM
)

REM Check range
if !VRAM_VALUE! lss 16 (
    echo VRAM size must be at least 16 MB.
    ping -n 2 127.0.0.1 >nul
    goto INPUT_VRAM
)
if !VRAM_VALUE! gtr 8192 (
    echo VRAM size must not exceed 8192 MB (8GB).
    ping -n 2 127.0.0.1 >nul
    goto INPUT_VRAM
)

REM Use validated value
set "NEW_VRAM=!VRAM_VALUE!"

echo.
echo New configuration:
echo   CPU Cores: !NEW_CPU!
echo   RAM Size: !NEW_RAM! MB
echo   VRAM Size: !NEW_VRAM! MB
echo.
set /p CONFIRM="Apply these changes? (Y/N): "
if /i not "!CONFIRM!"=="Y" (
    echo Changes cancelled.
    ping -n 2 127.0.0.1 >nul
    goto MENU_MAIN
)

REM Update config.ini
call :UPDATE_CONFIG "!AVD_CONFIG_PATH!" "hw.cpu.ncore" "!NEW_CPU!"
call :UPDATE_CONFIG "!AVD_CONFIG_PATH!" "hw.ramSize" "!NEW_RAM!"
call :UPDATE_CONFIG "!AVD_CONFIG_PATH!" "hw.gpu.vramSize" "!NEW_VRAM!"

echo.
echo Hardware configuration updated successfully!
echo Please restart the emulator for changes to take effect.
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

REM ===================================================================
REM End of Script
REM ===================================================================