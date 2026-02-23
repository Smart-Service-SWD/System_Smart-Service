#!/bin/bash
set -e

# Define variables
ROOT_DIR="Smart-Service"
CONFIG_FILE="services.conf"

echo "Starting Auto Update..."

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file '$CONFIG_FILE' not found."
    exit 1
fi

# Process Services from Config
while IFS='|' read -r FOLDER_NAME REPO_URL BRANCH || [ -n "$FOLDER_NAME" ]; do
    # Skip empty lines or comments
    [[ "$FOLDER_NAME" =~ ^#.*$ ]] && continue
    [[ -z "$FOLDER_NAME" ]] && continue

    TARGET_DIR="$ROOT_DIR/$FOLDER_NAME"

    echo "--------------------------------------------------"
    echo "Updating Service: $FOLDER_NAME"
    echo "  Branch: $BRANCH"

    # Check if directory exists
    if [ ! -d "$TARGET_DIR/.git" ]; then
        echo "  Error: '$TARGET_DIR' is not a git repo. Please run setup.sh first."
        continue
    fi

    cd "$TARGET_DIR"

    # Discard any local changes
    echo "  > Discarding local changes..."
    git checkout -- .
    git clean -fd

    # Fetch latest
    echo "  > Fetching from origin..."
    git fetch origin

    # Checkout target branch (main/master)
    echo "  > Checking out $BRANCH..."
    git checkout "$BRANCH"

    # Reset to match remote exactly
    echo "  > Pulling latest from origin/$BRANCH..."
    git reset --hard "origin/$BRANCH"

    echo "  > $FOLDER_NAME updated successfully."

    cd - > /dev/null

done < "$CONFIG_FILE"

echo "--------------------------------------------------"
echo "All services updated successfully!"
