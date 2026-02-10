#!/bin/bash
set -e

# Define variables
ROOT_DIR="Smart-Service"
CONFIG_FILE="services.conf"

echo "Starting System Service Setup..."

# 1. Create Root Directory
echo "Creating root directory..."
mkdir -p "$ROOT_DIR"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

# Function to detect and build
build_project() {
    local dir=$1
    local name=$2
    
    echo "  > Building $name in $dir..."
    cd "$dir"

    # Check for .NET project
    if ls *.csproj 1> /dev/null 2>&1 || ls *.sln 1> /dev/null 2>&1; then
        echo "    Detected .NET project."
        echo "    Restoring dependencies..."
        dotnet restore
        echo "    Building..."
        dotnet build
    # Check for Node project
    elif [ -f "package.json" ]; then
        echo "    Detected Node.js project."
        echo "    Installing dependencies..."
        npm install
        
        # Check if build script exists
        if grep -q '"build":' package.json; then
            echo "    Building..."
            npm run build
        else
            echo "    No 'build' script found in package.json. Skipping build step."
        fi
    else
        echo "    Unknown project type. Skipping build for $name."
    fi

    echo "  > Finished building $name."
    cd - > /dev/null
}

# 2. Process Services from Config
while IFS='|' read -r FOLDER_NAME REPO_URL BRANCH || [ -n "$FOLDER_NAME" ]; do
    # Skip empty lines or comments
    [[ "$FOLDER_NAME" =~ ^#.*$ ]] && continue
    [[ -z "$FOLDER_NAME" ]] && continue

    TARGET_DIR="$ROOT_DIR/$FOLDER_NAME"
    echo "--------------------------------------------------"
    echo "Processing Service: $FOLDER_NAME"
    echo "  Repo: $REPO_URL"
    echo "  Branch: $BRANCH"

    # Create directory if it doesn't exist
    if [ ! -d "$TARGET_DIR" ]; then
        echo "  > Creating directory $TARGET_DIR..."
        mkdir -p "$TARGET_DIR"
    fi

    cd "$TARGET_DIR"

    # Initialize git if not already a repo
    if [ ! -d ".git" ]; then
        echo "  > Initializing git..."
        git init
    fi

    # Add or update remote
    if ! git remote | grep -q "^origin$"; then
        echo "  > Adding remote origin..."
        git remote add origin "$REPO_URL"
    else
        echo "  > Remote origin exists. Updating URL..."
        git remote set-url origin "$REPO_URL"
    fi

    # Fetch
    echo "  > Fetching from origin..."
    git fetch origin

    # Checkout and Pull
    echo "  > Checking out $BRANCH..."
    git checkout "$BRANCH"
    
    echo "  > Pulling latest changes..."
    git pull origin "$BRANCH"

    cd - > /dev/null

    # 3. Build
    build_project "$TARGET_DIR" "$FOLDER_NAME"

done < "$CONFIG_FILE"

echo "--------------------------------------------------"
echo "Setup and Build completed successfully!"
