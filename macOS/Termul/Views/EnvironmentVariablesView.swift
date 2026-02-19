//
//  EnvironmentVariablesView.swift
//  Termul
//
//  Created by Service Helper
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// View model for managing environment variables for a specific project
class EnvironmentVariablesViewModel: ObservableObject {
    // MARK: - Published Properties

    /// The project being configured
    @Published var project: Project {
        didSet {
            // Sync environment variables when project is updated
            environmentVariables = project.environmentVariables
        }
    }

    /// Environment variables for project
    @Published var environmentVariables: [EnvironmentVariable] = []

    /// Indicates if a save operation is in progress
    @Published var isLoading: Bool = false

    /// General error message
    @Published var errorMessage: String?

    /// Success message after successful save
    @Published var successMessage: String?

    // MARK: - Dependencies

    private let projectManager: ProjectManager

    // MARK: - Initialization

    init(project: Project, projectManager: ProjectManager = ProjectManager()) {
        self.project = project
        self.projectManager = projectManager
        self.environmentVariables = project.environmentVariables
    }

    // MARK: - Public Methods

    /// Saves() environment variables to the project
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func save() -> Bool {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        // Update project with new environment variables
        var updatedProject = project
        updatedProject.environmentVariables = environmentVariables.filter { $0.isValid }

        let success = projectManager.updateProject(updatedProject)
        isLoading = false

        if success {
            // Update the local project reference, which triggers didSet to sync environmentVariables
            project = updatedProject
            successMessage = "Environment variables saved successfully"
            return true
        } else {
            errorMessage = projectManager.lastError?.localizedDescription ?? "Failed to save environment variables"
            return false
        }
    }

    /// Adds a new empty environment variable
    func addEnvironmentVariable() {
        let newEnvVar = EnvironmentVariable(key: "", value: "")
        environmentVariables.append(newEnvVar)
    }

    /// Removes an environment variable
    /// - Parameter index: The index of the environment variable to remove
    func removeEnvironmentVariable(at index: Int) {
        guard index >= 0 && index < environmentVariables.count else { return }
        environmentVariables.remove(at: index)
    }

    /// Updates the key of an environment variable
    /// - Parameters:
    ///   - index: The index of the environment variable
    ///   - key: The new key value
    func updateEnvironmentVariableKey(at index: Int, key: String) {
        guard index >= 0 && index < environmentVariables.count else { return }
        environmentVariables[index].key = key
    }

    /// Updates the value of an environment variable
    /// - Parameters:
    ///   - index: The index of the environment variable
    ///   - value: The new value
    func updateEnvironmentVariableValue(at index: Int, value: String) {
        guard index >= 0 && index < environmentVariables.count else { return }
        environmentVariables[index].value = value
    }

    /// Imports environment variables from a .env file
    /// - Parameter url: The URL to the .env file
    /// - Returns: true if import was successful, false otherwise
    @discardableResult
    func importFromEnvFile(url: URL) -> Bool {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            var importedCount = 0

            for line in content.components(separatedBy: .newlines) {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)

                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }

                // Parse KEY=VALUE format
                let components = trimmedLine.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                guard components.count == 2 else { continue }

                let key = String(components[0]).trimmingCharacters(in: .whitespaces)
                let value = String(components[1]).trimmingCharacters(in: .whitespaces)

                // Skip if key or value is empty
                guard !key.isEmpty else { continue }

                // Check if this env var already exists
                if let existingIndex = environmentVariables.firstIndex(where: { $0.key == key }) {
                    // Update existing
                    environmentVariables[existingIndex].value = value
                } else {
                    // Add new
                    let newEnvVar = EnvironmentVariable(key: key, value: value)
                    environmentVariables.append(newEnvVar)
                    importedCount += 1
                }
            }

            if importedCount > 0 {
                successMessage = "Imported \(importedCount) environment variable\(importedCount > 1 ? "s" : "")"
            }
            return importedCount > 0
        } catch {
            errorMessage = "Failed to read .env file: \(error.localizedDescription)"
            return false
        }
    }

    /// Opens a file picker to select a .env file to import
    func selectEnvFileToImport() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Select .env File"
        panel.prompt = "Import"
        panel.message = "Choose a .env file to import environment variables from"
        if let envType = UTType(filenameExtension: "env") {
            panel.allowedContentTypes = [envType]
        }

        if panel.runModal() == .OK, let url = panel.url {
            importFromEnvFile(url: url)
        }
    }
}

