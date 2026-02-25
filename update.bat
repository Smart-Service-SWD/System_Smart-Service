@echo off
setlocal enabledelayedexpansion

REM Define variables
set "ROOT_DIR=Smart-Service"
set "CONFIG_FILE=services.conf"

echo Starting Auto Update...

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo Error: Configuration file '%CONFIG_FILE%' not found.
    exit /b 1
)

REM Process Services from Config
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%CONFIG_FILE%") do (
    set "FOLDER_NAME=%%A"
    set "REPO_URL=%%B"
    set "BRANCH=%%C"

    REM Check if line is valid (not comment or empty)
    set "IS_VALID=true"
    if "!FOLDER_NAME!"=="" set "IS_VALID=false"
    if defined FOLDER_NAME (
        echo !FOLDER_NAME! | findstr /b "#" >nul 2>&1 && set "IS_VALID=false"
    )

    if "!IS_VALID!"=="true" (
        set "TARGET_DIR=%ROOT_DIR%\!FOLDER_NAME!"

        echo --------------------------------------------------
        echo Updating Service: !FOLDER_NAME!
        echo   Branch: !BRANCH!

        REM Check if directory exists
        if not exist "!TARGET_DIR!\.git" (
            echo   Error: '!TARGET_DIR!' is not a git repo. Please run setup.bat first.
        ) else (
            pushd "!TARGET_DIR!"

            REM Discard any local changes
            echo   ^> Discarding local changes...
            git checkout -- .
            git clean -fd

            REM Fetch latest
            echo   ^> Fetching from origin...
            git fetch origin

            REM Checkout target branch (main/master)
            echo   ^> Checking out !BRANCH!...
            git checkout "!BRANCH!"

            REM Reset to match remote exactly
            echo   ^> Pulling latest from origin/!BRANCH!...
            git reset --hard "origin/!BRANCH!"

            echo   ^> !FOLDER_NAME! updated successfully.

            popd
        )
    )
)

echo --------------------------------------------------
echo All services updated successfully!
pause
