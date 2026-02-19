//
//  AppDelegate.swift
//  Termul
//
//  Created by Service Helper
//

import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    /// Status item in the menu bar
    private var statusItem: NSStatusItem?

    /// View model for the menu bar
    private var menuBarViewModel: MenuBarViewModel?

    /// Hosting controller for the menu bar dropdown
    private var popover: NSPopover?

    /// Currently open output viewer windows (keyed by project ID)
    private var outputViewerWindows: [UUID: NSWindow] = [:]

    /// Currently open configuration window
    private var configurationWindow: NSWindow?

    /// Currently open port killer window
    private var portKillerWindow: NSWindow?

    /// Currently open group configuration window
    private var groupConfigurationWindow: NSWindow?

    /// Currently open settings window
    private var settingsWindow: NSWindow?

    /// Currently open delete confirmation window
    private var deleteConfirmationWindow: NSWindow?

    /// Currently open environment variables window
    private var environmentVariablesWindow: NSWindow?

    /// Main dashboard window
    private var mainWindow: NSWindow?

    /// View model for the main window
    private var mainWindowViewModel: MainWindowViewModel?

    /// Onboarding window
    private var onboardingWindow: NSWindow?

    /// Event monitor for detecting clicks outside of popover
    private var eventMonitor: Any?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize view model
        menuBarViewModel = MenuBarViewModel()

        // Setup menu bar item
        setupMenuBar()

        // Subscribe to notifications
        setupNotifications()

        // Check if this is first launch or onboarding hasn't been completed
        let settings = AppSettingsManager.shared.settings
        if !settings.hasCompletedOnboarding {
            // Show onboarding for first-time users
            showOnboarding()
        } else if settings.openMainWindowOnLaunch {
            // Show main window based on user preference
            showMainWindow()
        }

        // Activate the app
        NSApp.setActivationPolicy(.accessory)
    }



    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar apps should NOT quit when all windows close
        return false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Clean up any running processes
        menuBarViewModel?.projects.forEach { project in
            if menuBarViewModel?.isRunning(project) == true {
                menuBarViewModel?.stopProject(project)
            }
        }

        // Close all windows
        outputViewerWindows.values.forEach { $0.close() }
        configurationWindow?.close()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Menu Bar Setup

    private func setupMenuBar() {
        // Create status item with fixed square size
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Load the menu bar icon - try multiple methods for compatibility
            var iconImage: NSImage?

            print("🔍 Debug: Starting icon load process...")
            print("🔍 Debug: button.title before: \(button.title)")
            print("🔍 Debug: button.image before: \(button.image?.size ?? CGSize.zero)")

            // Method 1: Try SPM Bundle.module (for swift run)
            #if SWIFT_PACKAGE
            if #available(macOS 14.0, *) {
                let spmIconPath = Bundle.module.bundlePath + "/Assets.xcassets/MenuBarIcon.imageset/16.png"
                print("🔍 Debug: Trying SPM path: \(spmIconPath)")
                print("🔍 Debug: File exists: \(FileManager.default.fileExists(atPath: spmIconPath))")
                if FileManager.default.fileExists(atPath: spmIconPath) {
                    iconImage = NSImage(contentsOfFile: spmIconPath)
                    if iconImage != nil {
                        print("✅ Debug: Loaded from SPM bundle")
                    }
                }
            }
            #endif

            // Method 2: Try main bundle (for build.sh / .app bundle)
            if iconImage == nil {
                let mainBundleIconPath = Bundle.main.bundlePath + "/Contents/Resources/Assets.xcassets/MenuBarIcon.imageset/16.png"
                print("🔍 Debug: Trying main bundle path: \(mainBundleIconPath)")
                print("🔍 Debug: File exists: \(FileManager.default.fileExists(atPath: mainBundleIconPath))")
                if FileManager.default.fileExists(atPath: mainBundleIconPath) {
                    iconImage = NSImage(contentsOfFile: mainBundleIconPath)
                    if iconImage != nil {
                        print("✅ Debug: Loaded from main bundle")
                    }
                }
            }

            if let img = iconImage {
                // Force image size to menu bar standard
                img.size = NSSize(width: 16, height: 16)
                img.isTemplate = true
                button.image = img
                button.title = ""  // Clear text to ensure icon is visible
                print("✅ Debug: Icon set successfully, title cleared")
            } else {
                // Fallback to text if icon fails to load
                print("❌ Debug: Icon load failed, using text fallback")
                button.title = ">_"
            }

            print("🔍 Debug: button.title after: \(button.title)")
            print("🔍 Debug: button.image after: \(button.image?.size ?? CGSize.zero)")
            button.toolTip = "Termul - Click to open"

            // Add click handler
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    @objc private func statusBarButtonClicked() {
        guard let menuBarViewModel = menuBarViewModel else {
            return
        }

        if popover == nil {
            // Create popover
            popover = NSPopover()
            popover?.contentSize = NSSize(width: 300, height: 500)
            popover?.behavior = .transient
            popover?.animates = true

            // Create SwiftUI view and wrap in hosting controller
            let menuBarView = MenuBarView(viewModel: menuBarViewModel)
            let hostingController = NSHostingController(rootView: menuBarView)
            popover?.contentViewController = hostingController
        }

        // Toggle popover: close if shown, show if hidden
        if let popover = popover, popover.isShown {
            closePopover()
        } else if let button = statusItem?.button, let popover = popover {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Add global event monitor to detect clicks outside the app
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }

            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func closePopover() {
        popover?.close()

        // Properly remove the event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        // Show output viewer notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowOutputViewer(_:)),
            name: .showOutputViewer,
            object: nil
        )

        // Close output viewer notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloseOutputViewer(_:)),
            name: .closeOutputViewer,
            object: nil
        )

        // Show configuration notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowConfiguration),
            name: NSNotification.Name("showConfiguration"),
            object: nil
        )

        // Show port killer notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowPortKiller),
            name: .showPortKiller,
            object: nil
        )

        // Show group configuration notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowGroupConfiguration),
            name: .showGroupConfiguration,
            object: nil
        )

        // Show settings notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowSettings),
            name: .showSettings,
            object: nil
        )

        // Show delete confirmation notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowDeleteConfirmation(_:)),
            name: .showDeleteConfirmation,
            object: nil
        )

        // Show environment variables notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowEnvironmentVariables(_:)),
            name: .showEnvironmentVariables,
            object: nil
        )

        // Show main window notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowMainWindow),
            name: .showMainWindow,
            object: nil
        )

        // Show onboarding notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowOnboarding),
            name: .showOnboarding,
            object: nil
        )

        // Onboarding completed notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOnboardingCompleted),
            name: .onboardingCompleted,
            object: nil
        )
    }

    // MARK: - Output Viewer Management

    @objc private func handleShowOutputViewer(_ notification: Notification) {
        guard let project = notification.object as? Project else {
            return
        }

        // Close the popover so the window is visible
        closePopover()

        // Check if window already exists for this project
        if let existingWindow = outputViewerWindows[project.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Use the existing command runner from the view model, or create a new one
        let commandRunner = menuBarViewModel?.getCommandRunner(for: project) ?? CommandRunner()
        let existingOutputs = menuBarViewModel?.getOutputs(for: project) ?? []

        // Create output viewer view model with the existing runner
        let viewModel = OutputViewerViewModel(project: project, commandRunner: commandRunner)

        // Pre-populate with accumulated outputs
        viewModel.outputs = existingOutputs

        // Sync status from the runner
        viewModel.status = commandRunner.status

        // Create SwiftUI view
        let outputViewerView = OutputViewerView(project: project, viewModel: viewModel)
        let hostingController = NSHostingController(rootView: outputViewerView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "\(project.name) - Output"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("OutputViewer_\(project.id)")
        window.isReleasedWhenClosed = false

        // Set up window delegate to handle window closure
        window.delegate = self

        // Store window reference
        outputViewerWindows[project.id] = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func handleCloseOutputViewer(_ notification: Notification) {
        guard let project = notification.object as? Project else {
            return
        }

        closeOutputViewer(for: project)
    }

    private func closeOutputViewer(for project: Project) {
        if let window = outputViewerWindows[project.id] {
            window.close()
            outputViewerWindows.removeValue(forKey: project.id)
        }
    }

    // MARK: - Configuration Window Management

    @objc private func handleShowConfiguration() {
        // Close the popover so the configuration window is visible
        closePopover()

        guard let menuBarViewModel = menuBarViewModel else {
            return
        }

        // If window already exists, bring it to front
        if let existingWindow = configurationWindow {
            print("Configuration window already exists, bringing to front")
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create configuration view model
        let viewModel = ConfigurationViewModel(projectManager: menuBarViewModel.projectManager)

        // Create SwiftUI view
        let configurationView = ConfigurationView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: configurationView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 650),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Add Project"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("ConfigurationWindow")
        window.isReleasedWhenClosed = false

        // Set up window delegate
        window.delegate = self

        // Store window reference
        configurationWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Port Killer Window Management

    @objc private func handleShowPortKiller() {
        // Close the popover so the window is visible
        closePopover()

        // If window already exists, bring it forward
        if let existingWindow = portKillerWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create port killer view
        let portKillerView = PortKillerView()
        let hostingController = NSHostingController(rootView: portKillerView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Port Killer"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("PortKillerWindow")
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 450, height: 400)

        // Set up window delegate
        window.delegate = self

        // Store window reference
        portKillerWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Delete Confirmation Window Management

    @objc private func handleShowDeleteConfirmation(_ notification: Notification) {
        // Close the popover so the window is visible
        closePopover()

        guard let project = notification.object as? Project,
              let menuBarViewModel = menuBarViewModel else {
            return
        }

        // If window already exists, bring it forward
        if let existingWindow = deleteConfirmationWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create delete confirmation view
        let deleteConfirmationView = DeleteProjectConfirmationView(
            project: project,
            onConfirm: {
                menuBarViewModel.confirmDeleteProject(project)
                self.deleteConfirmationWindow?.close()
            },
            onCancel: {
                self.deleteConfirmationWindow?.close()
            }
        )

        let hostingController = NSHostingController(rootView: deleteConfirmationView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Delete Project"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("DeleteConfirmationWindow")
        window.isReleasedWhenClosed = false

        // Set up window delegate
        window.delegate = self

        // Store window reference
        deleteConfirmationWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Window Delegate

    func windowWillClose(_ notification: Notification) {
        // Check if it's the configuration window
        if configurationWindow == notification.object as? NSWindow {
            configurationWindow = nil
        }

        // Check if it's the group configuration window
        if groupConfigurationWindow == notification.object as? NSWindow {
            groupConfigurationWindow = nil
        }

        // Check if it's the settings window
        if settingsWindow == notification.object as? NSWindow {
            settingsWindow = nil
        }

        // Check if it's the delete confirmation window
        if deleteConfirmationWindow == notification.object as? NSWindow {
            deleteConfirmationWindow = nil
        }

        // Check if it's an output viewer window
        if let window = notification.object as? NSWindow,
           let projectId = outputViewerWindows.first(where: { $0.value == window })?.key {
            outputViewerWindows.removeValue(forKey: projectId)
        }
    }

    // MARK: - Group Configuration Window Management

    @objc private func handleShowGroupConfiguration() {
        // Close the popover so the window is visible
        closePopover()

        guard let menuBarViewModel = menuBarViewModel else {
            return
        }

        // If window already exists, bring it to front
        if let existingWindow = groupConfigurationWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create group configuration view model
        let viewModel = GroupConfigurationViewModel(projectManager: menuBarViewModel.projectManager)

        // Create SwiftUI view
        let groupConfigView = GroupConfigurationView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: groupConfigView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 550),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Manage Groups"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("GroupConfigurationWindow")
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 550, height: 450)

        // Set up window delegate
        window.delegate = self

        // Store window reference
        groupConfigurationWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Settings Window Management

    @objc private func handleShowSettings() {
        // Close the popover so the window is visible
        closePopover()

        // If window already exists, bring it to front
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create settings view with shared settings manager
        let settingsView = SettingsView(settingsManager: AppSettingsManager.shared)
        let hostingController = NSHostingController(rootView: settingsView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Settings"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        window.isReleasedWhenClosed = false

        // Set up window delegate
        window.delegate = self

        // Store window reference
        settingsWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Environment Variables Window Management

    @objc private func handleShowEnvironmentVariables(_ notification: Notification) {
        // Close popover so the window is visible
        closePopover()

        // If window already exists, bring it to front
        if let existingWindow = environmentVariablesWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Get project ID from notification
        guard let projectFromNotification = notification.object as? Project,
              let project = menuBarViewModel?.projectManager.projects.first(where: { $0.id == projectFromNotification.id }) else {
            return
        }

        // Create environment variables view model with fresh project from ProjectManager
        let viewModel = EnvironmentVariablesViewModel(project: project)
        let environmentVariablesView = EnvironmentVariablesView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: environmentVariablesView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Environment Variables - \(project.name)"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("EnvironmentVariablesWindow")
        window.isReleasedWhenClosed = false

        // Set up window delegate
        window.delegate = self

        // Store window reference
        environmentVariablesWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Main Window Management

    @objc private func handleShowMainWindow() {
        // Close the popover so the main window is visible
        closePopover()

        // If window already exists, bring it to front
        if let existingWindow = mainWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create main window view model
        Task { @MainActor in
            mainWindowViewModel = MainWindowViewModel(menuBarViewModel: menuBarViewModel)

        // Create SwiftUI view
        let mainView = MainWindowView(viewModel: mainWindowViewModel!)
        let hostingController = NSHostingController(rootView: mainView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false

        window.title = "Termul - Dashboard"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("MainWindow")
        window.isReleasedWhenClosed = false

        // Set up window delegate
        window.delegate = self

        // Store window reference
        mainWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showMainWindow() {
        handleShowMainWindow()
    }

    // MARK: - Onboarding Window Management

    @objc private func handleShowOnboarding() {
        // Close popover if open
        closePopover()

        // If onboarding already completed, show main window instead
        if AppSettingsManager.shared.settings.hasCompletedOnboarding {
            handleShowMainWindow()
            return
        }

        // If window already exists, bring it to front
        if let existingWindow = onboardingWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create onboarding view model
        // Create SwiftUI view
        let onboardingView = OnboardingView()
        let hostingController = NSHostingController(rootView: onboardingView)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        window.title = "Welcome to Termul"
        window.contentViewController = hostingController

        // Explicitly set window frame to ensure correct size
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 600, height: 400)
        window.setFrame(
            NSRect(
                x: screenFrame.midX - 300,
                y: screenFrame.midY - 200,
                width: 600,
                height: 400
            ),
            display: true,
            animate: false
        )

        window.isReleasedWhenClosed = false

        // Set up window delegate
        window.delegate = self

        // Store window reference
        onboardingWindow = window

        // Show window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showOnboarding() {
        handleShowOnboarding()
    }

    @objc private func handleOnboardingCompleted() {
        // Close onboarding window
        onboardingWindow?.close()
        onboardingWindow = nil

        // Show main window based on user preference
        let settings = AppSettingsManager.shared.settings
        if settings.openMainWindowOnLaunch {
            handleShowMainWindow()
        }
    }

    // MARK: - Cleanup

    deinit {
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)

        // Remove event monitor
        closePopover()
    }
}

// MARK: - NSWindowDelegate Conformance

extension AppDelegate: NSWindowDelegate {}
