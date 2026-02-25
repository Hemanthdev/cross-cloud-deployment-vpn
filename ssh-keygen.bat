@echo off
REM ============================================================================
REM Multi-Cloud SSH Key Generator for Windows
REM Generates SSH keys for AWS, Azure, GCP, OCI
REM Requires: OpenSSH Client (Windows 10+)
REM ============================================================================

setlocal enabledelayedexpansion

REM Configuration
set "HOME=%USERPROFILE%"
set "KEY_DIR=%HOME%\.ssh"
set "KEY_TYPE=ed25519"

REM Create .ssh directory if it doesn't exist
if not exist "%KEY_DIR%" mkdir "%KEY_DIR%"

REM Main loop
:MENU
cls
echo.
echo ╔════════════════════════════════════════════════════════════════════════╗
echo ║       Multi-Cloud SSH Key Generator v1.0                              ║
echo ║       AWS ^| Azure ^| GCP ^| OCI                                         ║
echo ╚════════════════════════════════════════════════════════════════════════╝
echo.
echo     ┌─────────────┐
echo     │    AWS      │
echo     │  Key Gen    │
echo     └────┬────────┘
echo          │
echo     ┌────▼────────┐
echo     │   Azure     │
echo     │  Key Gen    │
echo     └────┬────────┘
echo          │
echo     ┌────▼────────┐
echo     │     GCP     │
echo     │  Key Gen    │
echo     └────┬────────┘
echo          │
echo     ┌────▼────────┐
echo     │     OCI     │
echo     │  Key Gen    │
echo     └─────────────┘
echo.
echo ────────────────────────────────────────────────────────────────────────
echo Select Option:
echo ────────────────────────────────────────────────────────────────────────
echo.
echo   1) Generate All Keys (AWS, Azure, GCP, OCI)
echo   2) Generate AWS Key
echo   3) Generate Azure Key
echo   4) Generate GCP Key
echo   5) Generate OCI Key
echo   6) View Key Locations
echo   7) Show Statistics
echo   8) Change Key Type (ED25519/RSA)
echo   9) Exit
echo.
set /p CHOICE=Enter choice: 

if "%CHOICE%"=="1" goto GENERATE_ALL
if "%CHOICE%"=="2" goto GENERATE_AWS
if "%CHOICE%"=="3" goto GENERATE_AZURE
if "%CHOICE%"=="4" goto GENERATE_GCP
if "%CHOICE%"=="5" goto GENERATE_OCI
if "%CHOICE%"=="6" goto SHOW_LOCATIONS
if "%CHOICE%"=="7" goto SHOW_STATS
if "%CHOICE%"=="8" goto CHANGE_TYPE
if "%CHOICE%"=="9" goto EXIT_SCRIPT

echo Invalid choice. Press Enter to continue...
pause >nul
goto MENU

REM ============================================================================
REM Generate All Keys
REM ============================================================================
:GENERATE_ALL
call :GENERATE_KEY AWS
call :GENERATE_KEY Azure
call :GENERATE_KEY GCP
call :GENERATE_KEY OCI
pause >nul
goto MENU

:GENERATE_AWS
call :GENERATE_KEY AWS
pause >nul
goto MENU

:GENERATE_AZURE
call :GENERATE_KEY Azure
pause >nul
goto MENU

:GENERATE_GCP
call :GENERATE_KEY GCP
pause >nul
goto MENU

:GENERATE_OCI
call :GENERATE_KEY OCI
pause >nul
goto MENU

REM ============================================================================
REM Generate Key Function
REM ============================================================================
:GENERATE_KEY
setlocal
set "CLOUD=%1"
set "CLOUD_LOWER=%CLOUD:~0,1%"
for %%A in (AWS Azure GCP OCI) do (
    if /i "%CLOUD%"=="%%A" set "CLOUD_FILE=%%A"
)
set "CLOUD_FILE=%CLOUD_FILE:~0,1%%CLOUD_FILE:~1%"

