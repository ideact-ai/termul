#!/bin/bash

# Uninstaller script for Termul
# This script removes Termul and all associated files from your system

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Termul"
BUNDLE_ID="com.termul.app"
APP_PATH="/Applications/$APP_NAME.app"
CONTAINER_PATH="$HOME/Library/Containers/$BUNDLE_ID"
PREFS_PATH="$HOME/Library/Preferences/$BUNDLE_ID.plist"
CACHES_PATH="$HOME/Library/Caches/$BUNDLE_ID"
SAVED_STATE_PATH="$HOME/Library/Saved Application State/$BUNDLE_ID.savedState"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Termul Uninstaller${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}This will remove Termul and all its data from your Mac.${NC}"
echo ""
echo -e "The following will be removed:"
echo -e "  • ${BLUE}$APP_PATH${NC}"
echo -e "  • ${BLUE}$CONTAINER_PATH${NC}"
echo -e "  • ${BLUE}$PREFS_PATH${NC}"
echo -e "  • ${BLUE}$CACHES_PATH${NC}"
echo -e "  • ${BLUE}$SAVED_STATE_PATH${NC}"
echo ""
echo -e "${RED}⚠️  WARNING: This action cannot be undone!${NC}"
echo ""

# Ask for confirmation
read -p "Are you sure you want to uninstall Termul? (yes/no): " confirm

if [[ "$confirm" != "yes" && "$confirm" != "y" ]]; then
    echo -e "${YELLOW}Uninstall cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting uninstallation...${NC}"
echo ""

# Function to safely remove a file/directory
safe_remove() {
    local path="$1"
    local description="$2"

    if [ -e "$path" ]; then
        echo -e "  Removing $description..."
        rm -rf "$path"
        echo -e "  ${GREEN}✓ Removed${NC}"
    else
        echo -e "  ${BLUE}⊘ Not found (skipping)${NC}: $path"
    fi
    echo ""
}

# Remove the app bundle
safe_remove "$APP_PATH" "Application"

# Remove container (app data and configs)
safe_remove "$CONTAINER_PATH" "Application data and configurations"

# Remove preferences
safe_remove "$PREFS_PATH" "Preferences"

# Remove caches
safe_remove "$CACHES_PATH" "Cache files"

# Remove saved state
safe_remove "$SAVED_STATE_PATH" "Saved application state"

# Check for and remove any running instances
echo -e "Checking for running processes..."
if pgrep -f "$APP_NAME" > /dev/null; then
    echo -e "  ${YELLOW}Found running Termul process${NC}"
    echo -e "  Attempting to quit..."
    pkill -f "$APP_NAME" || true
    sleep 2

    if pgrep -f "$APP_NAME" > /dev/null; then
        echo -e "  ${RED}Process still running. Please quit Termul manually and run this script again.${NC}"
        exit 1
    else
        echo -e "  ${GREEN}✓ Process terminated${NC}"
    fi
else
    echo -e "  ${BLUE}⊘ No running processes found${NC}"
fi
echo ""

# Check if running in login items
echo -e "Checking Login Items..."
if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q "$APP_NAME"; then
    echo -e "  ${YELLOW}Termul is in Login Items${NC}"
    echo -e "  ${YELLOW}Please remove it manually:${NC}"
    echo -e "    System Settings → General → Login Items → Remove Termul"
else
    echo -e "  ${BLUE}⊘ Not in Login Items${NC}"
fi
echo ""

# Success message
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Uninstallation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Termul has been successfully removed from your system."
echo ""
echo -e "${BLUE}Note:${NC} If you had Termul in your Login Items, please remove it manually:"
echo -e "  System Settings → General → Login Items"
echo ""

exit 0
