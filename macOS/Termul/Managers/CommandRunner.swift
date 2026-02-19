//
//  CommandRunner.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation
import Combine

/// Manages shell command execution for projects
class CommandRunner: ObservableObject {
    // MARK: - Published Properties

    /// Current status of the command execution
    @Published var status: ProcessStatus = .idle

    /// Stream of output from the command
    var outputStream: AnyPublisher<CommandOutput, Never> {
        outputSubject.eraseToAnyPublisher()
    }

    /// Stream of status changes
    var statusStream: AnyPublisher<ProcessStatus, Never> {
        $status.eraseToAnyPublisher()
    }

    /// Stream of memory updates
    var memoryStream: AnyPublisher<MemoryData, Never> {
        memorySubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    private var process: Process?
    private let outputSubject = PassthroughSubject<CommandOutput, Never>()
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private var cancellables = Set<AnyCancellable>()
    private let terminationTimeout: TimeInterval = 5.0
    private let memoryMonitor: MemoryMonitor?
    private let memorySubject = PassthroughSubject<MemoryData, Never>()
    private var currentProjectId: UUID?

    // MARK: - Initialization

    /// Creates a new command runner instance
    /// - Parameter memoryMonitor: Optional memory monitor for tracking process memory
    init(memoryMonitor: MemoryMonitor? = nil) {
        self.memoryMonitor = memoryMonitor
    }

    // MARK: - Public Methods

    /// Runs a shell command in the specified directory
    /// - Parameters:
    ///   - command: The shell command to execute
    ///   - workingDirectory: The directory where the command should be executed
    ///   - projectId: UUID of the project (for memory tracking)
    ///   - environmentVariables: Optional array of environment variables to set before running the command
    func run(command: String, workingDirectory: String, projectId: UUID? = nil, environmentVariables: [EnvironmentVariable] = []) {
        // Store project ID for memory tracking
        self.currentProjectId = projectId

        // Stop any existing process
        if status.isRunning {
            stop()
        }

        // Validate working directory
        guard FileManager.default.fileExists(atPath: workingDirectory) else {
            status = .failed(NSError(
                domain: "CommandRunner",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Working directory does not exist: \(workingDirectory)"]
            ))
            return
        }

        // Fetch and send git branch information
        if let gitBranch = fetchGitBranch(projectPath: workingDirectory) {
            sendSystemMessage("Git branch: \(gitBranch)")
        }

        // Create new process using the user's default shell as a login shell.
        // GUI apps don't have a TTY, so interactive mode (-i) and direnv hooks don't work.
        // Instead, we explicitly:
        //   1. Source Nix profiles to get nix/direnv into PATH
        //   2. cd into the project directory
        //   3. Run `direnv export` to load the project's .envrc / Nix dev environment
        //   4. Execute the actual command
        let process = Process()
        let userShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        process.executableURL = URL(fileURLWithPath: userShell)

        // Escape single quotes in the path for safe shell interpolation
        let escapedPath = workingDirectory.replacingOccurrences(of: "'", with: "'\\''")

        // Build environment variable export commands
        let validEnvVars = environmentVariables.filter { $0.isValid }
        let exportCommands = validEnvVars
            .map { $0.exportCommand() }
            .joined(separator: "; ")

        // Log environment variables to output
        if !validEnvVars.isEmpty {
            sendSystemMessage("Setting up environment variables...")
            for envVar in validEnvVars {
                sendSystemMessage("  \(envVar.key)=\(envVar.value)")
            }
            sendSystemMessage("Environment variables configured")
        }

        // Build a command that sources Nix and direnv before running the user's command
        var wrappedCommand = """
        [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
        [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"; \
        cd '\(escapedPath)' && \
        if command -v direnv >/dev/null 2>&1; then eval "$(direnv export zsh 2>/dev/null)"; fi
        """

        // Add environment variable exports if any exist
        if !exportCommands.isEmpty {
            wrappedCommand += "; \(exportCommands)"
        }

        // Add the actual command
        wrappedCommand += "; \(command)"
        process.arguments = ["-l", "-c", wrappedCommand]

        // Set up pipes for stdout and stderr
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Set up termination handler
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.handleProcessTermination(process)
            }
        }

