Param()

$ErrorActionPreference = "Stop"

$rootDir = "Smart-Service"
$configFile = "services.conf"

Write-Host "Starting System Service Setup (PowerShell)..."

# 1. Create Root Directory
if (-not (Test-Path $rootDir)) {
    Write-Host "Creating root directory..."
    New-Item -ItemType Directory -Path $rootDir | Out-Null
} else {
    Write-Host "Root directory '$rootDir' already exists."
}

# Check if config file exists
if (-not (Test-Path $configFile)) {
    Write-Error "Error: Configuration file '$configFile' not found."
    exit 1
}

function Build-Project {
    param(
        [string]$Dir,
        [string]$Name
    )

    Write-Host "  > Building $Name in $Dir..."
    Push-Location $Dir
    try {
        # Check for .NET project
        $hasCsproj = (Get-ChildItem -Filter *.csproj -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
        $hasSln = (Get-ChildItem -Filter *.sln -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0

        if ($hasCsproj -or $hasSln) {
            Write-Host "    Detected .NET project."
            Write-Host "    Restoring dependencies..."
            dotnet restore
            Write-Host "    Building..."
            dotnet build
        }
        elseif (Test-Path "package.json") {
            Write-Host "    Detected Node.js project."
            Write-Host "    Installing dependencies..."
            npm ci

            $packageJson = Get-Content "package.json" -Raw
            if ($packageJson -match '"build"\s*:') {
                Write-Host "    Building..."
                npm run build
            }
            else {
                Write-Host "    No 'build' script found in package.json. Skipping build step."
            }
        }
        else {
            Write-Host "    Unknown project type. Skipping build for $Name."
        }
    }
    finally {
        Pop-Location
    }

    Write-Host "  > Finished building $Name."
}

# 2. Process Services from Config
Get-Content $configFile | ForEach-Object {
    $line = $_.Trim()

    # Skip empty lines or comments
    if (-not $line) { return }
    if ($line.StartsWith("#")) { return }

    $parts = $line.Split("|")
    if ($parts.Count -lt 3) { return }

    $folderName = $parts[0]
    $repoUrl = $parts[1]
    $branch = $parts[2]

    $targetDir = Join-Path $rootDir $folderName

    Write-Host "--------------------------------------------------"
    Write-Host "Processing Service: $folderName"
    Write-Host "  Repo: $repoUrl"
    Write-Host "  Branch: $branch"

    # Create directory if it doesn't exist
    if (-not (Test-Path $targetDir)) {
        Write-Host "  > Creating directory $targetDir..."
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    Push-Location $targetDir
    try {
        # Initialize git if not already a repo
        if (-not (Test-Path ".git")) {
            Write-Host "  > Initializing git..."
            git init
        }

        # Add or update remote
        $hasOrigin = git remote | Select-String -Pattern "^origin$" -Quiet
        if (-not $hasOrigin) {
            Write-Host "  > Adding remote origin..."
            git remote add origin $repoUrl
        }
        else {
            Write-Host "  > Remote origin exists. Updating URL..."
            git remote set-url origin $repoUrl
        }

        # Fetch
        Write-Host "  > Fetching from origin..."
        git fetch origin

        # Checkout and Pull
        Write-Host "  > Checking out $branch..."
        git checkout $branch

        Write-Host "  > Pulling latest changes..."
        git pull origin $branch
    }
    finally {
        Pop-Location
    }

    # 3. Build
    Build-Project -Dir $targetDir -Name $folderName
}

Write-Host "--------------------------------------------------"
Write-Host "Setup and Build completed successfully!"
