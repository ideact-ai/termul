//
//  PortKiller.swift
//  Termul
//
//  Created by Service Helper
//

import Foundation

/// Represents a process occupying a network port
struct PortProcess: Identifiable, Equatable {
    let id = UUID()
    let port: Int
    let pid: Int32
    let processName: String
    let user: String

    static func == (lhs: PortProcess, rhs: PortProcess) -> Bool {
        return lhs.port == rhs.port && lhs.pid == rhs.pid
    }
}

/// Utility for finding and killing processes on specific ports
class PortKiller {

    /// Scans a single port and returns processes listening on it
    /// - Parameter port: The port number to scan
    /// - Returns: Array of processes found on the port
    static func findProcesses(on port: Int) -> [PortProcess] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-i", ":\(port)", "-P", "-n", "-sTCP:LISTEN"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseProcesses(from: output, port: port)
    }

    /// Scans multiple ports and returns all processes found
    /// - Parameter ports: Array of port numbers to scan
    /// - Returns: Array of processes found across all ports
    static func findProcesses(on ports: [Int]) -> [PortProcess] {
        var allProcesses: [PortProcess] = []
        var seenPids: Set<Int32> = []

        for port in ports {
            let processes = findProcesses(on: port)
            for proc in processes {
                // Avoid duplicate PIDs (same process can show up for multiple ports)
                if !seenPids.contains(proc.pid) {
                    allProcesses.append(proc)
                    seenPids.insert(proc.pid)
                }
            }
        }

        return allProcesses
    }

    /// Kills a process by PID
    /// - Parameter pid: The process ID to kill
    /// - Returns: true if the kill signal was sent successfully
    static func killProcess(pid: Int32) -> Bool {
        let result = kill(pid, SIGTERM)
        if result == 0 {
            // Wait briefly and check if it's still alive
            usleep(500_000) // 500ms
            let stillAlive = kill(pid, 0) == 0
            if stillAlive {
                // Force kill
                kill(pid, SIGKILL)
            }
            return true
        }
        return false
    }

    /// Kills all given processes
    /// - Parameter processes: Array of PortProcess to kill
    /// - Returns: Dictionary of PID to success/failure
    static func killProcesses(_ processes: [PortProcess]) -> [Int32: Bool] {
        var results: [Int32: Bool] = [:]
        for proc in processes {
            results[proc.pid] = killProcess(pid: proc.pid)
        }
        return results
    }

    // MARK: - Private

    /// Parses lsof output to extract process information
    private static func parseProcesses(from output: String, port: Int) -> [PortProcess] {
        var processes: [PortProcess] = []
        let lines = output.components(separatedBy: "\n")

        // Skip the header line
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // lsof output format: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            let columns = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard columns.count >= 9 else { continue }

            let processName = columns[0]
            let user = columns[2]

            guard let pid = Int32(columns[1]) else { continue }

            // Skip the lsof process itself
            guard processName != "lsof" else { continue }

            processes.append(PortProcess(
                port: port,
                pid: pid,
                processName: processName,
                user: user
            ))
        }

        return processes
    }

    /// Parses a comma/space separated string of ports into integers
    /// - Parameter input: String like "3000, 8080, 5432"
    /// - Returns: Array of valid port numbers
    static func parsePorts(from input: String) -> [Int] {
        return input
            .components(separatedBy: CharacterSet(charactersIn: ", \n"))
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { $0 > 0 && $0 <= 65535 }
    }
}
