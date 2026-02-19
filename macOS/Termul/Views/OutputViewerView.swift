//
//  OutputViewerView.swift
//  Termul
//

import SwiftUI
import Combine
import AppKit

/// Terminal-like output viewer for displaying command execution output
struct OutputViewerView: View {
    // MARK: - Properties

    let project: Project
    @ObservedObject var viewModel: OutputViewerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isScrolledToBottom = true
    @State private var searchText = ""
    @State private var isSearchVisible = false
    @State private var hoveredButton: String?
    @ObservedObject private var settingsManager = AppSettingsManager.shared

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            if isSearchVisible {
                searchBar
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if settingsManager.settings.memoryTrackingEnabled && settingsManager.settings.showMemoryChart {
                memoryChartSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            outputDisplay

            controls
        }
        .frame(minWidth: 650, minHeight: 450)
        .background(DesignColors.white)
        .onAppear { viewModel.startWatching() }
        .onDisappear { viewModel.stopWatching() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)

                Text(project.path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(DesignColors.iron)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                if settingsManager.settings.memoryTrackingEnabled && settingsManager.settings.showMemoryChart {
                    memoryBadge
                }

                statusBadge
            }

            HeaderToolbarButton(
                icon: "magnifyingglass",
                isActive: isSearchVisible,
                id: "search",
                hoveredButton: $hoveredButton,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isSearchVisible.toggle()
                    }
                }
            )

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(DesignColors.linen)
                    .frame(height: 1)
            }
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(DesignColors.iron)

            TextField("Search output...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))

            if !searchText.isEmpty {
                let matchCount = viewModel.outputs.filter { $0.text.localizedCaseInsensitiveContains(searchText) }.count
                Text("\(matchCount) matches")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))

                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.25))
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(red: 0.11, green: 0.11, blue: 0.14))
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 6) {
            if viewModel.status.isRunning {
                PulsingDot(color: DesignColors.success, size: 6)
            } else {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }

            Text(viewModel.status.description)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .idle:    return DesignColors.iron
        case .running: return DesignColors.success
        case .stopped: return DesignColors.coral
        case .failed:  return DesignColors.error
        }
    }

    // MARK: - Output Display

    private var outputDisplay: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.outputs.isEmpty && viewModel.status.isIdle {
                        emptyOutputView
                    } else {
                        let filteredOutputs = searchText.isEmpty
                            ? viewModel.outputs
                            : viewModel.outputs.filter { $0.text.localizedCaseInsensitiveContains(searchText) }

                        ForEach(Array(filteredOutputs.enumerated()), id: \.element.id) { index, output in
                            outputRow(for: output, index: index)
                        }

                        Color.clear.frame(height: 0).id("bottom")
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .onChange(of: viewModel.outputs.count) {
                if isScrolledToBottom {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyOutputView: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .frame(width: 56, height: 56)

                Image(systemName: "terminal")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.12))
            }

            VStack(spacing: 6) {
                Text("No output yet")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))

                Text("Click 'Run' to start the command")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.18))
            }

            HStack(spacing: 6) {
                Text("$")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignColors.success.opacity(0.6))
                Text(project.command)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.03))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private func outputRow(for output: CommandOutput, index: Int) -> some View {
        let isHighlighted = !searchText.isEmpty && output.text.localizedCaseInsensitiveContains(searchText)

        return HStack(alignment: .top, spacing: 0) {
            Text("\(index + 1)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.1))
                .frame(width: 40, alignment: .trailing)
                .padding(.trailing, 8)

            Text(timestampString(for: output.timestamp))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.18))
                .frame(width: 65, alignment: .leading)

            // Type indicator stripe
            Rectangle()
                .fill(outputTypeColor(for: output.type))
                .frame(width: 2)
                .padding(.vertical, 2)
                .padding(.trailing, 8)

            Text(output.text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(outputColor(for: output.type))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .background(
            output.isError
                ? DesignColors.error.opacity(0.06)
                : (isHighlighted ? DesignColors.warning.opacity(0.06) : Color.clear)
        )
    }

    private func outputColor(for type: OutputType) -> Color {
        switch type {
        case .stdout: return .white.opacity(0.78)
        case .stderr: return DesignColors.coral
        case .system: return DesignColors.coral.opacity(0.7)
        }
    }

    private func outputTypeColor(for type: OutputType) -> Color {
        switch type {
        case .stdout: return .white.opacity(0.06)
        case .stderr: return DesignColors.error.opacity(0.5)
        case .system: return DesignColors.coral.opacity(0.3)
        }
    }

    private func timestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 10) {
            scrollIndicator

            Spacer()

            if !viewModel.outputs.isEmpty {
                Text("\(viewModel.outputs.count) lines")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
            }

            ControlButton(icon: "doc.on.doc", label: "Copy", id: "copy", hoveredButton: $hoveredButton, isDisabled: viewModel.outputs.isEmpty, action: copyToClipboard)
            ControlButton(icon: "square.and.arrow.down", label: "Save", id: "save", hoveredButton: $hoveredButton, isDisabled: viewModel.outputs.isEmpty, action: saveToFile)
            ControlButton(icon: "trash", label: "Clear", id: "clear", hoveredButton: $hoveredButton, isDisabled: viewModel.outputs.isEmpty, style: .destructive, action: clearOutput)

            actionButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
    }

    private var scrollIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: isScrolledToBottom ? "arrow.down.circle.fill" : "arrow.down.circle")
                .font(.system(size: 10))
                .foregroundColor(isScrolledToBottom ? DesignColors.success.opacity(0.7) : .white.opacity(0.25))

            Text("Auto-scroll")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            Toggle("", isOn: $isScrolledToBottom)
                .toggleStyle(SwitchToggleStyle())
                .controlSize(.mini)
                .scaleEffect(0.75)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.04))
        )
    }

    private var actionButton: some View {
        Button(action: {
            if viewModel.status.isRunning { viewModel.stop() } else { viewModel.run() }
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.status.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 10))
                Text(viewModel.status.isRunning ? "Stop" : "Run")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(viewModel.status.isRunning ? DesignColors.coral : DesignColors.success)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Memory Badge

    private var memoryBadge: some View {
        HStack(spacing: 6) {
            if let current = viewModel.currentMemory {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 8))
                    .foregroundColor(memoryLevelColor(for: current.memoryMB))

                Text(current.memoryMBFormatted)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(memoryLevelColor(for: current.memoryMB))
            } else {
                Image(systemName: "chart.bar")
                    .font(.system(size: 8))
                    .foregroundColor(.white.opacity(0.3))

                Text("-- MB")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(.white.opacity(0.05))
        )
    }

    // MARK: - Memory Chart Section

    private var memoryChartSection: some View {
        VStack(spacing: 0) {
            MemoryChartView(memoryData: viewModel.memoryHistory)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }

    // MARK: - Memory Helpers

    private func memoryLevelColor(for mb: Double) -> Color {
        switch mb {
        case 0..<500: return DesignColors.success
        case 500..<1024: return DesignColors.warning
        case 1024..<2048: return DesignColors.warning
        default: return DesignColors.error
        }
    }

    // MARK: - Actions

    private func copyToClipboard() {
        let text = viewModel.outputs.map { $0.text }.joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func saveToFile() {
        let text = viewModel.outputs.map { "[\($0.timestamp)] \($0.text)" }.joined(separator: "\n")
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(project.name.replacingOccurrences(of: " ", with: "_"))_output.txt"
        panel.title = "Save Output"
        if panel.runModal() == .OK, let url = panel.url {
            do { try text.write(to: url, atomically: true, encoding: .utf8) }
            catch { viewModel.errorMessage = "Failed to save: \(error.localizedDescription)" }
        }
    }

    private func clearOutput() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { viewModel.clearOutput() }
    }
}

// MARK: - Header Toolbar Button

struct HeaderToolbarButton: View {
    let icon: String
    let isActive: Bool
    let id: String
    @Binding var hoveredButton: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isActive ? .white.opacity(0.9) : .white.opacity(0.35))
                .frame(width: 26, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isActive ? DesignColors.info.opacity(0.3) : (hoveredButton == id ? Color.white.opacity(0.06) : Color.clear))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { hoveredButton = hovering ? id : nil }
        }
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let label: String
    let id: String
    @Binding var hoveredButton: String?
    var isDisabled: Bool = false
    var style: ControlButtonStyle = .normal
    let action: () -> Void

    enum ControlButtonStyle { case normal, destructive }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10))
                Text(label).font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(
                isDisabled ? .white.opacity(0.12)
                : (style == .destructive ? DesignColors.coral : .white.opacity(0.5))
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(hoveredButton == id && !isDisabled ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { hoveredButton = hovering ? id : nil }
        }
    }
}
