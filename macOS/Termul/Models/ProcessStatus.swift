//
//  ProcessStatus.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents the current status of a running process
enum ProcessStatus: Equatable {
    /// No process is running
    case idle

    /// Process is currently running
    /// - Parameter pid: Process ID of the running process
    case running(pid: Int32)

    /// Process has completed or been stopped
    /// - Parameter exitCode: The exit code from the process, nil if terminated by signal
    case stopped(exitCode: Int32?)

    /// Process encountered an error
    /// - Parameter error: The error that occurred
    case failed(Error)

    /// Returns true if the process is currently running
    var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }

    /// Returns true if the process is idle (not running and never started)
    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }

    /// Returns true if the process has stopped (completed or terminated)
    var isStopped: Bool {
        if case .stopped = self {
            return true
        }
        return false
    }

    /// Returns true if the process has failed
    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    /// Returns a human-readable description of the status
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .running(let pid):
            return "Running (PID: \(pid))"
        case .stopped(let exitCode):
            if let exitCode = exitCode {
                return "Stopped (Exit: \(exitCode))"
            } else {
                return "Stopped (Terminated)"
            }
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
}

// Implement Equatable for Error types
extension ProcessStatus {
    static func == (lhs: ProcessStatus, rhs: ProcessStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.running(let lhsPid), .running(let rhsPid)):
            return lhsPid == rhsPid
        case (.stopped(let lhsCode), .stopped(let rhsCode)):
            return lhsCode == rhsCode
        case (.failed, .failed):
            return false // Errors are not easily comparable
        default:
            return false
        }
    }
}
