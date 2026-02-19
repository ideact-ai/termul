#!/bin/bash

# Build script for Termul macOS app
# This script compiles the Swift code and packages it into a .app bundle

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Termul"
BUNDLE_ID="com.termul.app"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo -e "${GREEN}Building Termul...${NC}"

# Clean previous build
echo -e "${YELLOW}Cleaning previous build...${NC}"
rm -rf "$BUILD_DIR"

# Create directory structure
echo -e "${YELLOW}Creating app bundle structure...${NC}"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CONTENTS_DIR/Assets.xcassets"

# Compile Swift sources
echo -e "${YELLOW}Compiling Swift sources...${NC}"
swiftc \
    -target arm64-apple-macosx14.0 \
    -o "$MACOS_DIR/$APP_NAME" \
    Termul/main.swift \
    Termul/AppDelegate.swift \
    Termul/Models/EnvironmentVariable.swift \
    Termul/Models/Project.swift \
    Termul/Models/ProjectGroup.swift \
    Termul/Models/ProcessStatus.swift \
    Termul/Models/CommandOutput.swift \
    Termul/Models/MemoryData.swift \
    Termul/Models/AppSettings.swift \
    Termul/Managers/ProjectManager.swift \
    Termul/Managers/CommandRunner.swift \
    Termul/Managers/PortKiller.swift \
    Termul/Managers/MemoryMonitor.swift \
    Termul/ViewModels/MenuBarViewModel.swift \
    Termul/ViewModels/ConfigurationViewModel.swift \
    Termul/ViewModels/OutputViewerViewModel.swift \
    Termul/ViewModels/GroupConfigurationViewModel.swift \
    Termul/Views/MenuBarView.swift \
    Termul/Views/ConfigurationView.swift \
    Termul/Views/OutputViewerView.swift \
    Termul/Views/PortKillerView.swift \
    Termul/Views/MemoryChartView.swift \
    Termul/Views/DeleteProjectConfirmationView.swift \
    Termul/Views/EnvironmentVariablesView.swift \
    Termul/Views/GroupConfigurationView.swift \
    Termul/Views/SettingsView.swift \
    -framework SwiftUI \
    -framework AppKit \
    -framework Combine \
    -framework Foundation

# Copy Info.plist
echo -e "${YELLOW}Copying Info.plist...${NC}"
cp Termul/Info.plist "$CONTENTS_DIR/"

# Copy entitlements (for code signing)
echo -e "${YELLOW}Copying entitlements...${NC}"
cp Termul/Termul.entitlements "$CONTENTS_DIR/"

# Copy resources if they exist
if [ -d "Termul/Resources/Assets.xcassets" ]; then
    echo -e "${YELLOW}Copying resources...${NC}"
    cp -r Termul/Resources/Assets.xcassets "$RESOURCES_DIR/"
fi

# Create PkgInfo
echo -e "${YELLOW}Creating PkgInfo...${NC}"
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# Create app icon from AppIcon files
echo -e "${YELLOW}Creating app icon...${NC}"
if [ -d "Termul/Resources/Assets.xcassets/AppIcon.appiconset" ]; then
    mkdir -p "$RESOURCES_DIR/AppIcon.iconset"

    # Create a temporary directory for converted PNG files
    TEMP_DIR=$(mktemp -d)

    # Convert WebP files to PNG and copy to iconset
    # sips can handle the conversion automatically
    echo -e "${YELLOW}Converting icons to PNG format...${NC}"

    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/16-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_16x16.png" > /dev/null 2>&1
    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/32-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_16x16@2x.png" > /dev/null 2>&1

    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/32-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_32x32.png" > /dev/null 2>&1
    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/64-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_32x32@2x.png" > /dev/null 2>&1

    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/128-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_128x128.png" > /dev/null 2>&1
    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/256-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_128x128@2x.png" > /dev/null 2>&1

    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/256-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_256x256.png" > /dev/null 2>&1
    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/512-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_256x256@2x.png" > /dev/null 2>&1

    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/512-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_512x512.png" > /dev/null 2>&1
    sips -s format png "Termul/Resources/Assets.xcassets/AppIcon.appiconset/1024-mac.png" --out "$RESOURCES_DIR/AppIcon.iconset/icon_512x512@2x.png" > /dev/null 2>&1

    # Convert iconset to .icns
    iconutil -c icns "$RESOURCES_DIR/AppIcon.iconset" -o "$RESOURCES_DIR/AppIcon.icns"

    # Clean up temporary directory and iconset
    rm -rf "$RESOURCES_DIR/AppIcon.iconset"
    rm -rf "$TEMP_DIR"

    echo -e "${GREEN}✓ App icon created${NC}"
else
    echo -e "${YELLOW}Warning: AppIcon.appiconset not found, using default icon${NC}"
fi

# Make executable
echo -e "${YELLOW}Setting executable permissions...${NC}"
chmod +x "$MACOS_DIR/$APP_NAME"

# Optional: Code signing (requires developer certificate)
if [ -n "$CODE_SIGN_IDENTITY" ]; then
    echo -e "${YELLOW}Code signing with identity: $CODE_SIGN_IDENTITY...${NC}"
    codesign --force --deep --sign "$CODE_SIGN_IDENTITY" --entitlements "$CONTENTS_DIR/Termul.entitlements" "$APP_DIR"
else
    echo -e "${YELLOW}Skipping code signing (no CODE_SIGN_IDENTITY set)...${NC}"
fi

# Success!
echo -e "${GREEN}✓ Build successful!${NC}"
echo -e "${GREEN}App location: $APP_DIR${NC}"
echo ""
echo "To run the app:"
echo "  open $APP_DIR"
echo ""
echo "To add to login items:"
echo "  1. Open System Settings → General → Login Items"
echo "  2. Click + and select: $APP_DIR"
