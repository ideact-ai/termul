//
//  MainWindowViewModel.swift
//  Termul
//
//  ViewModel for managing the main dashboard window
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing the main dashboard window
final class MainWindowViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Currently selected project in the dashboard
    @Published var selectedProject: Project?

    /// Search query for filtering projects
    @Published var searchQuery: String = ""

    /// Currently selected filter (all, running, stopped, grouped)
    @Published var selectedFilter: ProjectFilter = .all

    /// Whether to show only projects in a specific group
    @Published var selectedGroupFilter: UUID?

    /// Whether to refresh the dashboard
    @Published var needsRefresh: Bool = false

    /// Dashboard statistics
    @Published var statistics: DashboardStatistics = DashboardStatistics()

    // MARK: - Properties

    /// Reference to the shared menu bar view model
    private weak var menuBarViewModel: MenuBarViewModel?

    /// Project manager reference
    private let projectManager: ProjectManager

    /// App settings reference
    private let settingsManager: AppSettingsManager

    /// Timer for updating statistics
    private var statisticsTimer: Timer?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// All projects filtered based on current search and filters
    var filteredProjects: [Project] {
        var projects = menuBarViewModel?.projects ?? []

        // Apply search filter
        if !searchQuery.isEmpty {
            projects = projects.filter { project in
                project.name.localizedCaseInsensitiveContains(searchQuery) ||
                project.path.localizedCaseInsensitiveContains(searchQuery) ||
                project.command.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .running:
            projects = projects.filter { project in
                menuBarViewModel?.isRunning(project) == true
            }
        case .stopped:
            projects = projects.filter { project in
                menuBarViewModel?.isRunning(project) == false
            }
        }

        // Apply group filter
        if let groupId = selectedGroupFilter {
            projects = projects.filter { $0.groupId == groupId }
        }

        return projects
    }

    /// Projects that are currently running
    var runningProjects: [Project] {
        (menuBarViewModel?.projects ?? [])
            .filter { menuBarViewModel?.isRunning($0) == true }
    }

    /// Projects that are stopped
    var stoppedProjects: [Project] {
        (menuBarViewModel?.projects ?? [])
            .filter { menuBarViewModel?.isRunning($0) == false }
    }

    /// All project groups
    var groups: [ProjectGroup] {
        projectManager.groups
    }

    /// Total number of projects
    var totalProjects: Int {
        menuBarViewModel?.projects.count ?? 0
    }

    /// Number of running projects
    var runningCount: Int {
        runningProjects.count
    }

    /// Number of stopped projects
    var stoppedCount: Int {
        stoppedProjects.count
    }

    // MARK: - Initialization

    /// Creates a new main window view model
    /// - Parameters:
    ///   - menuBarViewModel: The shared menu bar view model
    ///   - projectManager: The project manager instance
    ///   - settingsManager: The app settings manager
    @MainActor
    init(
        menuBarViewModel: MenuBarViewModel? = nil,
        settingsManager: AppSettingsManager = .shared
    ) {
        self.menuBarViewModel = menuBarViewModel
        self.projectManager = ProjectManager()
        self.settingsManager = settingsManager

        // Set up timer for updating statistics
        startStatisticsTimer()

        // Subscribe to menu bar view model changes
        setupSubscriptions()

        // Initial statistics update
        updateStatistics()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to project changes from menu bar view model
        menuBarViewModel?.$projects
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatistics()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Subscribe to settings changes
        settingsManager.$settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func startStatisticsTimer() {
        // Update statistics every 2 seconds
        statisticsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatistics()
            }
        }
    }

    // MARK: - Statistics Management

    private func updateStatistics() {
        let projects = menuBarViewModel?.projects ?? []
        let runningProjects = projects.filter { menuBarViewModel?.isRunning($0) == true }

        // Calculate total memory usage
        var totalMemory: UInt64 = 0
        for project in runningProjects {
            if let memoryData = menuBarViewModel?.getCurrentMemory(for: project) {
                // Convert MB to bytes
                totalMemory += UInt64(memoryData.memoryMB) * 1024 * 1024
            }
        }

        // Update statistics
        statistics = DashboardStatistics(
            totalProjects: projects.count,
            runningProjects: runningProjects.count,
            stoppedProjects: projects.count - runningProjects.count,
            totalMemoryUsage: totalMemory,
            averageMemoryUsage: runningProjects.isEmpty ? 0 : totalMemory / UInt64(runningProjects.count),
            totalGroups: projectManager.groups.count
        )
    }

    // MARK: - Project Actions

    /// Runs a project
    /// - Parameter project: The project to run
    func runProject(_ project: Project) {
        menuBarViewModel?.runProject(project)
        updateStatistics()
    }

    /// Stops a project
    /// - Parameter project: The project to stop
    func stopProject(_ project: Project) {
        menuBarViewModel?.stopProject(project)
        updateStatistics()
    }

    /// Runs all projects in the filtered list
    func runAllProjects() {
        filteredProjects.forEach { project in
            if menuBarViewModel?.isRunning(project) == false {
                menuBarViewModel?.runProject(project)
            }
        }
        updateStatistics()
    }

    /// Stops all running projects
    func stopAllProjects() {
        runningProjects.forEach { project in
            menuBarViewModel?.stopProject(project)
        }
        updateStatistics()
    }

    /// Deletes a project
    /// - Parameter project: The project to delete
    func deleteProject(_ project: Project) {
        // Post notification to show delete confirmation
        NotificationCenter.default.post(
            name: .showDeleteConfirmation,
            object: project
        )
    }

    /// Opens the output viewer for a project
    /// - Parameter project: The project to view output for
    func openOutputViewer(for project: Project) {
        NotificationCenter.default.post(
            name: .showOutputViewer,
            object: project
        )
    }

    /// Opens the configuration view to add a new project
    func openAddProject() {
        NotificationCenter.default.post(
            name: NSNotification.Name("showConfiguration"),
            object: nil
        )
    }

    /// Opens the configuration view to edit a project
    /// - Parameter project: The project to edit
    func editProject(_ project: Project) {
        NotificationCenter.default.post(
            name: NSNotification.Name("showConfiguration"),
            object: project
        )
    }

    /// Opens the group configuration view
    func openGroupConfiguration() {
        NotificationCenter.default.post(
            name: .showGroupConfiguration,
            object: nil
        )
    }

    /// Opens the settings view
    func openSettings() {
        NotificationCenter.default.post(
            name: .showSettings,
            object: nil
        )
    }

    /// Opens the port killer view
    func openPortKiller() {
        NotificationCenter.default.post(
            name: .showPortKiller,
            object: nil
        )
    }

    // MARK: - Filter Management

    /// Sets the project filter
    /// - Parameter filter: The filter to apply
    func setFilter(_ filter: ProjectFilter) {
        selectedFilter = filter
    }

    /// Sets the group filter
    /// - Parameter groupId: The group ID to filter by, or nil to show all
    func setGroupFilter(_ groupId: UUID?) {
        selectedGroupFilter = groupId
    }

    /// Clears all filters
    func clearFilters() {
        selectedFilter = .all
        selectedGroupFilter = nil
        searchQuery = ""
    }

    // MARK: - Quick Actions

    /// Runs all projects in a specific group
    /// - Parameter group: The group whose projects to run
    func runGroup(_ group: ProjectGroup) {
        let groupProjects = (menuBarViewModel?.projects ?? [])
            .filter { $0.groupId == group.id }

        groupProjects.forEach { project in
            if menuBarViewModel?.isRunning(project) == false {
                menuBarViewModel?.runProject(project)
            }
        }
        updateStatistics()
    }

    /// Stops all projects in a specific group
    /// - Parameter group: The group whose projects to stop
    func stopGroup(_ group: ProjectGroup) {
        let groupProjects = (menuBarViewModel?.projects ?? [])
            .filter { $0.groupId == group.id }

        groupProjects.forEach { project in
            if menuBarViewModel?.isRunning(project) == true {
                menuBarViewModel?.stopProject(project)
            }
        }
        updateStatistics()
    }

    /// Opens a project in the configured IDE
    /// - Parameter project: The project to open
    func openInIDE(_ project: Project) {
        let ideCommand = settingsManager.settings.ideCommand
        guard !ideCommand.isEmpty else {
            return
        }

        let runner = CommandRunner()
        _ = runner.openInIDE(ideCommand: ideCommand, projectPath: project.path)
    }

    /// Opens environment variables configuration for a project
    /// - Parameter project: The project to configure environment variables for
    func openEnvironmentVariables(_ project: Project) {
        NotificationCenter.default.post(name: .showEnvironmentVariables, object: project)
    }

    /// Deletes a group
    /// - Parameter groupId: The group ID to delete
    func deleteGroup(groupId: UUID) {
        projectManager.deleteGroup(groupId: groupId)
        objectWillChange.send()
    }

    /// Opens add group view
    func openAddGroup() {
        NotificationCenter.default.post(
            name: .showGroupConfiguration,
            object: nil
        )
    }

    // MARK: - Memory Management

    /// Gets memory data for a specific project
    /// - Parameter project: The project to get memory data for
    /// - Returns: The memory data array for the project
    func getMemoryData(for project: Project) -> [MemoryData] {
        return menuBarViewModel?.getMemoryHistory(for: project) ?? []
    }

    /// Gets current memory usage for a specific project
    /// - Parameter project: The project to get memory usage for
    /// - Returns: The current memory usage in bytes, or nil if not available
    func getCurrentMemoryUsage(for project: Project) -> Int64? {
        guard let memoryData = menuBarViewModel?.getCurrentMemory(for: project) else {
            return nil
        }
        // Convert MB to bytes
        return Int64(memoryData.memoryMB * 1024 * 1024)
    }

    // MARK: - Git Branch

    /// Gets current git branch for a project
    /// - Parameter project: The project to get the branch for
    /// - Returns: The branch name, or nil if not available
    func getGitBranch(for project: Project) -> String? {
        return menuBarViewModel?.projectGitBranches[project.id]
    }

    /// Gets the group name for a project
    /// - Parameter project: The project to get the group for
    /// - Returns: The group name, or nil if not in a group
    func groupName(for project: Project) -> String? {
        guard let groupId = project.groupId,
              let group = groups.first(where: { $0.id == groupId }) else {
            return nil
        }
        return group.name
    }

    /// Gets the number of projects in a group
    /// - Parameter groupId: The group ID
    /// - Returns: The number of projects in the group
    func projectCount(for groupId: UUID) -> Int {
        return (menuBarViewModel?.projects ?? []).filter { $0.groupId == groupId }.count
    }

    /// Gets the number of running projects in a group
    /// - Parameter groupId: The group ID
    /// - Returns: The number of running projects in the group
    func runningCount(for groupId: UUID) -> Int {
        let groupProjects = (menuBarViewModel?.projects ?? []).filter { $0.groupId == groupId }
        return groupProjects.filter { project in
            menuBarViewModel?.isRunning(project) == true
        }.count
    }

    // MARK: - Process Status

    /// Gets the status of a project's process
    /// - Parameter project: The project to check
    /// - Returns: The process status
    func getProjectStatus(_ project: Project) -> ProcessStatus {
        return menuBarViewModel?.getStatus(for: project) ?? .stopped(exitCode: nil)
    }

    // MARK: - Cleanup

    deinit {
        statisticsTimer?.invalidate()
        statisticsTimer = nil
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

/// Filter options for the project list
enum ProjectFilter: String, CaseIterable {
    case all = "All"
    case running = "Running"
    case stopped = "Stopped"

    var displayName: String {
        return rawValue
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .running: return "play.fill"
        case .stopped: return "stop.fill"
        }
    }
}

/// Dashboard statistics
struct DashboardStatistics {
    /// Total number of projects
    var totalProjects: Int = 0

    /// Number of running projects
    var runningProjects: Int = 0

    /// Number of stopped projects
    var stoppedProjects: Int = 0

    /// Total memory usage across all running projects (in bytes)
    var totalMemoryUsage: UInt64 = 0

    /// Average memory usage (in bytes)
    var averageMemoryUsage: UInt64 = 0

    /// Total number of groups
    var totalGroups: Int = 0
}
