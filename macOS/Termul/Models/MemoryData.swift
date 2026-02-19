//
//  MemoryData.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents a snapshot of memory usage at a specific point in time
struct MemoryData: Identifiable, Codable {
    /// Unique identifier for this memory data point
    let id: UUID

    /// When this memory reading was captured
    let timestamp: Date

    /// Memory usage in megabytes
    let memoryMB: Double

    /// Formatted string representation of memory usage
    /// Examples: "512 MB", "1.2 GB", "2.5 GB"
    var memoryMBFormatted: String {
        if memoryMB >= 1024 {
            let gb = memoryMB / 1024.0
            return String(format: "%.2f GB", gb)
        } else {
            return String(format: "%.0f MB", memoryMB)
        }
    }

    /// Creates a new memory data point
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - timestamp: When this reading was captured (defaults to now)
    ///   - memoryMB: Memory usage in megabytes
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        memoryMB: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.memoryMB = memoryMB
    }

    /// Returns a color identifier based on memory usage threshold
    /// - Returns: Color name for UI rendering
    var colorLevel: String {
        switch memoryMB {
        case 0..<500:
            return "green"
        case 500..<1024:
            return "yellow"
        case 1024..<2048:
            return "orange"
        default:
            return "red"
        }
    }
}

/// Trend of memory usage over time
enum MemoryTrend: String, Codable {
    /// Memory usage is increasing
    case increasing

    /// Memory usage is decreasing
    case decreasing

    /// Memory usage is stable
    case stable

    /// Symbol to display for this trend
    var symbol: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    /// Color to use for this trend
    var color: String {
        switch self {
        case .increasing: return "red"
        case .decreasing: return "green"
        case .stable: return "gray"
        }
    }
}
