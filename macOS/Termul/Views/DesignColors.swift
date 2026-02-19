//
//  DesignColors.swift
//  Termul
//
//  Modern sophisticated color system with gradients and visual hierarchy
//

import SwiftUI
import AppKit

/// Advanced color system with semantic naming, gradients, and opacity variants
struct DesignColors {

    // MARK: - Environment Detection

    /// Returns whether dark mode is currently active
    static var isDarkMode: Bool {
        NSAppearance.current.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    // MARK: - Base Colors

    /// Primary background color (adapted to dark mode)
    static var background: Color {
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 0.99)
    }

    /// Surface color for cards and panels (adapted to dark mode)
    static var surface: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color.white
    }

    /// Elevated surface color (for hovered/focused elements)
    static var surfaceElevated: Color {
        isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color(red: 1.0, green: 1.0, blue: 1.0)
    }

    /// Border/separator color
    static var border: Color {
        isDarkMode ? Color(red: 0.25, green: 0.25, blue: 0.27) : Color(red: 0.90, green: 0.90, blue: 0.92)
    }

    /// Subtle divider color
    static var divider: Color {
        isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.24) : Color(red: 0.94, green: 0.94, blue: 0.96)
    }

    // MARK: - Text Colors

    /// Primary text for headings and important content
    static var textPrimary: Color {
        isDarkMode ? Color(red: 0.98, green: 0.98, blue: 0.99) : Color(red: 0.11, green: 0.11, blue: 0.13)
    }

    /// Secondary text for body content
    static var textSecondary: Color {
        isDarkMode ? Color(red: 0.72, green: 0.72, blue: 0.75) : Color(red: 0.45, green: 0.45, blue: 0.47)
    }

    /// Tertiary text for labels and hints
    static var textTertiary: Color {
        isDarkMode ? Color(red: 0.55, green: 0.55, blue: 0.58) : Color(red: 0.65, green: 0.65, blue: 0.67)
    }

    /// Muted text for disabled elements
    static var textMuted: Color {
        isDarkMode ? Color(red: 0.40, green: 0.40, blue: 0.42) : Color(red: 0.80, green: 0.80, blue: 0.82)
    }

    // MARK: - Primary Brand Colors

    /// Primary brand color - sophisticated coral
    static let primary = Color(red: 0.95, green: 0.55, blue: 0.48)
    static let primaryLight = Color(red: 0.98, green: 0.75, blue: 0.70)
    static let primaryDark = Color(red: 0.85, green: 0.40, blue: 0.35)

    /// Secondary brand color - elegant purple
    static let secondary = Color(red: 0.62, green: 0.55, blue: 0.82)
    static let secondaryLight = Color(red: 0.78, green: 0.72, blue: 0.92)
    static let secondaryDark = Color(red: 0.48, green: 0.42, blue: 0.68)

    /// Tertiary brand color - refined teal
    static let tertiary = Color(red: 0.38, green: 0.72, blue: 0.68)
    static let tertiaryLight = Color(red: 0.58, green: 0.85, blue: 0.82)
    static let tertiaryDark = Color(red: 0.28, green: 0.58, blue: 0.55)

    // MARK: - Semantic Colors

    /// Success state - refined green
    static let success = Color(red: 0.42, green: 0.75, blue: 0.52)
    static let successLight = Color(red: 0.68, green: 0.88, blue: 0.75)
    static let successDark = Color(red: 0.32, green: 0.58, blue: 0.40)

    /// Warning state - warm amber
    static let warning = Color(red: 0.95, green: 0.72, blue: 0.32)
    static let warningLight = Color(red: 0.98, green: 0.88, blue: 0.62)
    static let warningDark = Color(red: 0.82, green: 0.58, blue: 0.22)

    /// Error state - soft red
    static let error = Color(red: 0.92, green: 0.48, blue: 0.48)
    static let errorLight = Color(red: 0.96, green: 0.72, blue: 0.72)
    static let errorDark = Color(red: 0.78, green: 0.32, blue: 0.32)

    /// Info state - calm blue
    static let info = Color(red: 0.42, green: 0.62, blue: 0.85)
    static let infoLight = Color(red: 0.68, green: 0.82, blue: 0.95)
    static let infoDark = Color(red: 0.28, green: 0.45, blue: 0.68)

    // MARK: - Special Purpose Colors

    /// Git branch indicator - sage
    static let gitBranch = Color(red: 0.52, green: 0.72, blue: 0.58)

    /// Terminal accent - midnight blue
    static let terminal = Color(red: 0.32, green: 0.38, blue: 0.52)

    /// Process running - vibrant green
    static let running = Color(red: 0.38, green: 0.78, blue: 0.55)

    /// Process stopped - neutral gray
    static let stopped = Color(red: 0.58, green: 0.60, blue: 0.65)

    /// Process failed - alert red
    static let failed = Color(red: 0.88, green: 0.38, blue: 0.38)

    /// Memory indicator - calm purple
    static let memory = Color(red: 0.68, green: 0.52, blue: 0.85)

    /// Rose accent for decorative elements
    static let rose = Color(red: 0.92, green: 0.58, blue: 0.68)

    /// Coral accent for call-to-actions
    static let coral = Color(red: 0.95, green: 0.58, blue: 0.52)

    // MARK: - Gradient Definitions

    /// Primary gradient (coral to peach)
    static let gradientPrimary = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Secondary gradient (purple to lavender)
    static let gradientSecondary = LinearGradient(
        colors: [secondary, secondaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Success gradient (green to mint)
    static let gradientSuccess = LinearGradient(
        colors: [success, successLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Info gradient (blue to sky)
    static let gradientInfo = LinearGradient(
        colors: [info, infoLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warning gradient (amber to yellow)
    static let gradientWarning = LinearGradient(
        colors: [warning, warningLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Error gradient (red to rose)
    static let gradientError = LinearGradient(
        colors: [error, errorLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle background gradient
    static let gradientBackground = LinearGradient(
        colors: [
            isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 0.99),
            isDarkMode ? Color(red: 0.13, green: 0.13, blue: 0.14) : Color.white
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card gradient for depth
    static let gradientCard = LinearGradient(
        colors: [
            isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.20) : Color.white,
            isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.17) : Color(red: 0.98, green: 0.98, blue: 0.99)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Opacity Variants

    /// Surface with low opacity (for overlays)
    static func surface(_ opacity: Double) -> Color {
        surface.opacity(opacity)
    }

    /// Primary brand color with opacity
    static func primary(_ opacity: Double) -> Color {
        primary.opacity(opacity)
    }

    /// Secondary brand color with opacity
    static func secondary(_ opacity: Double) -> Color {
        secondary.opacity(opacity)
    }

    /// Tertiary brand color with opacity
    static func tertiary(_ opacity: Double) -> Color {
        tertiary.opacity(opacity)
    }

    /// Success color with opacity
    static func success(_ opacity: Double) -> Color {
        success.opacity(opacity)
    }

    /// Warning color with opacity
    static func warning(_ opacity: Double) -> Color {
        warning.opacity(opacity)
    }

    /// Error color with opacity
    static func error(_ opacity: Double) -> Color {
        error.opacity(opacity)
    }

    /// Info color with opacity
    static func info(_ opacity: Double) -> Color {
        info.opacity(opacity)
    }

    // MARK: - Helper Functions

    /// Returns the appropriate color for a given group color
    static func colorForGroupColor(_ groupColor: GroupColor) -> Color {
        switch groupColor {
        case .red: return error
        case .orange: return warning
        case .yellow: return warning
        case .green: return gitBranch
        case .blue: return info
        case .purple: return secondary
        case .pink: return rose
        case .teal: return tertiary
        }
    }

    /// Returns the gradient for a given group color
    static func gradientForGroupColor(_ groupColor: GroupColor) -> LinearGradient {
        switch groupColor {
        case .red: return gradientError
        case .orange: return gradientWarning
        case .yellow: return gradientWarning
        case .green: return LinearGradient(
            colors: [gitBranch, gitBranch.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case .blue: return gradientInfo
        case .purple: return gradientSecondary
        case .pink: return LinearGradient(
            colors: [rose, rose.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case .teal: return LinearGradient(
            colors: [tertiary, tertiaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        }
    }

    /// Returns the color for a given process status
    static func colorForProcessStatus(_ status: ProcessStatus) -> Color {
        switch status {
        case .idle: return textTertiary
        case .running: return running
        case .stopped: return stopped
        case .failed: return failed
        }
    }

    /// Returns the background color for a process status indicator
    static func backgroundColorForProcessStatus(_ status: ProcessStatus) -> Color {
        switch status {
        case .idle: return textTertiary.opacity(0.1)
        case .running: return running.opacity(0.15)
        case .stopped: return stopped.opacity(0.15)
        case .failed: return failed.opacity(0.15)
        }
    }

    /// Returns color based on memory usage level
    static func colorForMemoryUsage(_ usage: UInt64) -> Color {
        let mb = usage / (1024 * 1024)
        switch mb {
        case 0..<500: return success
        case 500..<1024: return warning
        case 1024..<2048: return error
        default: return errorDark
        }
    }

    /// Returns gradient for memory usage
    static func gradientForMemoryUsage(_ usage: UInt64) -> LinearGradient {
        let baseColor = colorForMemoryUsage(usage)
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Legacy Compatibility

    /// Legacy compatibility - maps old color names to new system
    static let white = background
    static let snow = surface
    static let rausch = textPrimary
    static let iron = textSecondary
    static let linen = divider
}

// MARK: - Color Extension for Shadows

extension Color {
    /// Returns a shadow color with the specified opacity
    func shadowColor(_ opacity: Double = 0.1) -> Color {
        self.opacity(opacity)
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// Creates a subtle gradient for backgrounds
    static func subtle(from start: Color, to end: Color) -> LinearGradient {
        LinearGradient(
            colors: [start, end],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Creates a vibrant gradient for buttons and accents
    static func vibrant(from start: Color, to end: Color) -> LinearGradient {
        LinearGradient(
            colors: [start, end],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
