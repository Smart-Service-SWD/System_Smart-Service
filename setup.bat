@echo off
setlocal enabledelayedexpansion

REM Define variables
set "ROOT_DIR=Smart-Service"
set "CONFIG_FILE=services.conf"

echo Starting System Service Setup...

REM 1. Create Root Directory
echo Creating root directory...
if not exist "%ROOT_DIR%" mkdir "%ROOT_DIR%"

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo Error: Configuration file '%CONFIG_FILE%' not found.
    exit /b 1
)

REM 2. Process Services from Config
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%CONFIG_FILE%") do (
    set "FOLDER_NAME=%%A"
    set "REPO_URL=%%B"
    set "BRANCH=%%C"

    REM Skip comments
    echo !FOLDER_NAME! | findstr /b "#" >nul 2>&1 && goto :continue
    REM Skip empty lines
    if "!FOLDER_NAME!"=="" goto :continue

    set "TARGET_DIR=%ROOT_DIR%\!FOLDER_NAME!"

    echo --------------------------------------------------
    echo Processing Service: !FOLDER_NAME!
    echo   Repo: !REPO_URL!
    echo   Branch: !BRANCH!

    REM Create directory if it doesn't exist
    if not exist "!TARGET_DIR!" (
        echo   ^> Creating directory !TARGET_DIR!...
        mkdir "!TARGET_DIR!"
    )

    pushd "!TARGET_DIR!"

    REM Initialize git if not already a repo
    if not exist ".git" (
        echo   ^> Initializing git...
        git init
    )

    REM Add or update remote
    git remote | findstr /b "origin" >nul 2>&1
    if !errorlevel! neq 0 (
        echo   ^> Adding remote origin...
        git remote add origin "!REPO_URL!"
    ) else (
        echo   ^> Remote origin exists. Updating URL...
        git remote set-url origin "!REPO_URL!"
    )

    REM Fetch
    echo   ^> Fetching from origin...
    git fetch origin

    REM Checkout and Pull
    echo   ^> Checking out !BRANCH!...
    git checkout "!BRANCH!"

    echo   ^> Pulling latest changes...
    git pull origin "!BRANCH!"

    popd

    REM 3. Build
    call :build_project "!TARGET_DIR!" "!FOLDER_NAME!"

    :continue
)

echo --------------------------------------------------
echo Setup and Build completed successfully!
goto :eof

REM ============================================================
REM Function: build_project
REM ============================================================
:build_project
    set "BUILD_DIR=%~1"
    set "BUILD_NAME=%~2"

    echo   ^> Building %BUILD_NAME% in %BUILD_DIR%...
    pushd "%BUILD_DIR%"

    REM Check for .NET project
    if exist "*.csproj" goto :dotnet_build
    if exist "*.sln" goto :dotnet_build

    REM Check for Node project
    if exist "package.json" goto :node_build

    echo     Unknown project type. Skipping build for %BUILD_NAME%.
    goto :build_done

    :dotnet_build
        echo     Detected .NET project.
        echo     Restoring dependencies...
        dotnet restore
        if !errorlevel! neq 0 (
            echo     Error: dotnet restore failed!
            popd
            exit /b 1
        )
        echo     Building...
        dotnet build
        if !errorlevel! neq 0 (
            echo     Error: dotnet build failed!
            popd
            exit /b 1
        )
        goto :build_done

    :node_build
        echo     Detected Node.js project.
        echo     Installing dependencies...
        call npm install
        if !errorlevel! neq 0 (
            echo     Error: npm install failed!
            popd
            exit /b 1
        )

        REM Check if build script exists in package.json
        findstr /c:"\"build\":" package.json >nul 2>&1
        if !errorlevel! equ 0 (
            echo     Building...
            call npm run build
            if !errorlevel! neq 0 (
                echo     Error: npm run build failed!
                popd
                exit /b 1
            )
        ) else (
            echo     No 'build' script found in package.json. Skipping build step.
        )
        goto :build_done

    :build_done
        echo   ^> Finished building %BUILD_NAME%.
        popd
        goto :eof
