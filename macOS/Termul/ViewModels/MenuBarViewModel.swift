//
//  MenuBarViewModel.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation
import Combine
import AppKit

/// View model for the menu bar dropdown interface
class MenuBarViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All configured projects
    @Published var projects: [Project] = []

    /// All project groups
    @Published var groups: [ProjectGroup] = []

    /// Indicates if the configuration window should be shown
    @Published var showConfiguration: Bool = false

    /// Indicates if data is being loaded
    @Published var isLoading: Bool = false

    /// Last error that occurred
    @Published var lastError: Error?

    /// Currently running project ID (nil if none)
    @Published var runningProjectId: UUID?

    /// Process status for each project
    @Published var projectStatuses: [UUID: ProcessStatus] = [:]

    /// Git branch information for each project
    @Published var projectGitBranches: [UUID: String] = [:]

    // MARK: - Dependencies

    internal let projectManager: ProjectManager
    private var commandRunners: [UUID: CommandRunner] = [:]
    private var projectOutputs: [UUID: [CommandOutput]] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var memoryMonitor: MemoryMonitor?
    private var projectMemoryHistory: [UUID: [MemoryData]] = [:]
    @Published private var appSettings = AppSettingsManager.shared.settings

    // MARK: - Initialization

    init(projectManager: ProjectManager = ProjectManager()) {
        self.projectManager = projectManager
        self.memoryMonitor = MemoryMonitor(appSettings: AppSettingsManager.shared.settings)
        setupBindings()
        setupSettingsBindings()

        // Fetch git branches for all loaded projects
        fetchAllGitBranches()
    }

    // MARK: - Private Setup

    private func setupBindings() {
        // Subscribe to project manager changes
        projectManager.$projects
            .receive(on: DispatchQueue.main)
            .assign(to: &$projects)

        projectManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        projectManager.$lastError
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastError)

        projectManager.$groups
            .receive(on: DispatchQueue.main)
            .assign(to: &$groups)
    }

    /// Fetches git branch information for all projects
    private func fetchAllGitBranches() {
        for project in projects {
            fetchGitBranch(for: project)
        }
    }

    private func setupSettingsBindings() {
        // Subscribe to app settings changes
        AppSettingsManager.shared.$settings
            .receive(on: DispatchQueue.main)
            .assign(to: &$appSettings)
    }

    // MARK: - Quick Actions

    /// Runs the command for a specified project
    /// - Parameter project: The project to run
    func runProject(_ project: Project) {
        // Check if already running
        guard projectStatuses[project.id]?.isRunning != true else {
            return
        }

        // Stop any existing runner for this project
        commandRunners[project.id]?.stop()

        // Clear previous outputs for this project
        projectOutputs[project.id] = []

        // Create command runner for this project
        let runner = CommandRunner(memoryMonitor: memoryMonitor)

        // Subscribe to status changes
        runner.statusStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateProjectStatus(projectId: project.id, status: status)
            }
            .store(in: &cancellables)

        // Subscribe to output and accumulate it
        runner.outputStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.handleOutput(output, for: project)
            }
            .store(in: &cancellables)

        // Subscribe to memory updates from CommandRunner if memory tracking is enabled
        if appSettings.memoryTrackingEnabled {
            runner.memoryStream
                .receive(on: DispatchQueue.main)
                .sink { [weak self] memoryData in
                    self?.addMemoryData(projectId: project.id, data: memoryData)
                }
                .store(in: &cancellables)
        }

        // Store runner reference per project
        commandRunners[project.id] = runner

        // Run the command with project ID for memory tracking and environment variables
        runner.run(command: project.command, workingDirectory: project.path, projectId: project.id, environmentVariables: project.environmentVariables)

        // Fetch git branch information
        fetchGitBranch(for: project)

        // Mark project as run
        projectManager.markProjectAsRun(projectId: project.id)
    }

    /// Stops the currently running process for a project
    /// - Parameter project: The project to stop
    func stopProject(_ project: Project) {
        guard let status = projectStatuses[project.id], status.isRunning else {
            return
        }

        // Stop memory monitoring
        memoryMonitor?.stopMonitoring(projectId: project.id)

        commandRunners[project.id]?.stop()
        updateProjectStatus(projectId: project.id, status: .stopped(exitCode: nil))
    }

    /// Opens a project in the user's configured IDE
    /// - Parameter project: The project to open
    /// - Returns: true if the IDE was launched successfully, false otherwise
    func openInIDE(_ project: Project) -> Bool {
        let ideCommand = appSettings.ideCommand
        guard !ideCommand.isEmpty else {
            return false
        }

        let runner = CommandRunner()
        return runner.openInIDE(ideCommand: ideCommand, projectPath: project.path)
    }

    /// Opens the environment variables configuration for a project
    /// - Parameter project: The project to configure environment variables for
    func openEnvironmentVariables(_ project: Project) {
        NotificationCenter.default.post(name: .showEnvironmentVariables, object: project)
    }

    /// Shows the delete confirmation dialog (handled by UI layer)
    /// - Parameter project: The project to delete
    func deleteProject(_ project: Project) {
        // Post notification to show delete confirmation window
        NotificationCenter.default.post(name: .showDeleteConfirmation, object: project)
    }

    /// Confirms and performs the project deletion
    /// - Parameter project: The project to delete
    func confirmDeleteProject(_ project: Project) {
        // Check if process is running
        if let status = projectStatuses[project.id], status.isRunning {
            // Stop the process first
            stopProject(project)
        }

        // Delete the project
        _ = projectManager.deleteProject(projectId: project.id)

        // Remove status tracking
        projectStatuses.removeValue(forKey: project.id)

        // Close output viewer if open
        closeOutputViewer(for: project)
    }

    // MARK: - Configuration Management

    /// Opens the configuration window to add a new project
    func openConfiguration() {
        showConfiguration = true
        // Post notification to AppDelegate to open configuration window
        NotificationCenter.default.post(name: .showConfiguration, object: nil)
    }

    /// Opens the port killer window
    func openPortKiller() {
        NotificationCenter.default.post(name: .showPortKiller, object: nil)
    }

    /// Opens the group configuration window
    func openGroupConfiguration() {
        NotificationCenter.default.post(name: .showGroupConfiguration, object: nil)
    }

    /// Opens the settings window
    func openSettings() {
        NotificationCenter.default.post(name: .showSettings, object: nil)
    }

    /// Closes the configuration window
    func closeConfiguration() {
        showConfiguration = false
    }

    /// Moves a project from one position to another (drag-and-drop reorder)
    func moveProject(from source: IndexSet, to destination: Int) {
        projectManager.moveProject(from: source, to: destination)
    }

    /// Moves a group from one position to another (drag-and-drop reorder)
    func moveGroup(from source: IndexSet, to destination: Int) {
        projectManager.moveGroup(from: source, to: destination)
    }

    /// Adds a new project from configuration data
    /// - Parameters:
    ///   - name: Project name
    ///   - path: Project directory path
    ///   - command: Shell command to run
    ///   - description: Optional description
    /// - Returns: true if successful, false otherwise
    func addProject(name: String, path: String, command: String, description: String? = nil) -> Bool {
        let project = Project(
            name: name,
            path: path,
            command: command,
            description: description
        )

        return projectManager.addProject(project)
    }

    /// Updates an existing project
    /// - Parameter project: The updated project
    /// - Returns: true if successful, false otherwise
    func updateProject(_ project: Project) -> Bool {
        return projectManager.updateProject(project)
    }

    // MARK: - Group Actions

    /// Runs all projects in a group
    /// - Parameter group: The group to run
    func runGroup(_ group: ProjectGroup) {
        let groupProjects = projectManager.projects(inGroup: group.id)
        for project in groupProjects {
            runProject(project)
        }
    }

    /// Stops all projects in a group
    /// - Parameter group: The group to stop
    func stopGroup(_ group: ProjectGroup) {
        let groupProjects = projectManager.projects(inGroup: group.id)
        for project in groupProjects {
            stopProject(project)
        }
    }

    /// Checks if any project in a group is running
    /// - Parameter group: The group to check
    /// - Returns: true if at least one project is running
    func isGroupRunning(_ group: ProjectGroup) -> Bool {
        let groupProjects = projectManager.projects(inGroup: group.id)
        return groupProjects.contains { isRunning($0) }
    }

    /// Checks if all projects in a group are running
    /// - Parameter group: The group to check
    /// - Returns: true if all projects are running
    func isGroupFullyRunning(_ group: ProjectGroup) -> Bool {
        let groupProjects = projectManager.projects(inGroup: group.id)
        guard !groupProjects.isEmpty else { return false }
        return groupProjects.allSatisfy { isRunning($0) }
    }

    /// Returns projects in a specific group
    /// - Parameter group: The group
    /// - Returns: Array of projects
    func projects(inGroup group: ProjectGroup) -> [Project] {
        return projectManager.projects(inGroup: group.id)
    }

    /// Returns ungrouped projects
    /// - Returns: Array of projects not in any group
    func ungroupedProjects() -> [Project] {
        return projectManager.ungroupedProjects()
    }

    /// Deletes a group after confirmation
    /// - Parameter group: The group to delete
    func deleteGroup(_ group: ProjectGroup) {
        // Stop all running projects in the group first
        let groupProjects = projectManager.projects(inGroup: group.id)
        for project in groupProjects {
            if isRunning(project) {
                stopProject(project)
            }
        }

        let alert = NSAlert()
        alert.messageText = "Delete Group?"
        alert.informativeText = "Are you sure you want to delete group '\(group.name)'? Projects in this group will not be deleted, only ungrouped."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            projectManager.deleteGroup(groupId: group.id)
        }
    }

    // MARK: - Status Management

    /// Updates the status for a specific project
    /// - Parameters:
    ///   - projectId: The project ID
    ///   - status: The new status
    private func updateProjectStatus(projectId: UUID, status: ProcessStatus) {
        projectStatuses[projectId] = status

        // Update running project ID
        if status.isRunning {
            runningProjectId = projectId
        } else if runningProjectId == projectId {
            runningProjectId = nil
        }
    }

    /// Returns the status for a specific project
    /// - Parameter project: The project to get status for
    /// - Returns: The current process status, defaults to .idle
    func getStatus(for project: Project) -> ProcessStatus {
        projectStatuses[project.id] ?? .idle
    }

    /// Checks if a project is currently running
    /// - Parameter project: The project to check
    /// - Returns: true if running, false otherwise
    func isRunning(_ project: Project) -> Bool {
        getStatus(for: project).isRunning
    }

    // MARK: - Output Viewer Management

    /// Shows the output log viewer for a project
    /// - Parameter project: The project to show logs for
    func showLog(for project: Project) {
        NotificationCenter.default.post(
            name: .showOutputViewer,
            object: project
        )
    }

    /// Closes the output viewer for a project
    /// - Parameter project: The project to close output for
    private func closeOutputViewer(for project: Project) {
        NotificationCenter.default.post(
            name: .closeOutputViewer,
            object: project
        )
    }

    /// Returns the command runner for a project (if any)
    func getCommandRunner(for project: Project) -> CommandRunner? {
        return commandRunners[project.id]
    }

    /// Returns accumulated outputs for a project
    func getOutputs(for project: Project) -> [CommandOutput] {
        return projectOutputs[project.id] ?? []
    }

    /// Returns the last N output lines for a project
    /// - Parameters:
    ///   - project: The project to get outputs for
    ///   - count: Maximum number of lines to return
    /// - Returns: The last N output lines
    func getLastOutputLines(for project: Project, count: Int = 30) -> [CommandOutput] {
        let outputs = projectOutputs[project.id] ?? []
        return Array(outputs.suffix(count))
    }

    /// Handles output from command execution
    /// - Parameters:
    ///   - output: The output entry
    ///   - project: The project that generated the output
    private func handleOutput(_ output: CommandOutput, for project: Project) {
        // Accumulate output for this project
        if projectOutputs[project.id] == nil {
            projectOutputs[project.id] = []
        }
        projectOutputs[project.id]?.append(output)

        // Limit stored outputs to prevent memory issues
        if let count = projectOutputs[project.id]?.count, count > 10000 {
            projectOutputs[project.id]?.removeFirst(count - 10000)
        }

        // Also post to notification center for any open output viewers
        NotificationCenter.default.post(
            name: .commandOutput,
            object: project,
            userInfo: ["output": output]
        )
    }

    // MARK: - Helper Methods

    /// Validates a project path
    /// - Parameter path: The path to validate
    /// - Returns: true if valid and exists, false otherwise
    func validateProjectPath(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Suggests a project name based on the path
    /// - Parameter path: The project path
    /// - Returns: A suggested project name
    func suggestProjectName(from path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    /// Fetches the current git branch for a project
    /// - Parameter project: The project to fetch branch info for
    func fetchGitBranch(for project: Project) {
        let runner = CommandRunner()

        // Fetch git branch on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let branch = runner.fetchGitBranch(projectPath: project.path)

            // Update on main thread
            DispatchQueue.main.async {
                self?.projectGitBranches[project.id] = branch

                // Update project in ProjectManager to persist the branch
                if let index = self?.projectManager.projects.firstIndex(where: { $0.id == project.id }) {
                    self?.projectManager.projects[index].currentGitBranch = branch
                    self?.projectManager.saveProjects()
                }
            }
        }
    }

    // MARK: - Memory Management

    /// Adds memory data for a project
    /// - Parameters:
    ///   - projectId: UUID of the project
    ///   - data: Memory data to add
    private func addMemoryData(projectId: UUID, data: MemoryData) {
        // Initialize array if needed
        if projectMemoryHistory[projectId] == nil {
            projectMemoryHistory[projectId] = []
        }

        projectMemoryHistory[projectId]?.append(data)

        // Limit to max history points
        let maxPoints = appSettings.maxMemoryHistoryPoints
        if let count = projectMemoryHistory[projectId]?.count, count > maxPoints {
            projectMemoryHistory[projectId]?.removeFirst(count - maxPoints)
        }

        // Post notification for OutputViewerViewModel
        NotificationCenter.default.post(
            name: .memoryDataUpdate,
            object: projectId,
            userInfo: ["memoryData": data]
        )
    }

    /// Returns the memory history for a project
    /// - Parameter project: The project
    /// - Returns: Array of memory data points
    func getMemoryHistory(for project: Project) -> [MemoryData] {
        return projectMemoryHistory[project.id] ?? []
    }

    /// Returns the current memory usage for a project
    /// - Parameter project: The project
    /// - Returns: Current memory data, or nil if not available
    func getCurrentMemory(for project: Project) -> MemoryData? {
        return projectMemoryHistory[project.id]?.last
    }

    /// Calculates memory statistics for a project
    /// - Parameter project: The project
    /// - Returns: Memory statistics, or nil if no data available
    func getMemoryStatistics(for project: Project) -> (min: Double, max: Double, avg: Double, trend: MemoryTrend)? {
        guard let history = projectMemoryHistory[project.id], !history.isEmpty else {
            return nil
        }

        let values = history.map { $0.memoryMB }
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let avg = values.reduce(0, +) / Double(values.count)
        let trend = calculateTrend(from: history)

        return (min: min, max: max, avg: avg, trend: trend)
    }

    /// Calculates memory trend from history
    /// - Parameter history: Array of memory data
    /// - Returns: The detected trend
    private func calculateTrend(from history: [MemoryData]) -> MemoryTrend {
        guard history.count >= 10 else { return .stable }

        let recent = history.suffix(10).map { $0.memoryMB }
        let averageFirst = recent.prefix(5).reduce(0, +) / 5.0
        let averageLast = recent.suffix(5).reduce(0, +) / 5.0

        let delta = averageLast - averageFirst

        if delta > 10 { return .increasing }
        if delta < -10 { return .decreasing }
        return .stable
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showOutputViewer = Notification.Name("showOutputViewer")
    static let closeOutputViewer = Notification.Name("closeOutputViewer")
    static let commandOutput = Notification.Name("commandOutput")
    static let showConfiguration = Notification.Name("showConfiguration")
    static let showPortKiller = Notification.Name("showPortKiller")
    static let showGroupConfiguration = Notification.Name("showGroupConfiguration")
    static let showSettings = Notification.Name("showSettings")
    static let showDeleteConfirmation = Notification.Name("showDeleteConfirmation")
    static let memoryDataUpdate = Notification.Name("memoryDataUpdate")
    static let showEnvironmentVariables = Notification.Name("showEnvironmentVariables")
    static let showMainWindow = Notification.Name("showMainWindow")
    static let showOnboarding = Notification.Name("showOnboarding")
}

// MARK: - Status Indicator Helper

extension ProcessStatus {
    /// Returns a system symbol name for the status indicator
    var statusSymbol: String {
        switch self {
        case .idle:
            return "circle.fill"
        case .running:
            return "play.fill"
        case .stopped:
            return "stop.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }

    /// Returns a color name for the status indicator
    var statusColor: String {
        switch self {
        case .idle:
            return "gray"
        case .running:
            return "green"
        case .stopped:
            return "blue"
        case .failed:
            return "red"
        }
    }
}
