//
//  ProjectManager.swift
//  Termul
//
//  Created by Termul
//

import Foundation
import Combine

/// Manages project CRUD operations and persistence
class ProjectManager: ObservableObject {
    // MARK: - Published Properties

    /// All configured projects
    @Published var projects: [Project] = []

    /// All project groups
    @Published var groups: [ProjectGroup] = []

    /// Indicates if data is being loaded
    @Published var isLoading: Bool = false

    /// Last error that occurred
    @Published var lastError: Error?

    // MARK: - Constants

    private let projectsKey = "com.termul.projects"
    private let groupsKey = "com.termul.groups"
    private let backupDirectory = "Termul/Backups"

    // MARK: - Initialization

    init() {
        loadProjects()
        loadGroups()
    }

    // MARK: - Public Methods

    /// Adds a new project to the collection
    /// - Parameter project: The project to add
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func addProject(_ project: Project) -> Bool {
        // Check for duplicate names
        guard !projects.contains(where: { $0.name == project.name }) else {
            lastError = ProjectError.duplicateName(project.name)
            return false
        }

        // Validate project path
        guard project.isValidPath else {
            lastError = ProjectError.invalidPath(project.path)
            return false
        }

        projects.append(project)
        saveProjects()
        return true
    }

    /// Updates an existing project
    /// - Parameter project: The project with updated values
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func updateProject(_ project: Project) -> Bool {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
            lastError = ProjectError.projectNotFound
            return false
        }

        // Check for duplicate names (excluding current project)
        let duplicateName = projects.contains { $0.name == project.name && $0.id != project.id }
        guard !duplicateName else {
            lastError = ProjectError.duplicateName(project.name)
            return false
        }

        // Validate project path
        guard project.isValidPath else {
            lastError = ProjectError.invalidPath(project.path)
            return false
        }

