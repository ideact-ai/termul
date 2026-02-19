//
//  DeleteProjectConfirmationView.swift
//  Termul
//
//  Created by Service Helper
//

import SwiftUI

/// Confirmation view for deleting a project that requires typing the project title
struct DeleteProjectConfirmationView: View {
    // MARK: - Properties

    let project: Project
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var typedTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Computed Properties

    private var isConfirmEnabled: Bool {
        typedTitle.trimmingCharacters(in: .whitespacesAndNewlines) == project.name
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // Header with warning icon
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(DesignColors.error.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: "trash.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(DesignColors.error)
                }

                VStack(spacing: 4) {
                    Text("Delete Project")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(DesignColors.rausch)

                    Text("This action cannot be undone")
                        .font(.system(size: 12))
                        .foregroundColor(DesignColors.iron)
                }
            }

            // Project info
            VStack(alignment: .leading, spacing: 8) {
                Text("You are about to delete:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignColors.iron)

                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                        .foregroundColor(DesignColors.coral)

                    Text(project.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignColors.rausch)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.snow)
                )
            }

            // Typing confirmation
            VStack(alignment: .leading, spacing: 8) {
                Text("Type the project name to confirm:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignColors.iron)

                TextField("Project name", text: $typedTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 13, design: .rounded))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if isConfirmEnabled {
                            onConfirm()
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                typedTitle.isEmpty ? Color.clear : (isConfirmEnabled ? DesignColors.success : DesignColors.error),
                                lineWidth: 2
                            )
                    )

                // Match indicator
                if !typedTitle.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: isConfirmEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(isConfirmEnabled ? DesignColors.success : DesignColors.error)

                        Text(isConfirmEnabled ? "Project names match" : "Project names do not match")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isConfirmEnabled ? DesignColors.success : DesignColors.error)
                    }
                    .transition(.opacity)
                }
            }

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignColors.rausch)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignColors.snow)
                        )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onConfirm) {
                    Text("Delete Project")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isConfirmEnabled ? DesignColors.error : DesignColors.iron.opacity(0.3))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isConfirmEnabled)
            }
        }
        .padding(24)
        .frame(width: 380)
        .background(DesignColors.white)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
