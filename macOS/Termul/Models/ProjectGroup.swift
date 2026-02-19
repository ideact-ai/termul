//
//  ProjectGroup.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents a group of projects that can be run/stopped together
struct ProjectGroup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String?
    var projectIds: [UUID]
    var color: GroupColor

    /// Creates a new project group
    /// - Parameters:
    ///   - id: Unique identifier for the group
    ///   - name: Display name for the group
    ///   - description: Optional description of what this group represents
    ///   - projectIds: IDs of projects belonging to this group
    ///   - color: Color label for the group
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        projectIds: [UUID] = [],
        color: GroupColor = .blue
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.projectIds = projectIds
        self.color = color
    }

    /// Returns the number of projects in this group
    var projectCount: Int {
        projectIds.count
    }

    /// Checks if a specific project belongs to this group
    /// - Parameter projectId: The project ID to check
    /// - Returns: true if the project is in this group
    func contains(projectId: UUID) -> Bool {
        projectIds.contains(projectId)
    }

    /// Adds a project to this group
    /// - Parameter projectId: The project ID to add
    mutating func addProject(_ projectId: UUID) {
        guard !projectIds.contains(projectId) else { return }
        projectIds.append(projectId)
    }

    /// Removes a project from this group
    /// - Parameter projectId: The project ID to remove
    mutating func removeProject(_ projectId: UUID) {
        projectIds.removeAll { $0 == projectId }
    }
}

/// Available colors for project groups
enum GroupColor: String, Codable, CaseIterable, Equatable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case teal

    /// Human-readable display name
    var displayName: String {
        rawValue.capitalized
    }
}
