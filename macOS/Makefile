.PHONY: help build app installer run clean uninstall all

# Configuration
APP_NAME = Termul
BUILD_DIR = build
DMG_PATH = $(BUILD_DIR)/$(APP_NAME)-Installer.dmg

# Default target
help:
	@echo "Termul Build System"
	@echo "==================="
	@echo ""
	@echo "Available targets:"
	@echo "  make build        - Build the app (swift build)"
	@echo "  make app          - Build .app bundle"
	@echo "  make installer    - Build macOS disk image (.dmg)"
	@echo "  make run          - Run the app directly"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make uninstall    - Uninstall Termul from /Applications"
	@echo "  make all          - Build app + installer"
	@echo ""
	@echo "Quick start:"
	@echo "  make app && open $(BUILD_DIR)/$(APP_NAME).app"

# Build with swift build
build:
	@echo "Building $(APP_NAME)..."
	swift build

# Build .app bundle
app:
	@echo "Building .app bundle..."
	@chmod +x build.sh
	@./build.sh

# Build installer disk image
installer: app
	@echo "Building macOS disk image installer..."
	@chmod +x build_installer.sh
	@./build_installer.sh

# Run the app directly
run: build
	@echo "Running $(APP_NAME)..."
	swift run Termul

# Run the .app bundle
run-app: app
	@echo "Launching $(APP_NAME).app..."
	@open $(BUILD_DIR)/$(APP_NAME).app

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@swift package clean
	@echo "Clean complete!"

# Uninstall from /Applications
uninstall:
	@echo "Uninstalling $(APP_NAME)..."
	@chmod +x uninstall.sh
	@./uninstall.sh

# Build everything
all: app installer
	@echo ""
	@echo "Build complete!"
	@echo "  App:    $(BUILD_DIR)/$(APP_NAME).app"
	@echo "  Installer: $(DMG_PATH)"
	@echo ""
	@echo "To install:"
	@echo "  open $(DMG_PATH)"
	@echo "  Drag Termul to Applications folder"

# Install the app (shortcut)
install: installer
	@echo "Opening installer for $(APP_NAME)..."
	@open $(DMG_PATH)