/// Environment variables configuration view for quick access from project list
struct EnvironmentVariablesView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: EnvironmentVariablesViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    // Banner messages
                    if let success = viewModel.successMessage {
                        banner(text: success, isError: false)
                    }
                    if let errorMsg = viewModel.errorMessage {
                        banner(text: errorMsg, isError: true)
                    }

                    // Project info
                    projectInfoSection

                    // Environment variables list
                    environmentVariablesSection
                }
                .padding(20)
            }

            footer
        }
        .frame(width: 520, height: 480)
        .background(DesignColors.white)
        .onDisappear {
            // Auto-save when dismissing
            if viewModel.environmentVariables != viewModel.project.environmentVariables {
                viewModel.save()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignColors.warning)
                    .frame(width: 32, height: 32)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Environment Variables")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Text("Configure variables for: \(viewModel.project.name)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.13, green: 0.13, blue: 0.16))
    }

    // MARK: - Project Info Section

    private var projectInfoSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignColors.warning.opacity(0.8))

            Text(viewModel.project.path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignColors.iron.opacity(0.08))
        )
    }

    // MARK: - Environment Variables Section

    private var environmentVariablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Variables")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                HStack(spacing: 6) {
                    // Add button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.addEnvironmentVariable()
                        }
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
                                .fill(DesignColors.success.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignColors.success.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Import button
                    Button(action: {
                        viewModel.selectEnvFileToImport()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 9, weight: .bold))
                            Text("Import .env")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(DesignColors.coral)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(DesignColors.coral.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignColors.coral.opacity(0.3), lineWidth: 1)
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
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.03))
                    )
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.environmentVariables.enumerated()), id: \.element.id) { index, envVar in
                        environmentVariableRow(index: index, envVar: envVar)
                    }
                }
            }
        }
    }

    private func environmentVariableRow(index: Int, envVar: EnvironmentVariable) -> some View {
        HStack(spacing: 8) {
            // Key field
            VStack(alignment: .leading, spacing: 4) {
                Text("Key")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                TextField("e.g., NODE_ENV", text: Binding(
                    get: { envVar.key },
                    set: { viewModel.updateEnvironmentVariableKey(at: index, key: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(envVar.key.isEmpty ? DesignColors.error.opacity(0.4) : .white.opacity(0.08), lineWidth: 1)
                        )
                )
            }

            Image(systemName: "equal")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .padding(.horizontal, 2)

            // Value field
            VStack(alignment: .leading, spacing: 4) {
                Text("Value")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                TextField("e.g., development", text: Binding(
                    get: { envVar.value },
                    set: { viewModel.updateEnvironmentVariableValue(at: index, value: $0) }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(envVar.value.isEmpty ? DesignColors.error.opacity(0.4) : .white.opacity(0.08), lineWidth: 1)
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
                    .foregroundColor(DesignColors.error.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Remove environment variable")
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()

            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.08))
                    )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                if viewModel.save() {
                    dismiss()
                }
            }) {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .controlSize(.small)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.success)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.13, green: 0.13, blue: 0.16))
    }

    // MARK: - Banner

    private func banner(text: String, isError: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12))
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
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Preview

struct EnvironmentVariablesView_Previews: PreviewProvider {
    static var previews: some View {
        let project = Project(
            name: "Test Project",
            path: "/Users/test/project",
            command: "npm run dev"
        )
        EnvironmentVariablesView(viewModel: EnvironmentVariablesViewModel(project: project))
    }
}
