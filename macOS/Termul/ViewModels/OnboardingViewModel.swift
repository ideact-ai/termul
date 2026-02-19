//
//  OnboardingViewModel.swift
//  Termul
//
//  ViewModel for managing the onboarding experience
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing the onboarding flow
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current page index being displayed
    @Published var currentPageIndex: Int = 0

    /// Whether the onboarding is currently being dismissed
    @Published var isDismissing: Bool = false

    /// Animation offset for transitions
    @Published var dragOffset: CGFloat = 0

    /// Scale factor for icon animation
    @Published var iconScale: CGFloat = 1.0

    /// Opacity for content reveal
    @Published var contentOpacity: Double = 0.0

    // MARK: - Properties

    /// All onboarding pages
    private let pages: [OnboardingPage]

    /// App settings manager
    private let settingsManager: AppSettingsManager

    /// Timer for icon animation
    private var animationTimer: Timer?

    // MARK: - Computed Properties

    /// The current onboarding page
    var currentPage: OnboardingPage {
        pages[currentPageIndex]
    }

    /// Total number of pages
    var totalPages: Int {
        pages.count
    }

    /// Progress through onboarding (0.0 to 1.0)
    var progress: Double {
        Double(currentPageIndex + 1) / Double(totalPages)
    }

    /// Whether this is the last page
    var isLastPage: Bool {
        currentPageIndex == totalPages - 1
    }

    /// Whether this is the first page
    var isFirstPage: Bool {
        currentPageIndex == 0
    }

    // MARK: - Initialization

    /// Creates a new onboarding view model
    /// - Parameter pages: The onboarding pages to display (defaults to OnboardingPage.defaultPages)
    init(pages: [OnboardingPage] = OnboardingPage.defaultPages) {
        self.pages = pages
        self.settingsManager = AppSettingsManager.shared

        // Start content animation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.contentOpacity = 1.0
        }

        // Start icon pulsing animation
        startIconAnimation()
    }

    // MARK: - Navigation

    /// Moves to the next page
    func nextPage() {
        guard !isLastPage else {
            completeOnboarding()
            return
        }

        // Animate transition
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPageIndex += 1
            dragOffset = -50
        }

        // Reset offset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self?.dragOffset = 0
            }
        }

        // Animate content reveal
        animateContentReveal()
    }

    /// Moves to the previous page
    func previousPage() {
        guard !isFirstPage else {
            return
        }

        // Animate transition
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPageIndex -= 1
            dragOffset = 50
        }

        // Reset offset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                self?.dragOffset = 0
            }
        }

        // Animate content reveal
        animateContentReveal()
    }

    /// Skips to the end and completes onboarding
    func skipOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) { [weak self] in
            self?.isDismissing = true
        }

        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.completeOnboarding()
        }
    }

    /// Completes the onboarding experience
    func completeOnboarding() {
        // Update settings to mark onboarding as complete
        settingsManager.update { settings in
            settings.hasCompletedOnboarding = true
        }

        // Post notification to dismiss onboarding window
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }

    // MARK: - Animations

    /// Animates the content reveal on page change
    private func animateContentReveal() {
        // Fade out
        withAnimation(.easeOut(duration: 0.2)) { [weak self] in
            self?.contentOpacity = 0.0
        }

        // Fade in with slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            withAnimation(.easeOut(duration: 0.4)) {
                self?.contentOpacity = 1.0
            }
        }
    }

    /// Starts the icon pulsing animation
    private func startIconAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Subtle scale up
            withAnimation(.easeInOut(duration: 1.5)) {
                self.iconScale = 1.05
            }

            // Scale down
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    self.iconScale = 1.0
                }
            }
        }
    }

    /// Stops the icon animation timer
    nonisolated func stopAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    /// Handles gesture-based page navigation
    /// - Parameter translation: The drag translation value
    func handleDrag(_ translation: CGFloat) {
        // Allow drag to update offset visually
        dragOffset = translation * 0.3
    }

    /// Handles drag end and determines if page change should occur
    /// - Parameter translation: The final drag translation value
    func handleDragEnd(_ translation: CGFloat) {
        // Threshold for page change (in points)
        let threshold: CGFloat = 100

        if translation > threshold {
            // Swiped right - go to previous page
            previousPage()
        } else if translation < -threshold {
            // Swiped left - go to next page
            nextPage()
        } else {
            // Not enough drag - reset offset
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = 0
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        stopAnimations()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when onboarding is completed
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}
