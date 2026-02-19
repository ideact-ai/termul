//
//  PortKillerView.swift
//  Termul
//

import SwiftUI

/// View for finding and killing processes on specific ports
struct PortKillerView: View {
    // MARK: - State

    @State private var portInput: String = ""
    @State private var processes: [PortProcess] = []
    @State private var statusMessage: String?
    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var hoveredProcessId: UUID?
    @State private var hoveredButton: String?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            inputSection

            if isScanning {
                scanProgressBar
            }

            processsList

            if let msg = statusMessage {
                statusBar(message: msg)
            }
        }
        .frame(width: 480)
        .frame(minHeight: 400)
        .background(DesignColors.white)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignColors.warning)
                    .frame(width: 32, height: 32)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Port Killer")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)

                Text("Find and kill processes using specific ports")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.iron)
            }

        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(DesignColors.linen)
                    .frame(height: 1)
            }
        )
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.coral)
                Text("Port Numbers")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)
            }

            HStack(spacing: 10) {
                TextField("e.g., 3000, 8080, 5432", text: $portInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.textBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(DesignColors.linen, lineWidth: 1)
                            )
                    )
                    .onSubmit { scanPorts() }

                Button(action: scanPorts) {
                    HStack(spacing: 5) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 10, weight: .medium))
                        Text("Scan")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(DesignColors.coral)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(portInput.isEmpty || isScanning)
            }

            Text("Separate multiple ports with commas")
                .font(.system(size: 10))
                .foregroundColor(DesignColors.linen)
        }
        .padding(20)
    }

    // MARK: - Scan Progress

    private var scanProgressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignColors.coral.opacity(0.15))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignColors.coral)
                        .frame(width: geometry.size.width * scanProgress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: scanProgress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 20)

            Text("Scanning ports...")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignColors.iron)
        }
        .padding(.bottom, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Process List

    private var processsList: some View {
        Group {
            if processes.isEmpty && !isScanning {
                emptyState
            } else {
                VStack(spacing: 0) {
                    if !processes.isEmpty {
                        processListHeader
                    }

                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(processes) { proc in
                                processRow(proc)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var processListHeader: some View {
        HStack {
            Text("\(processes.count) process\(processes.count == 1 ? "" : "es") found")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(DesignColors.rausch)

            Spacer()

            if processes.count > 1 {
                Button(action: killAllProcesses) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Kill All")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(DesignColors.error)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(DesignColors.error.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            VStack {
                Spacer()
                Rectangle().fill(DesignColors.linen).frame(height: 1)
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(DesignColors.warning.opacity(0.15), lineWidth: 1)
                    .frame(width: 56, height: 56)

                Image(systemName: "network")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(DesignColors.warning.opacity(0.5))
            }

            VStack(spacing: 4) {
                Text("No Processes Found")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignColors.iron)

                Text("Enter port numbers above to scan")
                    .font(.system(size: 11))
                    .foregroundColor(DesignColors.linen)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func processRow(_ proc: PortProcess) -> some View {
        let isHovered = hoveredProcessId == proc.id

        return HStack(spacing: 12) {
            // Port badge
            Text("\(proc.port)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(DesignColors.coral)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(DesignColors.coral.opacity(0.1))
                )

            // Process info
            VStack(alignment: .leading, spacing: 2) {
                Text(proc.processName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Text("PID:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignColors.linen)
                        Text("\(proc.pid)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignColors.iron)
                    }

                    HStack(spacing: 3) {
                        Text("User:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignColors.linen)
                        Text(proc.user)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignColors.iron)
                    }
                }
            }

            Spacer()

            Button(action: { killProcess(proc) }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                    Text("Kill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(DesignColors.error)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(DesignColors.error.opacity(isHovered ? 0.18 : 0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? DesignColors.info.opacity(0.06) : DesignColors.snow.opacity(0.3))
        )
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredProcessId = hovered ? proc.id : nil
            }
        }
    }

    // MARK: - Status Bar

    private func statusBar(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(DesignColors.coral)

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignColors.iron)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(DesignColors.snow.opacity(0.3))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Actions

    private func scanPorts() {
        let ports = PortKiller.parsePorts(from: portInput)
        guard !ports.isEmpty else {
            statusMessage = "Please enter valid port numbers"
            return
        }

        isScanning = true
        scanProgress = 0
        statusMessage = nil
        processes = []

        withAnimation(.easeInOut(duration: 0.3)) { scanProgress = 0.3 }

        DispatchQueue.global(qos: .userInitiated).async {
            let results = PortKiller.findProcesses(on: ports)
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) { scanProgress = 1.0 }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.processes = results
                        self.isScanning = false

                        if results.isEmpty {
                            self.statusMessage = "No processes found on port\(ports.count > 1 ? "s" : "") \(ports.map(String.init).joined(separator: ", "))"
                        } else {
                            self.statusMessage = "Found \(results.count) process\(results.count > 1 ? "es" : "")"
                        }
                    }
                }
            }
        }
    }

    private func killProcess(_ proc: PortProcess) {
        let success = PortKiller.killProcess(pid: proc.pid)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            processes.removeAll { $0.id == proc.id }
            statusMessage = success
                ? "Killed \(proc.processName) (PID: \(proc.pid))"
                : "Failed to kill \(proc.processName) (PID: \(proc.pid))"
        }
    }

    private func killAllProcesses() {
        let results = PortKiller.killProcesses(processes)
        let successCount = results.values.filter { $0 }.count
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            processes.removeAll()
            statusMessage = "Killed \(successCount) of \(results.count) processes"
        }
    }
}