        projects[index] = project
        saveProjects()
        return true
    }

    /// Deletes a project by its ID
    /// - Parameter projectId: The ID of the project to delete
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func deleteProject(projectId: UUID) -> Bool {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else {
            lastError = ProjectError.projectNotFound
            return false
        }

        projects.remove(at: index)
        saveProjects()
        return true
    }

    /// Retrieves a project by its ID
    /// - Parameter projectId: The ID of the project to retrieve
    /// - Returns: The project if found, nil otherwise
    func getProject(projectId: UUID) -> Project? {
        projects.first { $0.id == projectId }
    }

    /// Updates the last run timestamp for a project
    /// - Parameter projectId: The ID of the project to update
    func markProjectAsRun(projectId: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectId }) else {
            return
        }

        projects[index].markAsRun()
        saveProjects()
    }

    /// Clears all projects
    func clearAllProjects() {
        projects.removeAll()
        saveProjects()
    }

    /// Moves a project from one index to another and persists the new order
    /// - Parameters:
    ///   - source: Source indices
    ///   - destination: Destination index
    func moveProject(from source: IndexSet, to destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        // Update sort orders to match new positions
        for (index, _) in projects.enumerated() {
            projects[index].sortOrder = index
        }
        saveProjects()
    }

    /// Moves a group from one index to another and persists the new order
    /// - Parameters:
    ///   - source: Source indices
    ///   - destination: Destination index
    func moveGroup(from source: IndexSet, to destination: Int) {
        groups.move(fromOffsets: source, toOffset: destination)
        saveGroups()
    }

    // MARK: - Group CRUD Operations

    /// Adds a new project group
    /// - Parameter group: The group to add
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func addGroup(_ group: ProjectGroup) -> Bool {
        // Check for duplicate names
        guard !groups.contains(where: { $0.name == group.name }) else {
            lastError = ProjectError.duplicateGroupName(group.name)
            return false
        }

        groups.append(group)
        saveGroups()
        return true
    }

    /// Updates an existing group
    /// - Parameter group: The group with updated values
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func updateGroup(_ group: ProjectGroup) -> Bool {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            lastError = ProjectError.groupNotFound
            return false
        }

        // Check for duplicate names (excluding current group)
        let duplicateName = groups.contains { $0.name == group.name && $0.id != group.id }
        guard !duplicateName else {
            lastError = ProjectError.duplicateGroupName(group.name)
            return false
        }

        groups[index] = group
        saveGroups()
        return true
    }

    /// Deletes a group by its ID
    /// - Parameter groupId: The ID of the group to delete
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func deleteGroup(groupId: UUID) -> Bool {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else {
            lastError = ProjectError.groupNotFound
            return false
        }

        // Clear groupId from all projects that belong to this group
        for i in projects.indices {
            if projects[i].groupId == groupId {
                projects[i].groupId = nil
            }
        }
        saveProjects()

        groups.remove(at: index)
        saveGroups()
        return true
    }

    /// Retrieves a group by its ID
    /// - Parameter groupId: The ID of the group to retrieve
    /// - Returns: The group if found, nil otherwise
    func getGroup(groupId: UUID) -> ProjectGroup? {
        groups.first { $0.id == groupId }
    }

    /// Returns all projects belonging to a specific group
    /// - Parameter groupId: The group ID
    /// - Returns: Array of projects in the group
    func projects(inGroup groupId: UUID) -> [Project] {
        guard let group = getGroup(groupId: groupId) else { return [] }
        return projects.filter { group.projectIds.contains($0.id) }
    }

    /// Returns all projects that don't belong to any group
    /// - Returns: Array of ungrouped projects
    func ungroupedProjects() -> [Project] {
        let allGroupedIds = Set(groups.flatMap { $0.projectIds })
        return projects.filter { !allGroupedIds.contains($0.id) }
    }

    /// Assigns a project to a group
    /// - Parameters:
    ///   - projectId: The project to assign
    ///   - groupId: The group to assign to (nil to ungroup)
    @discardableResult
    func assignProjectToGroup(projectId: UUID, groupId: UUID?) -> Bool {
        // Remove project from any existing group
        for i in groups.indices {
            groups[i].removeProject(projectId)
        }

        // Add to new group if specified
        if let groupId = groupId,
           let index = groups.firstIndex(where: { $0.id == groupId }) {
            groups[index].addProject(projectId)
        }

        // Update project's groupId
        if let projectIndex = projects.firstIndex(where: { $0.id == projectId }) {
            projects[projectIndex].groupId = groupId
            saveProjects()
        }

        saveGroups()
        return true
    }

    /// Creates a backup of all projects to the Documents folder
    /// - Returns: URL of the backup file if successful, nil otherwise
    func createBackup() -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupPath = documentsPath.appendingPathComponent(backupDirectory)

        // Create backup directory if it doesn't exist
        try? FileManager.default.createDirectory(at: backupPath, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "projects_backup_\(dateFormatter.string(from: Date())).json"
        let backupURL = backupPath.appendingPathComponent(filename)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(projects)
            try data.write(to: backupURL)
            return backupURL
        } catch {
            lastError = error
            return nil
        }
    }

    // MARK: - Private Methods

    /// Saves projects to UserDefaults
    func saveProjects() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(projects)
            UserDefaults.standard.set(data, forKey: projectsKey)
        } catch {
            lastError = error
        }
    }

    /// Loads projects from UserDefaults
    private func loadProjects() {
        isLoading = true

        guard let data = UserDefaults.standard.data(forKey: projectsKey) else {
            isLoading = false
            return
        }

        do {
            let decoder = JSONDecoder()
            projects = try decoder.decode([Project].self, from: data)
        } catch {
            lastError = error
            // If loading fails, start with empty array
            projects = []
        }

        isLoading = false
    }

    /// Saves groups to UserDefaults
    private func saveGroups() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(groups)
            UserDefaults.standard.set(data, forKey: groupsKey)
        } catch {
            lastError = error
        }
    }

    /// Loads groups from UserDefaults
    private func loadGroups() {
        guard let data = UserDefaults.standard.data(forKey: groupsKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            groups = try decoder.decode([ProjectGroup].self, from: data)
        } catch {
            lastError = error
            groups = []
        }
    }
}

// MARK: - Project Errors

enum ProjectError: LocalizedError {
    case duplicateName(String)
    case invalidPath(String)
    case projectNotFound
    case saveFailed
    case loadFailed
    case duplicateGroupName(String)
    case groupNotFound

    var errorDescription: String? {
        switch self {
        case .duplicateName(let name):
            return "A project with name '\(name)' already exists"
        case .invalidPath(let path):
            return "Invalid or inaccessible path: \(path)"
        case .projectNotFound:
            return "Project not found"
        case .saveFailed:
            return "Failed to save projects"
        case .loadFailed:
            return "Failed to load projects"
        case .duplicateGroupName(let name):
            return "A group with name '\(name)' already exists"
        case .groupNotFound:
            return "Group not found"
        }
    }
}
