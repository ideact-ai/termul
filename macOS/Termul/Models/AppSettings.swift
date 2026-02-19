//
//  AppSettings.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// App mode preference enum
enum AppMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case menuBarOnly = "menu_bar_only"
    case mainWindowOnly = "main_window_only"
    case both = "both"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .menuBarOnly: return "Menu Bar Only"
        case .mainWindowOnly: return "Main Window Only"
        case .both: return "Both (Default)"
        }
    }
}

/// Application-wide settings persisted in UserDefaults
struct AppSettings: Codable {
    /// Whether memory tracking is enabled for all projects
    var memoryTrackingEnabled: Bool

    /// Whether to show memory charts in the output viewer
    var showMemoryChart: Bool

    /// Memory tracking polling interval in seconds
    var memoryTrackingInterval: Double

    /// Whether the user has completed the onboarding experience
    var hasCompletedOnboarding: Bool

    /// Preferred app mode (menu bar only, main window, or both)
    var preferredAppMode: AppMode

    /// Whether to open the main window on app launch
    var openMainWindowOnLaunch: Bool

    /// Maximum number of memory data points to keep per project
    var maxMemoryHistoryPoints: Int

    /// Command to open projects in IDE (e.g., "cursor", "zeditor", "code")
    var ideCommand: String

    /// Default settings
    static let `default` = AppSettings(
        memoryTrackingEnabled: true,
        showMemoryChart: true,
        memoryTrackingInterval: 2.0,
        maxMemoryHistoryPoints: 300,
        ideCommand: "",
        hasCompletedOnboarding: false,
        preferredAppMode: .both,
        openMainWindowOnLaunch: true
    )

    /// UserDefaults key for storing settings
    private static let userDefaultsKey = "service_helper_app_settings"

    /// Creates a new settings instance
    /// - Parameters:
    ///   - memoryTrackingEnabled: Whether memory tracking is enabled
    ///   - showMemoryChart: Whether to show memory charts
    ///   - memoryTrackingInterval: Polling interval in seconds
    ///   - maxMemoryHistoryPoints: Maximum history points to keep
    ///   - ideCommand: Command to open projects in IDE
    init(
        memoryTrackingEnabled: Bool = true,
        showMemoryChart: Bool = true,
        memoryTrackingInterval: Double = 2.0,
        maxMemoryHistoryPoints: Int = 300,
        ideCommand: String = "",
        hasCompletedOnboarding: Bool = false,
        preferredAppMode: AppMode = .both,
        openMainWindowOnLaunch: Bool = true
    ) {
        self.memoryTrackingEnabled = memoryTrackingEnabled
        self.showMemoryChart = showMemoryChart
        self.memoryTrackingInterval = memoryTrackingInterval
        self.maxMemoryHistoryPoints = maxMemoryHistoryPoints
        self.ideCommand = ideCommand
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.preferredAppMode = preferredAppMode
        self.openMainWindowOnLaunch = openMainWindowOnLaunch
    }

    /// Saves the current settings to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    /// Loads settings from UserDefaults, returning defaults if not found
    /// - Returns: The loaded settings or defaults
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return `default`
        }
        return decoded
    }

    /// Shared instance for convenient access
    static var shared: AppSettings {
        get {
            load()
        }
        set {
            newValue.save()
        }
    }

    /// Updates a setting and saves to UserDefaults
    /// - Parameter update: A closure that modifies the settings
    mutating func update(_ update: (inout AppSettings) -> Void) {
        update(&self)
        save()
    }

    /// Validates the settings and returns corrected values
    /// - Returns: A valid settings instance
    func validated() -> AppSettings {
        var validated = self

        // Ensure memory tracking interval is reasonable (1-10 seconds)
        validated.memoryTrackingInterval = max(1.0, min(10.0, memoryTrackingInterval))

        // Ensure max history points is reasonable (50-1000)
        validated.maxMemoryHistoryPoints = max(50, min(1000, maxMemoryHistoryPoints))

        return validated
    }
}

// MARK: - ObservableObject Wrapper

import Combine

/// Observable wrapper for AppSettings to enable SwiftUI binding
final class AppSettingsManager: ObservableObject {
    @Published var settings: AppSettings

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "service_helper_app_settings"
    private var cancellables = Set<AnyCancellable>()

    /// Shared instance
    static let shared = AppSettingsManager()

    private init() {
        self.settings = AppSettings.load().validated()

        // Listen for UserDefaults changes from other app instances
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.settings = AppSettings.load().validated()
            }
            .store(in: &cancellables)
    }

    /// Updates a specific setting
    /// - Parameter update: A closure that modifies the settings
    func update(_ update: (inout AppSettings) -> Void) {
        var newSettings = settings
        update(&newSettings)
        settings = newSettings.validated()
        settings.save()
    }

    /// Resets all settings to defaults
    func resetToDefaults() {
        settings = .default
        settings.save()
    }
}
