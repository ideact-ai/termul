//
//  ConfigurationViewModel.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

/// View model for the project configuration form
/// Handles form validation, project creation/updates, and path selection
class ConfigurationViewModel: ObservableObject {
    // MARK: - Published Properties - Form Fields

    /// Project name input
    @Published var projectName: String = ""

    /// Project directory path input
    @Published var projectPath: String = ""

    /// Shell command to execute input
    @Published var command: String = ""

    /// Optional project description input
    @Published var description: String = ""

    /// Selected group ID (nil = no group)
    @Published var selectedGroupId: UUID?

    /// Name for creating a new group inline
    @Published var newGroupName: String = ""

    /// Color for the new inline group
    @Published var newGroupColor: GroupColor = .blue

    /// Whether the "create new group" inline form is shown
    @Published var showNewGroupField: Bool = false

    /// Available groups for selection
    @Published var availableGroups: [ProjectGroup] = []

    /// Error for new group name field
    @Published var newGroupError: String?

    /// Environment variables for the project
    @Published var environmentVariables: [EnvironmentVariable] = []


    // MARK: - Published Properties - Validation State

    /// Indicates if the form is valid and can be submitted
    @Published var isValid: Bool = false

    /// Error message for project name field
    @Published var nameError: String?

    /// Error message for project path field
    @Published var pathError: String?

    /// Error message for command field
    @Published var commandError: String?

    // MARK: - Published Properties - UI State

    /// Indicates if we're editing an existing project
    @Published var isEditing: Bool = false

    /// Indicates if the path picker should be shown
    @Published var showPathPicker: Bool = false

    /// Indicates if a save operation is in progress
    @Published var isLoading: Bool = false

    /// General error message for the form
    @Published var errorMessage: String?

    /// Success message after successful save
    @Published var successMessage: String?

    /// The project currently being edited (nil for new project)
    @Published var editingProject: Project?

    // MARK: - Dependencies

    private let projectManager: ProjectManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(projectManager: ProjectManager = ProjectManager()) {
        self.projectManager = projectManager
        setupValidation()
        setupGroupBindings()
    }

    // MARK: - Private Setup

    /// Sets up form validation by combining form field publishers
    private func setupValidation() {
        Publishers.CombineLatest3($projectName, $projectPath, $command)
            .map { [weak self] name, path, command in
                self?.validateForm(name: name, path: path, command: command) ?? false
            }
            .assign(to: &$isValid)
    }

    /// Binds available groups from project manager
    private func setupGroupBindings() {
        projectManager.$groups
            .receive(on: DispatchQueue.main)
            .assign(to: &$availableGroups)
    }

    // MARK: - Public Methods - Form Actions

    /// Saves the current form data as a new or updated project
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func save() -> Bool {
        // Clear previous errors and messages
        nameError = nil
        pathError = nil
        commandError = nil
        errorMessage = nil
        successMessage = nil

        // Validate each field individually to show specific errors
        var valid = true

        if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Project name is required"
            valid = false
        }

        if projectPath.trimmingCharacters(in: .whitespaces).isEmpty {
            pathError = "Project path is required"
            valid = false
        } else if !FileManager.default.fileExists(atPath: projectPath) {
            pathError = "Project path does not exist"
            valid = false
        }

        if command.trimmingCharacters(in: .whitespaces).isEmpty {
            commandError = "Command is required"
            valid = false
        }

        guard valid else {
            return false
        }

        // Handle inline new group creation if needed
        var groupId = selectedGroupId
        if showNewGroupField && !newGroupName.trimmingCharacters(in: .whitespaces).isEmpty {
            let newGroup = ProjectGroup(
                name: newGroupName.trimmingCharacters(in: .whitespaces),
                color: newGroupColor
            )
            if projectManager.addGroup(newGroup) {
                groupId = newGroup.id
            } else {
                newGroupError = projectManager.lastError?.localizedDescription ?? "Failed to create group"
                return false
            }
        }

        // Create or update project
        let project: Project
        if let editingProject = editingProject {
            // Update existing project
            project = Project(
                id: editingProject.id,
                name: projectName,
                path: projectPath,
                command: command,
                description: description.isEmpty ? nil : description,
                lastRun: editingProject.lastRun,
                groupId: groupId,
                environmentVariables: environmentVariables.filter { $0.isValid }
            )
        } else {
            // Create new project
            project = Project(
                name: projectName,
                path: projectPath,
                command: command,
                description: description.isEmpty ? nil : description,
                groupId: groupId,
                environmentVariables: environmentVariables.filter { $0.isValid }
            )
        }

        // Save using project manager
        let success = isEditing
            ? projectManager.updateProject(project)
            : projectManager.addProject(project)

        if success {
            // Assign project to group
            projectManager.assignProjectToGroup(projectId: project.id, groupId: groupId)

            successMessage = isEditing
                ? "Project '\(projectName)' updated successfully"
                : "Project '\(projectName)' added successfully"
            resetForm()
        } else {
            errorMessage = projectManager.lastError?.localizedDescription ?? "Failed to save project"
        }

