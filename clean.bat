@echo off
echo Cleaning Android Smart Fish Tank Project...
echo.

REM Check if gradlew.bat exists
if not exist "gradlew.bat" (
    echo Error: gradlew.bat not found!
    pause
    exit /b 1
)

echo Running gradle clean...
gradlew.bat clean

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Clean successful!
) else (
    echo.
    echo Clean failed!
)

echo.
REM Clean additional directories
echo Cleaning additional directories...
if exist "app\build" (
    rmdir /s /q "app\build" 2>nul
    echo Removed app\build
)
if exist "build" (
    rmdir /s /q "build" 2>nul
    echo Removed build directory
)

echo.
echo Project cleaned.
pause