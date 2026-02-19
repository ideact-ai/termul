//
//  ConfigurationView.swift
//  Termul
//

import SwiftUI
import AppKit

// MARK: - Premium Form Field (reusable)

struct PremiumFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var error: String?
    var icon: String = "textformat"
    var iconColor: Color = DesignColors.info

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.snow.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isFocused ? DesignColors.info.opacity(0.5) :
                                    (error != nil ? DesignColors.error.opacity(0.5) : DesignColors.linen),
                                    lineWidth: isFocused ? 1.5 : 1
                                )
                        )
                )
                .focused($isFocused)
                .animation(.easeInOut(duration: 0.15), value: isFocused)

            if let error = error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 10))
                }
                .foregroundColor(DesignColors.error)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// View for adding and editing project configurations
struct ConfigurationView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: ConfigurationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hoveredButton: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                formContent
                    .padding(24)
            }

            footer
        }
        .frame(width: 480, height: 520)
        .background(DesignColors.white)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignColors.info)
                    .frame(width: 32, height: 32)

                Image(systemName: viewModel.isEditing ? "pencil.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.isEditing ? "Edit Project" : "New Project")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)

                Text(viewModel.isEditing ? "Update project configuration" : "Configure a new project")
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

    // MARK: - Form Content

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Banners
            if let success = viewModel.successMessage {
                banner(text: success, isError: false)
            }
            if let errorMsg = viewModel.errorMessage {
                banner(text: errorMsg, isError: true)
            }

            // Name
            PremiumFormField(
                title: "Project Name",
                placeholder: "e.g., My API Server",
                text: $viewModel.projectName,
                error: viewModel.nameError,
                icon: "tag.fill",
                iconColor: DesignColors.info
            )

            // Path
            pathField

            // Command
            PremiumFormField(
                title: "Shell Command",
                placeholder: "e.g., npm run dev",
                text: $viewModel.command,
                error: viewModel.commandError,
                icon: "terminal.fill",
                iconColor: DesignColors.gitBranch
            )

            // Description
            descriptionField

            // Group selection
            groupSelector

            // Environment variables
            environmentVariablesSection
        }
    }

    // MARK: - Environment Variables Section

    private var environmentVariablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.warning)
                Text("Environment Variables")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)
                Text("Optional")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(DesignColors.iron)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DesignColors.linen.opacity(0.3)))

                Spacer()

                HStack(spacing: 6) {
                    Button(action: {
                        viewModel.addEnvironmentVariable()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                            Text("Add")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(DesignColors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(DesignColors.success.opacity(0.3), lineWidth: 1)
                                .background(Capsule().fill(DesignColors.success.opacity(0.05)))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        viewModel.selectEnvFileToImport()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 9, weight: .bold))
                            Text("Import .env")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(DesignColors.info)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(DesignColors.info.opacity(0.3), lineWidth: 1)
                                .background(Capsule().fill(DesignColors.info.opacity(0.05)))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Import environment variables from a .env file")
                }
            }

            if viewModel.environmentVariables.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("No environment variables configured")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(DesignColors.iron)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignColors.linen.opacity(0.3))
                    )
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.environmentVariables.enumerated()), id: \.element.id) { index, envVar in
                        environmentVariableRow(index: index, envVar: envVar)
                    }
                }
            }

            Text("These variables will be exported before running your project command. Use export format: export KEY=VALUE")
                Text("Optional: Assign this project to a group for easier management")
                    .font(.system(size: 9))
                    .foregroundColor(DesignColors.iron)
            }
        }

    private func environmentVariableRow(index: Int, envVar: EnvironmentVariable) -> some View {
        HStack(spacing: 8) {
            // Key field
            VStack(alignment: .leading, spacing: 4) {
                Text("Key")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignColors.iron)

                TextField("e.g., NODE_ENV", text: Binding(
                    get: { envVar.key },
                    set: { viewModel.updateEnvironmentVariableKey(at: index, key: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignColors.snow.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(envVar.key.isEmpty ? DesignColors.error.opacity(0.5) : DesignColors.linen, lineWidth: 1)
                        )
                )
            }

            Image(systemName: "equal")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignColors.iron)
                .padding(.horizontal, 2)

            // Value field
            VStack(alignment: .leading, spacing: 4) {
                Text("Value")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignColors.iron)

                TextField("e.g., development", text: Binding(
                    get: { envVar.value },
                    set: { viewModel.updateEnvironmentVariableValue(at: index, value: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignColors.snow.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(envVar.value.isEmpty ? DesignColors.error.opacity(0.5) : DesignColors.linen, lineWidth: 1)
                        )
                )
            }

            // Remove button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.removeEnvironmentVariable(at: index)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(DesignColors.error)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Remove environment variable")
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Path Field

    private var pathField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.coral)
                Text("Project Path")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)
            }

            HStack(spacing: 8) {
                TextField("/path/to/project", text: $viewModel.projectPath)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignColors.snow.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        viewModel.pathError != nil ? DesignColors.error.opacity(0.5) : DesignColors.linen,
                                        lineWidth: 1
                                    )
                            )
                    )

                Button(action: { viewModel.selectPath() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                        Text("Browse")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(DesignColors.info)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(DesignColors.info.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            if let error = viewModel.pathError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 9))
                    Text(error)
                        .font(.system(size: 10))
                }
                .foregroundColor(DesignColors.error)
            }
        }
    }

    // MARK: - Description Field

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.gitBranch)
                Text("Description")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)
                Text("Optional")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(DesignColors.iron)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DesignColors.linen.opacity(0.3)))
            }

            TextEditor(text: $viewModel.description)
                .font(.system(size: 12))
                .frame(minHeight: 50, maxHeight: 50)
                .scrollContentBackground(.hidden)
                .foregroundColor(DesignColors.iron)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.snow.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DesignColors.linen, lineWidth: 1)
                        )
                )
                .menuStyle(.borderlessButton)
        }
    }

    // MARK: - Group Selector

    private var groupSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.info)
                Text("Group")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)
                Text("Optional")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(DesignColors.iron)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DesignColors.linen.opacity(0.3)))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    groupPill(title: "None", isSelected: viewModel.selectedGroupId == nil && !viewModel.showNewGroupField) {
                        viewModel.selectedGroupId = nil
                        viewModel.showNewGroupField = false
                    }

                    ForEach(viewModel.availableGroups) { group in
                        groupPill(title: group.name, isSelected: viewModel.selectedGroupId == group.id) {
                            viewModel.selectedGroupId = group.id
                            viewModel.showNewGroupField = false
                        }
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.showNewGroupField = true
                            viewModel.selectedGroupId = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                            Text("New")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(DesignColors.info)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .stroke(DesignColors.info.opacity(0.3), lineWidth: 1)
                                .background(Capsule().fill(DesignColors.info.opacity(0.05)))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if viewModel.showNewGroupField {
                newGroupForm
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func groupPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : DesignColors.iron)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? DesignColors.info : DesignColors.linen.opacity(0.3))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var newGroupForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            PremiumFormField(
                title: "New Group Name",
                placeholder: "e.g., Backend Services",
                text: $viewModel.newGroupName,
                icon: "folder.badge.plus",
                iconColor: DesignColors.info
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignColors.info.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DesignColors.info.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Banner

    private func banner(text: String, isError: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(isError ? DesignColors.warning : DesignColors.success)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isError ? DesignColors.warning : DesignColors.success)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isError ? DesignColors.warning.opacity(0.08) : DesignColors.success.opacity(0.08))
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()

            Button(action: {
                viewModel.resetForm()
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    _ = viewModel.save()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text(viewModel.isEditing ? "Save Changes" : "Add Project")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(!viewModel.isValid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            VStack {
                Rectangle()
                    .fill(DesignColors.linen)
                    .frame(height: 1)
                Spacer()
            }
        )
    }
}