        return success
    }

    /// Cancels the form and resets all fields
    func cancel() {
        resetForm()
    }

    // MARK: - Public Methods - Form State

    /// Loads an existing project into the form for editing
    /// - Parameter project: The project to edit
    func loadProject(_ project: Project) {
        editingProject = project
        isEditing = true
        projectName = project.name
        projectPath = project.path
        command = project.command
        description = project.description ?? ""
        selectedGroupId = project.groupId
        environmentVariables = project.environmentVariables
        showNewGroupField = false
        newGroupName = ""
        newGroupColor = .blue

        // Clear any previous errors
        nameError = nil
        pathError = nil
        commandError = nil
        errorMessage = nil
        successMessage = nil
        newGroupError = nil
    }

    /// Resets the form to its initial state
    func resetForm() {
        projectName = ""
        projectPath = ""
        command = ""
        description = ""
        selectedGroupId = nil
        environmentVariables = []
        newGroupName = ""
        newGroupColor = .blue
        showNewGroupField = false
        editingProject = nil
        isEditing = false
        nameError = nil
        pathError = nil
        commandError = nil
        errorMessage = nil
        successMessage = nil
        newGroupError = nil
    }

    // MARK: - Public Methods - Path Selection

    /// Opens a file picker dialog to select a project directory
    func selectPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Select Project Directory"
        panel.prompt = "Select"
        panel.message = "Choose the directory containing your development project"

        if panel.runModal() == .OK, let url = panel.url {
            projectPath = url.path

            // Auto-suggest project name if name field is empty
            if projectName.trimmingCharacters(in: .whitespaces).isEmpty {
                projectName = suggestProjectName(from: projectPath)
            }

            // Trigger validation
            validateForm()
        }
    }

    // MARK: - Private Methods - Validation

    /// Validates the form fields
    /// - Parameters:
    ///   - name: Project name
    ///   - path: Project path
    ///   - command: Shell command
    /// - Returns: true if all fields are valid, false otherwise
    private func validateForm(name: String, path: String, command: String) -> Bool {
        let isValidName = !name.trimmingCharacters(in: .whitespaces).isEmpty
        let isValidPath = !path.trimmingCharacters(in: .whitespaces).isEmpty
            && FileManager.default.fileExists(atPath: path)
        let isValidCommand = !command.trimmingCharacters(in: .whitespaces).isEmpty

        return isValidName && isValidPath && isValidCommand
    }

    /// Triggers manual validation of form fields
    private func validateForm() {
        let valid = validateForm(name: projectName, path: projectPath, command: command)
        isValid = valid
    }

    // MARK: - Private Methods - Helpers

    /// Suggests a project name based on the directory path
    /// - Parameter path: The project directory path
    /// - Returns: A human-readable project name
    private func suggestProjectName(from path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    /// Validates if a project path exists and is accessible
    /// - Parameter path: The path to validate
    /// - Returns: true if valid and exists, false otherwise
    func validateProjectPath(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    // MARK: - Environment Variables

    /// Adds a new empty environment variable to the form
    func addEnvironmentVariable() {
        let newEnvVar = EnvironmentVariable(key: "", value: "")
        environmentVariables.append(newEnvVar)
    }

    /// Removes an environment variable from the form
    /// - Parameter index: The index of the environment variable to remove
    func removeEnvironmentVariable(at index: Int) {
        guard index >= 0 && index < environmentVariables.count else { return }
        environmentVariables.remove(at: index)
    }

    /// Updates the key of an environment variable
    /// - Parameters:
    ///   - index: The index of the environment variable
    ///   - key: The new key value
    func updateEnvironmentVariableKey(at index: Int, key: String) {
        guard index >= 0 && index < environmentVariables.count else { return }
        environmentVariables[index].key = key
    }

    /// Updates the value of an environment variable
    /// - Parameters:
    ///   - index: The index of the environment variable
    ///   - value: The new value
    func updateEnvironmentVariableValue(at index: Int, value: String) {
        guard index >= 0 && index < environmentVariables.count else { return }
        environmentVariables[index].value = value
    }

    /// Imports environment variables from a .env file
    /// - Parameter url: The URL to the .env file
    /// - Returns: true if import was successful, false otherwise
    @discardableResult
    func importFromEnvFile(url: URL) -> Bool {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            var importedCount = 0

            for line in content.components(separatedBy: .newlines) {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }

                // Parse KEY=VALUE format
                let components = trimmedLine.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard components.count == 2 else { continue }

                let key = String(components[0]).trimmingCharacters(in: .whitespaces)
                let value = String(components[1]).trimmingCharacters(in: .whitespaces)

                // Skip if key or value is empty
                guard !key.isEmpty else { continue }

                // Check if this env var already exists
                if let existingIndex = environmentVariables.firstIndex(where: { $0.key == key }) {
                    // Update existing
                    environmentVariables[existingIndex].value = value
                } else {
                    // Add new
                    let newEnvVar = EnvironmentVariable(key: key, value: value)
                    environmentVariables.append(newEnvVar)
                    importedCount += 1
                }
            }

            return importedCount > 0
        } catch {
            errorMessage = "Failed to read .env file: \(error.localizedDescription)"
            return false
        }
    }

    /// Opens a file picker to select a .env file to import
    func selectEnvFileToImport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Select .env File"
        panel.prompt = "Import"
        panel.message = "Choose a .env file to import environment variables from"
        if let envType = UTType(filenameExtension: "env") {
            panel.allowedContentTypes = [envType]
        }

        if panel.runModal() == .OK, let url = panel.url {
            importFromEnvFile(url: url)
        }
    }
}