set "KEY_PATH=%KEY_DIR%\%CLOUD_FILE:~0,1%_%KEY_TYPE%"

cls
echo.
echo ────────────────────────────────────────────────────────────────────────
echo Generating SSH key for %CLOUD%
echo ────────────────────────────────────────────────────────────────────────
echo.

REM Check if key exists
if exist "%KEY_PATH%" (
    echo WARNING: Key already exists: %KEY_PATH%
    set /p OVERWRITE=Overwrite? (y/n): 
    if /i not "!OVERWRITE!"=="y" (
        echo Skipped.
        endlocal
        exit /b
    )
)

REM Generate key
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set "CURDATE=%%c-%%b-%%a")

if "%KEY_TYPE%"=="rsa" (
    ssh-keygen -t rsa -b 4096 -f "%KEY_PATH%" -N "" -C "multi-cloud-%CLOUD_FILE:~0,1%@%CURDATE%" >nul 2>&1
) else (
    ssh-keygen -t ed25519 -f "%KEY_PATH%" -N "" -C "multi-cloud-%CLOUD_FILE:~0,1%@%CURDATE%" >nul 2>&1
)

if !errorlevel! equ 0 (
    echo Successfully generated key
    echo.
    echo Private: %KEY_PATH%
    echo Public:  %KEY_PATH%.pub
    echo.
) else (
    echo Failed to generate key. Ensure ssh-keygen is installed.
)

endlocal
exit /b

REM ============================================================================
REM Show Key Locations
REM ============================================================================
:SHOW_LOCATIONS
cls
echo.
echo ────────────────────────────────────────────────────────────────────────
echo SSH Key Locations
echo ────────────────────────────────────────────────────────────────────────
echo.

for %%C in (AWS Azure GCP OCI) do (
    set "KEY_PATH=%KEY_DIR%\%%C_%KEY_TYPE%"
    if exist "!KEY_PATH!" (
        echo [OK] %%C
        echo   Private: !KEY_PATH!
        echo   Public:  !KEY_PATH!.pub
    ) else (
        echo [--] %%C: Not generated
    )
    echo.
)

pause >nul
goto MENU

REM ============================================================================
REM Show Statistics
REM ============================================================================
:SHOW_STATS
cls
echo.
echo ────────────────────────────────────────────────────────────────────────
echo Key Statistics
echo ────────────────────────────────────────────────────────────────────────
echo.

setlocal enabledelayedexpansion
set /a KEY_COUNT=0

for %%F in ("%KEY_DIR%\*_%KEY_TYPE%") do (
    if exist "%%F" (
        set /a KEY_COUNT+=1
    )
)

echo Total Keys Generated: %KEY_COUNT%
echo Key Type: %KEY_TYPE%
echo Key Directory: %KEY_DIR%
echo.

pause >nul
goto MENU

REM ============================================================================
REM Change Key Type
REM ============================================================================
:CHANGE_TYPE
cls
echo.
echo ────────────────────────────────────────────────────────────────────────
echo Current Key Type: %KEY_TYPE%
echo ────────────────────────────────────────────────────────────────────────
echo.
echo   1) ED25519 (Recommended, smaller, faster)
echo   2) RSA-4096 (Traditional, widely supported)
echo.
set /p TYPE_CHOICE=Select: 

if "%TYPE_CHOICE%"=="1" (
    set "KEY_TYPE=ed25519"
    echo Key type set to ED25519
) else if "%TYPE_CHOICE%"=="2" (
    set "KEY_TYPE=rsa"
    echo Key type set to RSA-4096
) else (
    echo Invalid choice
)

pause >nul
goto MENU

REM ============================================================================
REM Exit Script
REM ============================================================================
:EXIT_SCRIPT
cls
echo.
echo Thank you for using SSH Key Generator!
echo.
exit /b
