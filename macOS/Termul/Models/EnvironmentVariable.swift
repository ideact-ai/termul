//
//  EnvironmentVariable.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents an environment variable to be set before running a project command
struct EnvironmentVariable: Identifiable, Codable, Equatable {
    let id: UUID
    var key: String
    var value: String

    /// Creates a new environment variable
    /// - Parameters:
    ///   - id: Unique identifier for the environment variable
    ///   - key: The environment variable name (e.g., "NODE_ENV", "API_URL")
    ///   - value: The value to set for this environment variable
    init(
        id: UUID = UUID(),
        key: String,
        value: String
    ) {
        self.id = id
        self.key = key
        self.value = value
    }

    /// Validates if the environment variable key is valid
    /// Environment variable keys should be alphanumeric with underscores
    var isValidKey: Bool {
        !key.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Validates if the environment variable is complete (both key and value)
    var isValid: Bool {
        !key.trimmingCharacters(in: .whitespaces).isEmpty &&
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Returns the formatted export command for shell
    /// - Returns: A string in the format "export KEY=VALUE"
    func exportCommand() -> String {
        // Escape special characters in value for shell safety
        let escapedKey = key.replacingOccurrences(of: "'", with: "'\\''")
        let escapedValue = value.replacingOccurrences(of: "'", with: "'\\''")
        return "export '\(escapedKey)'='\(escapedValue)'"
    }
}
