//
//  OnboardingPage.swift
//  Termul
//
//  Model for onboarding page content
//

import Foundation
import SwiftUI

/// Represents a single page in the onboarding experience
struct OnboardingPage: Identifiable, Equatable {
    /// Unique identifier for the page
    let id: UUID

    /// Title displayed on the page
    let title: String

    /// Detailed description of the feature
    let description: String

    /// SF Symbol icon name for visual representation
    let iconName: String

    /// Accent color for the page
    let accentColor: Color

    /// Creates a new onboarding page
    /// - Parameters:
    ///   - id: Unique identifier (defaults to UUID)
    ///   - title: The page title
    ///   - description: The page description
    ///   - iconName: SF Symbol icon name
    ///   - accentColor: Accent color for the page
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        accentColor: Color
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.accentColor = accentColor
    }

    /// Default onboarding pages for the app
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Termul",
            description: "Your powerful development environment manager. Configure projects, run commands, and monitor processes from one beautiful interface.",
            iconName: "terminal.fill",
            accentColor: DesignColors.primary
        ),
        OnboardingPage(
            title: "Manage Your Projects",
            description: "Add your development projects with custom commands. Group them logically and access them instantly from your menu bar.",
            iconName: "folder.badge.plus",
            accentColor: DesignColors.secondary
        ),
        OnboardingPage(
            title: "Run & Monitor",
            description: "Start and stop processes with one click. View real-time output, track memory usage, and manage git branches effortlessly.",
            iconName: "play.circle.fill",
            accentColor: DesignColors.tertiary
        ),
        OnboardingPage(
            title: "Get Started",
            description: "You're all set! Add your first project and experience the simplicity of managing your development environment.",
            iconName: "rocket.fill",
            accentColor: DesignColors.success
        )
    ]
}
