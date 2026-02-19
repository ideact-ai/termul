//
//  Project.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents a development project that can be run from the menu bar
struct Project: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var path: String
    var command: String
    var description: String?
    var lastRun: Date?
    var groupId: UUID?
    var sortOrder: Int
    var environmentVariables: [EnvironmentVariable]
    var currentGitBranch: String?

    /// Creates a new project with the given properties
    /// - Parameters:
    ///   - id: Unique identifier for the project
    ///   - name: Display name for the project
    ///   - path: File system path to the project directory
    ///   - command: Shell command to execute for this project
    ///   - description: Optional description of the project
    ///   - lastRun: Optional timestamp of when the project was last run
    ///   - groupId: Optional ID of the group this project belongs to
    ///   - sortOrder: Display order (lower = higher in list)
    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        command: String,
        description: String? = nil,
        lastRun: Date? = nil,
        groupId: UUID? = nil,
        sortOrder: Int = 0,
        environmentVariables: [EnvironmentVariable] = [],
        currentGitBranch: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.command = command
        self.description = description
        self.lastRun = lastRun
        self.groupId = groupId
        self.sortOrder = sortOrder
        self.environmentVariables = environmentVariables
        self.currentGitBranch = currentGitBranch
    }

    /// Checks if the project path is valid and exists
    var isValidPath: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Returns the last run date formatted as a string
    var lastRunFormatted: String? {
        guard let lastRun = lastRun else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastRun)
    }

    /// Updates the last run timestamp to the current date
    mutating func markAsRun() {
        self.lastRun = Date()
    }
}
