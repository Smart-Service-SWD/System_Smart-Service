# Check for WSL
if (Get-Command "wsl.exe" -ErrorAction SilentlyContinue) {
    Write-Host "WSL detected. Running setup.sh in WSL..."
    wsl ./setup.sh
    exit
}

# Check for Git Bash
if (Get-Command "bash.exe" -ErrorAction SilentlyContinue) {
    Write-Host "Git Bash detected. Running setup.sh in Git Bash..."
    bash ./setup.sh
    exit
}

# Neither found
Write-Error "Error: Neither WSL nor Git Bash found. Please install one of them to run the setup script."
exit 1
