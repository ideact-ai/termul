//
//  GroupConfigurationView.swift
//  Termul
//

import SwiftUI

/// View for managing project groups
struct GroupConfigurationView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: GroupConfigurationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGroupId: UUID?
    @State private var isCreatingNew = false
    @State private var hoveredGroupId: UUID?
    @State private var hoveredProjectId: UUID?
    @State private var hoveredButton: String?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
            Rectangle()
                .fill(DesignColors.linen)
                .frame(width: 1)
            detailView
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(DesignColors.white)
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            sidebarHeader
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(viewModel.groups) { group in
                        GroupListItem(group: group, isSelected: selectedGroupId == group.id)
                    }
                }
            }
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Groups")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(DesignColors.rausch)
                    Text("\(viewModel.groups.count) groups")
                        .font(.system(size: 10))
                        .foregroundColor(DesignColors.iron)
                }
                Spacer()
                Button(action: {
                    selectedGroupId = nil
                    isCreatingNew = true
                    viewModel.resetForm()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignColors.coral)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Rectangle()
                .fill(DesignColors.linen)
                .frame(height: 1)
        }
    }

    private var detailView: some View {
        Group {
            if selectedGroupId != nil || isCreatingNew {
                detailForm
            } else {
                emptyDetail
            }
        }
    }

    private var detailForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailFormHeader
            Rectangle()
                .fill(DesignColors.linen)
                .frame(height: 1)
            detailFormContent
        }
    }

    private var detailFormHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignColors.colorForGroupColor(viewModel.selectedColor))
                    .frame(width: 32, height: 32)

                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(isCreatingNew ? "New Group" : "Edit Group")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)
                Text("Configure group properties")
                    .font(.system(size: 10))
                    .foregroundColor(DesignColors.iron)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var detailFormContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let success = viewModel.successMessage {
                    FormBanner(text: success, isError: false)
                }
                if let error = viewModel.errorMessage {
                    FormBanner(text: error, isError: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Group Name")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DesignColors.rausch)

                    TextField("Enter group name", text: $viewModel.groupName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DesignColors.snow)
                        .cornerRadius(6)
                }

                Text("Color")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignColors.rausch)

                colorPicker
            }
            .padding(20)
        }
    }

    private var colorPicker: some View {
        HStack(spacing: 8) {
            ForEach(GroupColor.allCases, id: \.self) { color in
                ColorPickerDot(
                    color: DesignColors.colorForGroupColor(color),
                    isSelected: viewModel.selectedColor == color,
                    action: {
                        viewModel.selectedColor = color
                    }
                )
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyDetail: some View {
        VStack(spacing: 12) {
            Spacer()
            ZStack {
                Circle()
                    .fill(DesignColors.iron.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(DesignColors.iron.opacity(0.4))
            }
            Text("Select a group or create a new one")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignColors.iron)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }

    private var detailFormFooter: some View {
        HStack(spacing: 12) {
            if !isCreatingNew {
                Button(action: {
                    if let groupId = selectedGroupId,
                       let group = viewModel.groups.first(where: { $0.id == groupId }) {
                        viewModel.loadGroup(group)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(action: {
                selectedGroupId = nil
                isCreatingNew = false
                viewModel.resetForm()
            }) {
                Text("Cancel")
            }
            .buttonStyle(.bordered)

            Button(action: {
                if viewModel.save() {
                    selectedGroupId = nil
                    isCreatingNew = false
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                    Text(isCreatingNew ? "Create Group" : "Save Changes")
                }
            }
            .buttonStyle(.borderedProminent)
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

// MARK: - Group List Item

struct GroupListItem: View {
    let group: ProjectGroup
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(DesignColors.colorForGroupColor(group.color))
                    .frame(width: 20, height: 20)
            }

            Text(group.name)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? DesignColors.rausch : DesignColors.iron)
                .lineLimit(1)

            Spacer()

            if !group.projectIds.isEmpty {
                Text("\(group.projectIds.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignColors.linen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(DesignColors.iron.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? DesignColors.snow : (isHovered ? DesignColors.snow.opacity(0.5) : Color.clear))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Color Picker Dot

struct ColorPickerDot: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                    .scaleEffect(isSelected ? 1.05 : (isHovered ? 1.02 : 1.0))
                    .overlay(
                        Circle()
                            .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 4)
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}

struct FormBanner: View {
    let text: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
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
}

#if DEBUG
struct GroupConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        GroupConfigurationView(viewModel: GroupConfigurationViewModel(projectManager: ProjectManager()))
            .frame(minWidth: 700, minHeight: 500)
    }
}
#endif
