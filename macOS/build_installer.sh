#!/bin/bash

# Build script for Termul macOS DMG Installer
# This script creates a drag-and-drop disk image (.dmg) for easy installation

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
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/${APP_NAME}-Installer.dmg"
TEMP_DMG="$BUILD_DIR/temp.dmg"
DMG_VOLUME_NAME="Install Termul"
DMG_SIZE="100m"  # Size of the DMG
VERSION="1.0.0"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Building macOS DMG Installer for Termul${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for Xcode Command Line Tools
echo -e "${YELLOW}Checking for Xcode Command Line Tools...${NC}"
if command -v SetFile >/dev/null 2>&1; then
    echo -e "${GREEN}✓ SetFile found (volume icon will be set)${NC}"
    HAS_SETFILE=true
else
    echo -e "${YELLOW}SetFile not found (install Xcode Command Line Tools for volume icon support)${NC}"
    echo -e "${YELLOW}Install with: xcode-select --install${NC}"
    HAS_SETFILE=false
fi
echo ""

# Step 1: Check if .app bundle exists
if [ ! -d "$APP_DIR" ]; then
    echo -e "${YELLOW}.app bundle not found. Building it first...${NC}"
    chmod +x build.sh
    ./build.sh
fi

if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}Error: Failed to build .app bundle${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found .app bundle${NC}"
echo ""

# Step 2: Create temporary directory for DMG contents
DMG_TEMP=$(mktemp -d)
echo -e "${YELLOW}Preparing DMG contents...${NC}"

# Copy the app to the temp directory
cp -R "$APP_DIR" "$DMG_TEMP/$APP_NAME.app"

# Create symbolic link to /Applications
ln -s /Applications "$DMG_TEMP/Applications"

echo -e "${GREEN}✓ DMG contents prepared${NC}"
echo ""

# Step 3: Create a temporary sparse image
echo -e "${YELLOW}Creating temporary disk image...${NC}"
hdiutil create -srcfolder "$DMG_TEMP" \
    -volname "$DMG_VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "$DMG_SIZE" \
    "$TEMP_DMG" >/dev/null

echo -e "${GREEN}✓ Temporary disk image created${NC}"
echo ""

# Step 4: Mount the temporary image
echo -e "${YELLOW}Mounting disk image...${NC}"
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG")
DEVICE=$(echo "$ATTACH_OUTPUT" | grep -E '^/dev/' | head -1 | awk '{print $1}')
MOUNT_POINT=$(echo "$ATTACH_OUTPUT" | grep 'Apple_HFS' | awk '{for (i=3; i<=NF; i++) printf "%s", $i (i<NF?" ":"\n")}')

# Verify mount point was captured
if [ -z "$MOUNT_POINT" ]; then
    echo -e "${RED}Error: Failed to capture mount point${NC}"
    echo -e "${YELLOW}hdiutil output:${NC}"
    echo "$ATTACH_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✓ Mounted at $MOUNT_POINT${NC}"
echo ""

# Step 5: Set up DMG volume icon
echo -e "${YELLOW}Setting up DMG volume icon...${NC}"

# Copy the app icon to use as volume icon
cp "$APP_DIR/Contents/Resources/AppIcon.icns" "$MOUNT_POINT/.VolumeIcon.icns"

# Use SetFile to make it the volume icon if available
if [ "$HAS_SETFILE" = true ]; then
    SetFile -a C "$MOUNT_POINT"
    # Make the .VolumeIcon.icns file invisible
    SetFile -a V "$MOUNT_POINT/.VolumeIcon.icns"
    echo -e "${GREEN}✓ DMG volume icon set using SetFile${NC}"
else
    echo -e "${YELLOW}Using AppleScript fallback for volume icon...${NC}"
    # Fallback: Use AppleScript to set the volume icon
    osascript <<EOF 2>/dev/null || echo -e "${YELLOW}Could not set volume icon via AppleScript${NC}"
tell application "Finder"
    try
        set theIcon to (POSIX file "$APP_DIR/Contents/Resources/AppIcon.icns") as alias
        set icon of disk "$VOLUME_NAME" to theIcon
    end try
end tell
EOF
    echo -e "${GREEN}✓ DMG volume icon set using AppleScript${NC}"
fi
echo ""

# Step 6: Set up DMG window
echo -e "${YELLOW}Setting up DMG window...${NC}"

# Set icon positions using AppleScript with error handling
VOLUME_NAME="$DMG_VOLUME_NAME"
APP_NAME_VAL="$APP_NAME"
osascript <<EOF || echo -e "${YELLOW}Warning: Could not set window positions (non-critical)${NC}"
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set the bounds of container window to {400, 100, 880, 400}
        set the bounds of container window to {400, 100, 880, 400}

        try
            set position of item "$APP_NAME_VAL.app" to {120, 180}
        end try

        try
            set position of item "Applications" to {360, 180}
        end try

        close
        open
        update without registering applications
        delay 1
    end tell
end tell
EOF

echo -e "${GREEN}✓ DMG window set up${NC}"
echo ""

# Step 7: Unmount the temporary image
echo -e "${YELLOW}Unmounting temporary image...${NC}"
hdiutil detach "$DEVICE" -force >/dev/null || true

echo -e "${GREEN}✓ Unmounted${NC}"
echo ""

# Step 8: Compress the DMG
echo -e "${YELLOW}Compressing DMG...${NC}"
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH" >/dev/null

echo -e "${GREEN}✓ DMG compressed${NC}"
echo ""

# Step 9: Clean up
echo -e "${YELLOW}Cleaning up...${NC}"
rm -rf "$DMG_TEMP"
rm -f "$TEMP_DMG"

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Step 10: Code signing (optional)
if [ -n "$CODE_SIGN_IDENTITY" ]; then
    echo -e "${YELLOW}Code signing DMG with: $CODE_SIGN_IDENTITY${NC}"
    codesign --force --sign "$CODE_SIGN_IDENTITY" "$DMG_PATH"
    echo -e "${GREEN}✓ DMG signed${NC}"
    echo ""
fi

# Step 11: Display results
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}DMG Installer Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "DMG Path: ${BLUE}$DMG_PATH${NC}"
echo -e "Size:     ${BLUE}$DMG_SIZE${NC}"
echo -e "Version:  ${BLUE}$VERSION${NC}"
echo ""
echo -e "To install Termul:"
echo -e "  ${YELLOW}1. Open the DMG: open $DMG_PATH${NC}"
echo -e "  ${YELLOW}2. Drag $APP_NAME.app to Applications folder${NC}"
echo -e "  ${YELLOW}3. Launch from Applications${NC}"
echo ""
echo -e "To distribute:"
echo -e "  ${YELLOW}Share the $DMG_PATH file${NC}"
echo ""
echo -e "To verify:"
echo -e "  ${YELLOW}hdiutil imageinfo $DMG_PATH${NC}"
echo ""

exit 0