        do {
            // Start the process
            try process.run()
            self.process = process

            // Capture process ID after process has started
            let pid = process.processIdentifier

            // Update status
            status = .running(pid: pid)

            // Send system message
            sendSystemMessage("Started process (PID: \(pid))")

            // Start memory monitoring if a project ID is provided
            if let projectId = projectId, let memoryMonitor = memoryMonitor {
                memoryMonitor.startMonitoring(pid: pid, projectId: projectId)

                // Subscribe to memory updates and forward them
                memoryMonitor.memoryStream(for: projectId)
                    .sink { [weak self] memoryData in
                        self?.memorySubject.send(memoryData)
                    }
                    .store(in: &cancellables)
            }

            // Start reading output
            startReadingOutput(stdoutPipe: stdoutPipe, stderrPipe: stderrPipe)

        } catch {
            status = .failed(error)
            sendSystemMessage("Failed to start process: \(error.localizedDescription)")
        }
    }

    /// Opens a project in the user's configured IDE
    /// - Parameters:
    ///   - ideCommand: The IDE command to execute (e.g., "cursor", "zeditor", "code")
    ///   - projectPath: The path to the project to open
    /// - Returns: Whether the command was successfully launched
    @discardableResult
    func openInIDE(ideCommand: String, projectPath: String) -> Bool {
        // Validate IDE command
        guard !ideCommand.isEmpty else {
            return false
        }

        // Validate project path
        guard FileManager.default.fileExists(atPath: projectPath) else {
            return false
        }

        // Create process for opening in IDE
        let process = Process()
        let userShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        process.executableURL = URL(fileURLWithPath: userShell)

        // Escape single quotes in the path for safe shell interpolation
        let escapedPath = projectPath.replacingOccurrences(of: "'", with: "'\\''")

        // Build command to open project in IDE
        let wrappedCommand = """
        [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
        [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh"; \
        \(ideCommand) '\(escapedPath)'
        """

        process.arguments = ["-l", "-c", wrappedCommand]

        // Launch the process (detached, no need to monitor)
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            print("Failed to open IDE: \(error)")
            return false
        }
    }

    /// Fetches the current git branch for a project directory
    /// - Parameter projectPath: The path to the project directory
    /// - Returns: The current branch name if it's a git repository, nil otherwise
    func fetchGitBranch(projectPath: String) -> String? {
        // Validate project path
        guard FileManager.default.fileExists(atPath: projectPath) else {
            return nil
        }

        // Check if directory is a git repository (has .git directory or file)
        let gitDir = projectPath + "/.git"
        guard FileManager.default.fileExists(atPath: gitDir) else {
            return nil
        }

        // Create process to run git branch command
        let process = Process()
        let userShell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        process.executableURL = URL(fileURLWithPath: userShell)

        // Escape single quotes in the path for safe shell interpolation
        let escapedPath = projectPath.replacingOccurrences(of: "'", with: "'\\''")

        // Build git command to get current branch
        let wrappedCommand = """
        cd '\(escapedPath)' && git branch --show-current 2>/dev/null
        """

        process.arguments = ["-l", "-c", wrappedCommand]

        // Set up pipe for stdout
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe() // Suppress stderr

        // Run the process and capture output
        do {
            try process.run()
            process.waitUntilExit()

            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)

            // Return the branch name if successful, otherwise nil
            if let output = output, !output.isEmpty, process.terminationStatus == 0 {
                return output
            }
            return nil
        } catch {
            print("Failed to fetch git branch: \(error)")
            return nil
        }
    }

    /// Stops the currently running process
    func stop() {
        guard let process = process, status.isRunning else {
            return
        }

        // Stop memory monitoring
        if let projectId = currentProjectId {
            memoryMonitor?.stopMonitoring(projectId: projectId)
        }

        let pid = process.processIdentifier
        sendSystemMessage("Stopping process (PID: \(pid))...")

        // Send SIGTERM for graceful shutdown
        process.terminate()

        // Wait for process to terminate or force kill
        DispatchQueue.global().async { [weak self] in
            let timeoutDate = Date().addingTimeInterval(self?.terminationTimeout ?? 5.0)

            while process.isRunning && Date() < timeoutDate {
                usleep(100000) // Sleep for 100ms
            }

            if process.isRunning {
                // Force kill if still running
                process.terminate()
                DispatchQueue.main.async {
                    self?.sendSystemMessage("Forcefully terminated process (PID: \(pid))")
                }
            }
        }
    }

    /// Clears all captured output
    func clearOutput() {
        // Output subject doesn't need clearing as streams are live
        // This is a no-op but provided for API completeness
    }

    // MARK: - Private Methods

    /// Starts reading output from stdout and stderr pipes
    private func startReadingOutput(stdoutPipe: Pipe, stderrPipe: Pipe) {
        // Read stdout
        stdoutHandle = stdoutPipe.fileHandleForReading
        stdoutHandle?.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }

            let data = handle.availableData
            if !data.isEmpty {
                let output = String(data: data, encoding: .utf8) ?? ""
                self.sendOutput(output, type: .stdout)
            }
        }

        // Read stderr
        stderrHandle = stderrPipe.fileHandleForReading
        stderrHandle?.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }

            let data = handle.availableData
            if !data.isEmpty {
                let output = String(data: data, encoding: .utf8) ?? ""
                self.sendOutput(output, type: .stderr)
            }
        }
    }

    /// Handles process termination
    private func handleProcessTermination(_ process: Process) {
        let exitCode = process.terminationStatus

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Stop memory monitoring
            if let projectId = self.currentProjectId {
                self.memoryMonitor?.stopMonitoring(projectId: projectId)
            }

            // Close output handlers
            self.stdoutHandle?.closeFile()
            self.stderrHandle?.closeFile()
            self.stdoutHandle = nil
            self.stderrHandle = nil

            // Update status
            if exitCode == 0 {
                status = .stopped(exitCode: exitCode)
                sendSystemMessage("Process completed successfully (Exit: \(exitCode))")
            } else {
                status = .stopped(exitCode: exitCode)
                sendSystemMessage("Process exited with code: \(exitCode)")
            }

            // Clear process reference
            self.process = nil
        }
    }

    /// Sends output to the stream
    private func sendOutput(_ text: String, type: OutputType) {
        // Split output by newlines to send individual lines
        let lines = text.components(separatedBy: "\n")

        for line in lines {
            // Skip empty lines
            if line.isEmpty {
                continue
            }

            let output = CommandOutput(
                timestamp: Date(),
                text: line,
                type: type
            )
            outputSubject.send(output)
        }
    }

    /// Sends a system message to the output stream
    private func sendSystemMessage(_ message: String) {
        let output = CommandOutput(
            timestamp: Date(),
            text: message,
            type: .system
        )
        outputSubject.send(output)
    }

    // MARK: - Deinitialization

    deinit {
        // Clean up any running process
        stop()

        // Stop memory monitoring
        if let projectId = currentProjectId {
            memoryMonitor?.stopMonitoring(projectId: projectId)
        }

        // Cancel all subscriptions
        cancellables.forEach { $0.cancel() }

        // Close file handles
        stdoutHandle?.closeFile()
        stderrHandle?.closeFile()
    }
}
