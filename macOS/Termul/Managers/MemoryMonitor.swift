//
//  MemoryMonitor.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation
import Combine
import Darwin

/// Manages real-time memory monitoring for running processes
class MemoryMonitor: ObservableObject {
    // MARK: - Types

    /// Information about a monitored process
    private struct MonitoredProcess {
        let pid: Int32
        let projectId: UUID
        let publisher: PassthroughSubject<MemoryData, Never>
        var timer: Timer?
    }

    // MARK: - Published Properties

    @Published var isActive: Bool = false

    // MARK: - Private Properties

    private var monitoredProcesses: [UUID: MonitoredProcess] = [:]
    private var pollingQueue = DispatchQueue(label: "com.termul.memorymonitor", qos: .utility)
    private var cancellables = Set<AnyCancellable>()
    private let appSettings: AppSettings

    // MARK: - Initialization

    /// Creates a new memory monitor instance
    /// - Parameter appSettings: App settings for configuration (defaults to shared)
    init(appSettings: AppSettings = .shared) {
        self.appSettings = appSettings
    }

    // MARK: - Public Methods

    /// Starts monitoring memory for a specific process
    /// - Parameters:
    ///   - pid: Process ID to monitor
    ///   - projectId: UUID of the project associated with this process
    func startMonitoring(pid: Int32, projectId: UUID) {
        guard appSettings.memoryTrackingEnabled else {
            return
        }

        // Stop existing monitoring for this project if any
        stopMonitoring(projectId: projectId)

        let publisher = PassthroughSubject<MemoryData, Never>()
        let timer = Timer.scheduledTimer(
            withTimeInterval: appSettings.memoryTrackingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.pollMemory(for: projectId)
        }

        monitoredProcesses[projectId] = MonitoredProcess(
            pid: pid,
            projectId: projectId,
            publisher: publisher,
            timer: timer
        )

        isActive = !monitoredProcesses.isEmpty

        // Perform initial poll
        pollMemory(for: projectId)
    }

    /// Stops monitoring for a specific project
    /// - Parameter projectId: UUID of the project to stop monitoring
    func stopMonitoring(projectId: UUID) {
        guard let monitored = monitoredProcesses[projectId] else {
            return
        }

        // Invalidate timer
        monitored.timer?.invalidate()

        // Send completion to publisher
        monitored.publisher.send(completion: .finished)

        // Remove from tracking
        monitoredProcesses.removeValue(forKey: projectId)

        isActive = !monitoredProcesses.isEmpty
    }

    /// Stops monitoring all processes
    func stopAll() {
        let projectIds = Array(monitoredProcesses.keys)
        for projectId in projectIds {
            stopMonitoring(projectId: projectId)
        }
    }

    /// Returns a publisher that emits memory data for a specific project
    /// - Parameter projectId: UUID of the project
    /// - Returns: Publisher that emits MemoryData values
    func memoryStream(for projectId: UUID) -> AnyPublisher<MemoryData, Never> {
        if let monitored = monitoredProcesses[projectId] {
            return monitored.publisher.eraseToAnyPublisher()
        }

        // Return an empty publisher if not being monitored
        return Empty<MemoryData, Never>().eraseToAnyPublisher()
    }

    /// Updates the polling interval for all active monitors
    /// - Parameter interval: New interval in seconds
    func updatePollingInterval(_ interval: Double) {
        // Stop all and restart with new interval
        let activeProcesses = monitoredProcesses.map { ($0.value.pid, $0.key) }

        stopAll()

        for (pid, projectId) in activeProcesses {
            startMonitoring(pid: pid, projectId: projectId)
        }
    }

    // MARK: - Private Methods

    /// Polls memory usage for a specific project
    /// - Parameter projectId: UUID of the project to poll
    private func pollMemory(for projectId: UUID) {
        guard let monitored = monitoredProcesses[projectId] else {
            return
        }

        pollingQueue.async { [weak self] in
            guard let self = self else { return }

            // Query memory usage from system
            if let memoryMB = self.getMemoryUsage(pid: monitored.pid) {
                let memoryData = MemoryData(
                    timestamp: Date(),
                    memoryMB: memoryMB
                )

                // Publish on main thread for UI updates
                DispatchQueue.main.async {
                    monitored.publisher.send(memoryData)
                }
            } else {
                // Process may have terminated, stop monitoring
                DispatchQueue.main.async {
                    self.stopMonitoring(projectId: projectId)
                }
            }
        }
    }

    /// Queries the system for memory usage of a process
    /// - Parameter pid: Process ID to query
    /// - Returns: Memory usage in megabytes, or nil if query failed
    private func getMemoryUsage(pid: Int32) -> Double? {
        var info = proc_taskinfo()
        var size = MemoryLayout<proc_taskinfo>.stride

        let result = proc_pidinfo(
            pid,
            PROC_PIDTASKINFO,
            0,
            &info,
            Int32(size)
        )

        guard result == size else {
            // Process may not exist or access denied
            return nil
        }

        // Return resident memory in MB
        // pti_resident_size is in bytes
        return Double(info.pti_resident_size) / (1024.0 * 1024.0)
    }

    // MARK: - Deinitialization

    deinit {
        stopAll()
    }
}

// MARK: - Constants

extension MemoryMonitor {
    /// Default polling interval for memory monitoring (2 seconds)
    static let defaultPollingInterval: TimeInterval = 2.0

    /// Maximum number of memory data points to keep per project (10 minutes at 2s intervals)
    static let defaultMaxHistoryPoints: Int = 300
}
