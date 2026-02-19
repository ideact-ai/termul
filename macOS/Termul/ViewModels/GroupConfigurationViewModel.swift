//
//  GroupConfigurationViewModel.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation
import Combine
import AppKit

/// View model for the group configuration/management form
class GroupConfigurationViewModel: ObservableObject {
    // MARK: - Published Properties - Form Fields

    /// Group name input
    @Published var groupName: String = ""

    /// Optional group description input
    @Published var groupDescription: String = ""

    /// Selected color for the group
    @Published var selectedColor: GroupColor = .blue

    /// Selected project IDs for the group
    @Published var selectedProjectIds: Set<UUID> = []

    // MARK: - Published Properties - UI State

    /// All available projects
    @Published var availableProjects: [Project] = []

    /// All existing groups
    @Published var groups: [ProjectGroup] = []

    /// Indicates if we're editing an existing group
    @Published var isEditing: Bool = false

    /// Indicates if a save operation is in progress
    @Published var isLoading: Bool = false

    /// The group being edited (nil for new group)
    @Published var editingGroup: ProjectGroup?

    /// General error message
    @Published var errorMessage: String?

    /// Success message
    @Published var successMessage: String?

    /// Form validity
    @Published var isValid: Bool = false

    /// Name validation error
    @Published var nameError: String?

    // MARK: - Dependencies

    private let projectManager: ProjectManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(projectManager: ProjectManager) {
        self.projectManager = projectManager
        setupBindings()
        setupValidation()
    }

    // MARK: - Private Setup

    private func setupBindings() {
        projectManager.$projects
            .receive(on: DispatchQueue.main)
            .assign(to: &$availableProjects)

        projectManager.$groups
            .receive(on: DispatchQueue.main)
            .assign(to: &$groups)
    }

    private func setupValidation() {
        $groupName
            .map { [weak self] name in
                self?.validateGroupName(name) ?? false
            }
            .assign(to: &$isValid)
    }

    // MARK: - Public Methods

    /// Saves the current form data as a new or updated group
    /// - Returns: true if successful
    @discardableResult
    func save() -> Bool {
        nameError = nil
        errorMessage = nil
        successMessage = nil

        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            nameError = "Group name is required"
            return false
        }

        if isEditing, let editingGroup = editingGroup {
            // Update existing group
            var updatedGroup = editingGroup
            updatedGroup.name = trimmedName
            updatedGroup.description = groupDescription.isEmpty ? nil : groupDescription
            updatedGroup.color = selectedColor
            updatedGroup.projectIds = Array(selectedProjectIds)

            let success = projectManager.updateGroup(updatedGroup)
            if success {
                // Update project groupId references
                for project in availableProjects {
                    if selectedProjectIds.contains(project.id) {
                        projectManager.assignProjectToGroup(projectId: project.id, groupId: editingGroup.id)
                    } else if project.groupId == editingGroup.id {
                        projectManager.assignProjectToGroup(projectId: project.id, groupId: nil)
                    }
                }
                successMessage = "Group '\(trimmedName)' updated successfully"
                resetForm()
            } else {
                errorMessage = projectManager.lastError?.localizedDescription ?? "Failed to update group"
            }
            return success
        } else {
            // Create new group
            let group = ProjectGroup(
                name: trimmedName,
                description: groupDescription.isEmpty ? nil : groupDescription,
                projectIds: Array(selectedProjectIds),
                color: selectedColor
            )

            let success = projectManager.addGroup(group)
            if success {
                // Update project groupId references
                for projectId in selectedProjectIds {
                    projectManager.assignProjectToGroup(projectId: projectId, groupId: group.id)
                }
                successMessage = "Group '\(trimmedName)' created successfully"
                resetForm()
            } else {
                errorMessage = projectManager.lastError?.localizedDescription ?? "Failed to create group"
            }
            return success
        }
    }

    /// Loads an existing group into the form for editing
    /// - Parameter group: The group to edit
    func loadGroup(_ group: ProjectGroup) {
        editingGroup = group
        isEditing = true
        groupName = group.name
        groupDescription = group.description ?? ""
        selectedColor = group.color
        selectedProjectIds = Set(group.projectIds)

        nameError = nil
        errorMessage = nil
        successMessage = nil
    }

    /// Deletes a group
    /// - Parameter group: The group to delete
    func deleteGroup(_ group: ProjectGroup) {
        let alert = NSAlert()
        alert.messageText = "Delete Group?"
        alert.informativeText = "Are you sure you want to delete group '\(group.name)'? Projects will be ungrouped, not deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            projectManager.deleteGroup(groupId: group.id)
            if editingGroup?.id == group.id {
                resetForm()
            }
        }
    }

    /// Resets the form to its initial state
    func resetForm() {
        groupName = ""
        groupDescription = ""
        selectedColor = .blue
        selectedProjectIds = []
        editingGroup = nil
        isEditing = false
        nameError = nil
        errorMessage = nil
    }

    /// Cancels the form and resets all fields
    func cancel() {
        resetForm()
    }

    /// Toggles a project's inclusion in the current group
    /// - Parameter projectId: The project to toggle
    func toggleProject(_ projectId: UUID) {
        if selectedProjectIds.contains(projectId) {
            selectedProjectIds.remove(projectId)
        } else {
            selectedProjectIds.insert(projectId)
        }
    }

    /// Checks if a project is available for selection (not in another group)
    /// - Parameter project: The project to check
    /// - Returns: true if available
    func isProjectAvailable(_ project: Project) -> Bool {
        // Available if ungrouped or belongs to the group being edited
        if let editingGroup = editingGroup {
            return project.groupId == nil || project.groupId == editingGroup.id
        }
        return project.groupId == nil
    }

    // MARK: - Private Methods

    private func validateGroupName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
