//
//  OnboardingView.swift
//  Termul
//
//  Onboarding experience consistent with app design
//

import SwiftUI

// OnboardingPage is defined in Models/OnboardingPage.swift
// OnboardingViewModel is defined in ViewModels/OnboardingViewModel.swift
// MARK: - Onboarding View

struct OnboardingView: View {
    // MARK: - Properties

    @StateObject private var viewModel: OnboardingViewModel
    @State private var hoveredPageIndex: Int? = nil

    // MARK: - Initialization

    init() {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            DesignColors.gradientBackground
                .ignoresSafeArea()

            // Decorative background elements
            backgroundDecorations
                .opacity(0.4)

            VStack(spacing: 0) {
                // Header with close button
                header

                Spacer()

                // Main content
                mainContent

                Spacer()

                // Page indicator
                pageIndicator

                // Navigation
                navigationButtons
            }
            .padding(32)
        }
        .frame(width: 680, height: 520)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DesignColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignColors.border, lineWidth: 0.5)
                )
                .shadow(color: Color.black.shadowColor(0.08), radius: 24, x: 0, y: 12)
        )
        .opacity(viewModel.isDismissing ? 0 : 1)
        .scaleEffect(viewModel.isDismissing ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.3), value: viewModel.isDismissing)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                viewModel.contentOpacity = 1.0
                viewModel.iconScale = 1.0
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignColors.gradientPrimary)
                            .frame(width: 32, height: 32)
                            .shadow(color: DesignColors.primary.shadowColor(0.3), radius: 6, x: 0, y: 3)

                        Image(systemName: "terminal.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Termul")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(DesignColors.textPrimary)
                }

                Text("Setup Guide")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignColors.textSecondary)
            }

            Spacer()

            Button(action: {
                viewModel.skipOnboarding()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.surface.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignColors.border, lineWidth: 0.5)
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignColors.textSecondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                // Add hover effect if needed
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Background Decorations

    private var backgroundDecorations: some View {
        ZStack {
            // Top right circle
            Circle()
                .fill(DesignColors.primary.opacity(0.08))
                .frame(width: 220, height: 220)
                .offset(x: 160, y: -160)

            // Bottom left circle
            Circle()
                .fill(DesignColors.secondary.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: -140, y: 140)

            // Middle accent
            Circle()
                .fill(DesignColors.tertiary.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: 100, y: 60)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(viewModel.currentPage.accentColor.opacity(0.12))
                    .frame(width: 130, height: 130)
                    .blur(radius: 2)

                // Main circle
                Circle()
                    .fill(viewModel.currentPage.accentColor.opacity(0.16))
                    .frame(width: 110, height: 110)

                // Icon
                Image(systemName: viewModel.currentPage.iconName)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(viewModel.currentPage.accentColor)
                    .shadow(color: viewModel.currentPage.accentColor.shadowColor(0.25), radius: 12, x: 0, y: 6)
            }
            .scaleEffect(viewModel.iconScale)
            .animation(.spring(response: 0.6, dampingFraction: 0.5), value: viewModel.iconScale)

            // Text content
            VStack(spacing: 16) {
                Text(viewModel.currentPage.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(viewModel.contentOpacity)

                Text(viewModel.currentPage.description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(DesignColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: 440)
                    .opacity(viewModel.contentOpacity)
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        index == viewModel.currentPageIndex
                            ? viewModel.currentPage.accentColor
                            : DesignColors.divider
                    )
                    .frame(
                        width: index == viewModel.currentPageIndex ? 36 : 6,
                        height: 5
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.currentPageIndex)
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredPageIndex = hovering ? index : nil
                        }
                    }
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Previous button
            if !viewModel.isFirstPage {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.previousPage()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(DesignColors.textSecondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignColors.surface.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(DesignColors.border, lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            // Primary action button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    viewModel.nextPage()
                }
            }) {
                HStack(spacing: 8) {
                    Text(viewModel.isLastPage ? "Get Started" : "Continue")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))

                    if !viewModel.isLastPage {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            viewModel.currentPage.accentColor,
                            viewModel.currentPage.accentColor.opacity(0.85)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: viewModel.currentPage.accentColor.shadowColor(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// Notification.Name.onboardingCompleted is defined in ViewModels/OnboardingViewModel.swift

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .frame(width: 680, height: 520)
            .preferredColorScheme(.light)

        OnboardingView()
            .frame(width: 680, height: 520)
            .preferredColorScheme(.dark)
    }
}
