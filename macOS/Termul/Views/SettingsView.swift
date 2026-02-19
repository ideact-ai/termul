//
//  SettingsView.swift
//  Termul
//

import SwiftUI

/// Settings configuration view for application preferences
struct SettingsView: View {
    // MARK: - Properties

    @ObservedObject var settingsManager: AppSettingsManager
    @Environment(\.dismiss) private var dismiss
    @State private var hoveredSection: String?
    @State private var showResetConfirmation = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    memoryTrackingSection
                    displaySection
                    appModeSection
                    ideSection
                    historySection
                    advancedSection
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .background(DesignColors.white)
        }
        .frame(width: 580, height: 520)
        .background(DesignColors.white)
        .alert("Reset Settings", isPresented: $showResetConfirmation, presenting: ResetConfirmationContext()) { context in
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: { context in
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)

                Text("Configure Termul preferences")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.iron)
            }

            Spacer()

            Button(action: resetToDefaults) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                    Text("Reset to Defaults")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(DesignColors.error)
            }
            .buttonStyle(BorderlessButtonStyle())
            .help("Reset all settings to default values")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(DesignColors.linen)
                    .frame(height: 1)
            }
        )
    }

    // MARK: - Memory Tracking Section

    private var memoryTrackingSection: some View {
        SectionCard(
            title: "Memory Tracking",
            icon: "chart.line.uptrend.xyaxis",
            iconColor: DesignColors.info,
            isHovered: hoveredSection == "memoryTracking"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ToggleRow(
                    title: "Enable Memory Tracking",
                    description: "Monitor memory usage for running projects in real-time",
                    isOn: Binding(
                        get: { settingsManager.settings.memoryTrackingEnabled },
                        set: { enabled in
                            settingsManager.update { $0.memoryTrackingEnabled = enabled }
                        }
                    )
                )

                if settingsManager.settings.memoryTrackingEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        SliderRow(
                            title: "Update Interval",
                            value: Binding(
                                get: { settingsManager.settings.memoryTrackingInterval },
                                set: { interval in
                                    settingsManager.update { $0.memoryTrackingInterval = interval }
                                }
                            ),
                            range: 1...10,
                            format: "%.0f seconds"
                        )

                        SliderRow(
                            title: "History Points",
                            value: Binding(
                                get: { Double(settingsManager.settings.maxMemoryHistoryPoints) },
                                set: { points in
                                    settingsManager.update { $0.maxMemoryHistoryPoints = Int(points) }
                                }
                            ),
                            range: 50...1000,
                            format: "%.0f points"
                        )
                    }
                }
            }
        }
        .onHover { hovering in
            hoveredSection = hovering ? "memoryTracking" : nil
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        SectionCard(
            title: "Display",
            icon: "display",
            iconColor: DesignColors.coral,
            isHovered: hoveredSection == "display"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ToggleRow(
                    title: "Show Memory Charts",
                    description: "Display memory usage sparkline charts in output viewer",
                    isOn: Binding(
                        get: { settingsManager.settings.showMemoryChart },
                        set: { enabled in
                            settingsManager.update { $0.showMemoryChart = enabled }
                        }
                    )
                )
            }
        }
        .onHover { hovering in
            hoveredSection = hovering ? "display" : nil
        }
    }

    // MARK: - App Mode Section

    private var appModeSection: some View {
        SectionCard(
            title: "Application Mode",
            icon: "app.dashed",
            iconColor: DesignColors.gitBranch,
            isHovered: hoveredSection == "appMode"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ToggleRow(
                    title: "Open Window on Launch",
                    description: "Automatically show main window when app starts",
                    isOn: Binding(
                        get: { settingsManager.settings.openMainWindowOnLaunch },
                        set: { enabled in
                            settingsManager.update { $0.openMainWindowOnLaunch = enabled }
                        }
                    )
                )
            }
        }
        .onHover { hovering in
            hoveredSection = hovering ? "appMode" : nil
        }
    }

    // MARK: - IDE Section

    private var ideSection: some View {
        SectionCard(
            title: "IDE Integration",
            icon: "pencil.and.outline",
            iconColor: DesignColors.success,
            isHovered: hoveredSection == "ide"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignColors.coral)
                    Text("Open in IDE Command")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignColors.rausch)
                }

                TextField("e.g., code . or mate .", text: Binding(
                    get: { settingsManager.settings.ideCommand },
                    set: { command in
                        settingsManager.update { $0.ideCommand = command }
                    }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.snow.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignColors.linen, lineWidth: 1)
                        )
                )

                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundColor(DesignColors.info)

                    Text("Leave empty to hide 'Open in IDE' button")
                        .font(.system(size: 11))
                        .foregroundColor(DesignColors.iron)
                }
            }
        }
        .onHover { hovering in
            hoveredSection = hovering ? "ide" : nil
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        SectionCard(
            title: "Memory History",
            icon: "clock.arrow.circlepath",
            iconColor: DesignColors.warning,
            isHovered: hoveredSection == "history"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                SliderRow(
                    title: "Max History Points",
                    value: Binding(
                        get: { Double(settingsManager.settings.maxMemoryHistoryPoints) },
                        set: { points in
                            settingsManager.update { $0.maxMemoryHistoryPoints = Int(points) }
                        }
                    ),
                    range: 50...1000,
                    format: "%.0f points"
                )
            }
        }
        .onHover { hovering in
            hoveredSection = hovering ? "history" : nil
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        SectionCard(
            title: "Advanced",
            icon: "gearshape.2.fill",
            iconColor: DesignColors.iron,
            isHovered: hoveredSection == "advanced"
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: {
                    // TODO: Implement export settings
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                        Text("Export Settings")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(DesignColors.coral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignColors.coral.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    // TODO: Implement import settings
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .medium))
                        Text("Import Settings")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(DesignColors.info)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignColors.info.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onHover { hovering in
            hoveredSection = hovering ? "advanced" : nil
        }
    }

    // MARK: - Actions

    private func resetToDefaults() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            settingsManager.resetToDefaults()
        }
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let isHovered: Bool
    let content: Content

    init(title: String, icon: String, iconColor: Color, isHovered: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.isHovered = isHovered
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 28, height: 28)

                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)
            }

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? DesignColors.snow.opacity(0.6) : DesignColors.snow.opacity(0.3))
                .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 8 : 4, x: 0, y: 2)
        )
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(DesignColors.iron)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: DesignColors.coral))
        }
    }
}

// MARK: - Slider Row

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)

                Spacer()

                Text(String(format: format, value))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignColors.coral)
            }

            Slider(value: $value, in: range, step: 1)
                .tint(DesignColors.coral)
        }
    }
}

// MARK: - Reset Confirmation Context

struct ResetConfirmationContext {
    // Context for reset confirmation alert
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settingsManager: AppSettingsManager.shared)
            .frame(width: 580, height: 520)
    }
}
#endif
