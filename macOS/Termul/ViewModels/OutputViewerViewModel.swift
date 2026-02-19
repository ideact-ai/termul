//
//  OutputViewerViewModel.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation
import Combine

/// View model for managing output display in the output viewer
class OutputViewerViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All captured output entries
    @Published var outputs: [CommandOutput] = []

    /// Current process status
    @Published var status: ProcessStatus = .idle

    /// Error message to display
    @Published var errorMessage: String?

    /// Indicates if new output is being received
    @Published var isReceivingOutput: Bool = false

    /// Memory history for this project
    @Published var memoryHistory: [MemoryData] = []

    /// Current memory usage
    @Published var currentMemory: MemoryData?

    /// Minimum memory usage
    @Published var minMemory: Double?

    /// Maximum memory usage
    @Published var maxMemory: Double?

    /// Average memory usage
    @Published var averageMemory: Double?

    /// Memory trend
    @Published var memoryTrend: MemoryTrend = .stable

    /// Maximum number of output lines to keep (prevents memory issues)
    private let maxOutputLines = 10000

    // MARK: - Dependencies

    private let commandRunner: CommandRunner
    private let project: Project
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(project: Project, commandRunner: CommandRunner = CommandRunner()) {
        self.project = project
        self.commandRunner = commandRunner
    }

    // MARK: - Public Methods

    /// Starts watching for output and status changes
    func startWatching() {
        // Subscribe to status changes
        commandRunner.statusStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.status = status
            }
            .store(in: &cancellables)

        // Subscribe to output
        commandRunner.outputStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] output in
                self?.handleOutput(output)
            }
            .store(in: &cancellables)

        // Subscribe to memory updates from MenuBarViewModel via NotificationCenter
        NotificationCenter.default.publisher(for: .memoryDataUpdate)
            .compactMap { notification -> (UUID, MemoryData)? in
                guard let projectId = notification.object as? UUID,
                      let memoryData = notification.userInfo?["memoryData"] as? MemoryData else {
                    return nil
                }
                return (projectId, memoryData)
            }
            .filter { projectId, _ in projectId == self.project.id }
            .map { _, memoryData in memoryData }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] memoryData in
                self?.handleMemoryData(memoryData)
            }
            .store(in: &cancellables)
    }

    /// Stops watching for output
    func stopWatching() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    /// Runs the command for this project
    func run() {
        // Clear previous outputs before running
        outputs.removeAll()
        errorMessage = nil
        commandRunner.run(command: project.command, workingDirectory: project.path)
    }

    /// Stops the currently running command
    func stop() {
        commandRunner.stop()
    }

    /// Clears all captured output
    func clearOutput() {
        outputs.removeAll()
    }

    /// Returns all output as a single string
    /// - Returns: Combined output text with newlines
    func getAllOutputText() -> String {
        outputs
            .map { $0.text }
            .joined(separator: "\n")
    }

    /// Returns formatted output with timestamps
    /// - Returns: Output text with timestamp prefixes
    func getFormattedOutputText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        return outputs
            .map { "[\(formatter.string(from: $0.timestamp))] \($0.text)" }
            .joined(separator: "\n")
    }

    // MARK: - Private Methods

    private func handleOutput(_ output: CommandOutput) {
        isReceivingOutput = true
        outputs.append(output)

        // Prevent unbounded memory growth
        if outputs.count > maxOutputLines {
            let excess = outputs.count - maxOutputLines
            outputs.removeFirst(excess)
        }

        // Reset receiving flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isReceivingOutput = false
        }
    }

    /// Handles memory data updates
    /// - Parameter memoryData: The memory data point
    private func handleMemoryData(_ memoryData: MemoryData) {
        memoryHistory.append(memoryData)

        // Limit memory history to 300 points
        if memoryHistory.count > 300 {
            memoryHistory.removeFirst(memoryHistory.count - 300)
        }

        // Update current memory
        currentMemory = memoryData

        // Calculate statistics
        calculateStatistics()
    }

    /// Calculates memory statistics from history
    private func calculateStatistics() {
        guard !memoryHistory.isEmpty else {
            minMemory = nil
            maxMemory = nil
            averageMemory = nil
            memoryTrend = .stable
            return
        }

        let values = memoryHistory.map { $0.memoryMB }
        minMemory = values.min()
        maxMemory = values.max()
        averageMemory = values.reduce(0, +) / Double(values.count)

        // Calculate trend
        memoryTrend = calculateTrend()
    }

    /// Calculates memory trend from history
    /// - Returns: The detected trend
    private func calculateTrend() -> MemoryTrend {
        guard memoryHistory.count >= 10 else { return .stable }

        let recent = memoryHistory.suffix(10).map { $0.memoryMB }
        let averageFirst = recent.prefix(5).reduce(0, +) / 5.0
        let averageLast = recent.suffix(5).reduce(0, +) / 5.0

        let delta = averageLast - averageFirst

        if delta > 10 { return .increasing }
        if delta < -10 { return .decreasing }
        return .stable
    }

    /// Clears all memory history
    func clearMemoryHistory() {
        memoryHistory.removeAll()
        currentMemory = nil
        minMemory = nil
        maxMemory = nil
        averageMemory = nil
        memoryTrend = .stable
    }
}
