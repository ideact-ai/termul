//
//  CommandOutput.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents a single line or chunk of output from a command execution
struct CommandOutput: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let text: String
    let type: OutputType

    /// Creates a new command output entry
    /// - Parameters:
    ///   - id: Unique identifier for this output entry
    ///   - timestamp: When this output was generated
    ///   - text: The actual output text
    ///   - type: The type of output (stdout, stderr, or system message)
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        text: String,
        type: OutputType
    ) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.type = type
    }

    /// Returns the text with appropriate formatting for display
    var displayText: String {
        switch type {
        case .stdout, .stderr:
            return text
        case .system:
            return "[\(text)]"
        }
    }

    /// Checks if this output should be highlighted as an error
    var isError: Bool {
        type == .stderr
    }

    /// Checks if this is a system message
    var isSystem: Bool {
        type == .system
    }
}

/// The type of command output
enum OutputType: String, Codable, Equatable {
    /// Standard output from the command
    case stdout

    /// Standard error output from the command
    case stderr

    /// System-generated messages (e.g., process started, stopped)
    case system

    /// Returns a color identifier for UI purposes
    var color: String {
        switch self {
        case .stdout:
            return "text-primary"
        case .stderr:
            return "text-red"
        case .system:
            return "text-gray"
        }
    }
}
