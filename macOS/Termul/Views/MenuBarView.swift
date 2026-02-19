//
//  MenuBarView.swift
//  Termul
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers



/// Main menu bar dropdown view displaying projects and quick actions
struct MenuBarView: View {
    // MARK: - Properties

    @ObservedObject var viewModel: MenuBarViewModel
    @State private var hoveredProjectId: UUID?
    @State private var hoveredGroupId: UUID?
    @State private var expandedGroups: Set<UUID> = []
    @State private var draggedProjectId: UUID?
    @State private var draggedGroupId: UUID?
    @State private var hoveredFooterAction: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView

            if viewModel.isLoading {
                loadingView
            } else if viewModel.projects.isEmpty {
                emptyStateView
            } else {
                groupedProjectsList
                    .frame(maxHeight: 400)
            }

            Rectangle()
                .fill(DesignColors.linen)
                .frame(height: 1)

            footerActions
        }
        .frame(width: 340)
        .padding(.vertical, 4)
        .background(DesignColors.white)
        .onAppear {
            expandedGroups = Set(viewModel.groups.map { $0.id })
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Termul")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)

                Text("\(viewModel.projects.count) project\(viewModel.projects.count == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignColors.iron)
            }

            Spacer()

            if viewModel.runningProjectId != nil {
                HStack(spacing: 5) {
                    PulsingDot(color: DesignColors.success, size: 7)

                    Text("Running")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DesignColors.success)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(DesignColors.success.opacity(0.15))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DesignColors.snow.opacity(0.5))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.9)
                Text("Loading projects...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignColors.iron)
            }
            Spacer()
        }
        .padding(.vertical, 30)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DesignColors.info.opacity(0.2))
                    .frame(width: 56, height: 56)

                if let nsImage = Bundle.main.image(forResource: "MenuBarIcon") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .opacity(0.6)
                } else {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(DesignColors.info)
                }
            }

            Text("No Projects")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(DesignColors.rausch)
                .frame(maxWidth: .infinity)

            Text("Add your first project to get started")
                .font(.system(size: 12))
                .foregroundColor(DesignColors.iron)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button(action: { viewModel.openConfiguration() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Add Project")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(DesignColors.info)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Grouped Projects List

    private var groupedProjectsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.groups) { group in
                    let groupProjects = viewModel.projects(inGroup: group)
                    if !groupProjects.isEmpty {
                        GroupSection(
                            group: group,
                            projects: groupProjects,
                            isExpanded: expandedGroups.contains(group.id),
                            isGroupRunning: viewModel.isGroupRunning(group),
                            isGroupFullyRunning: viewModel.isGroupFullyRunning(group),
                            hoveredProjectId: hoveredProjectId,
                            hoveredGroupId: hoveredGroupId,
                            draggedProjectId: $draggedProjectId,
                            viewModel: viewModel,
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if expandedGroups.contains(group.id) {
                                        expandedGroups.remove(group.id)
                                    } else {
                                        expandedGroups.insert(group.id)
                                    }
                                }
                            },
                            onRunGroup: { viewModel.runGroup(group) },
                            onStopGroup: { viewModel.stopGroup(group) },
                            onHoverGroup: { isHovered in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredGroupId = isHovered ? group.id : nil
                                }
                            },
                            onHoverProject: { projectId, isHovered in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredProjectId = isHovered ? projectId : nil
                                }
                            },
                            onDeleteProject: { project in
                                viewModel.deleteProject(project)
                            }
                        )

                        Rectangle()
                            .fill(DesignColors.linen)
                            .frame(height: 1)
                            .padding(.horizontal, 12)
                    }
                }

                let ungrouped = viewModel.ungroupedProjects()
                if !ungrouped.isEmpty {
                    if !viewModel.groups.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignColors.iron)

                            Text("Ungrouped")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(DesignColors.iron)

                            Spacer()

                            Text("\(ungrouped.count)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(DesignColors.iron)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(DesignColors.linen.opacity(0.3))
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                    }

                    ForEach(ungrouped) { project in
                        DraggableProjectRow(
                            project: project,
                            status: viewModel.getStatus(for: project),
                            gitBranch: viewModel.projectGitBranches[project.id],
                            isHovered: hoveredProjectId == project.id,
                            draggedProjectId: $draggedProjectId,
                            allProjects: viewModel.projects,
                            viewModel: viewModel,
                            onRun: { viewModel.runProject(project) },
                            onStop: { viewModel.stopProject(project) },
                            onShowLog: { viewModel.showLog(for: project) },
                            onOpenInIDE: { viewModel.openInIDE(project) },
                            onOpenEnvironmentVariables: { viewModel.openEnvironmentVariables(project) },
                            onDelete: {
                                viewModel.deleteProject(project)
                            },
                            onHover: { isHovered in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    hoveredProjectId = isHovered ? project.id : nil
                                }
                            }
                        )

                        if project.id != ungrouped.last?.id {
                            Rectangle()
                                .fill(DesignColors.linen)
                                .frame(height: 1)
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Footer Actions

    private var footerActions: some View {
        VStack(spacing: 2) {
            footerButton(icon: "plus.circle.fill", title: "Add Project", iconColor: DesignColors.coral, id: "add") {
                viewModel.openConfiguration()
            }
            footerButton(icon: "folder.badge.gearshape", title: "Manage Groups", iconColor: DesignColors.info, id: "groups") {
                viewModel.openGroupConfiguration()
            }
            footerButton(icon: "rectangle.grid.2x2", title: "Open Dashboard", iconColor: DesignColors.gitBranch, id: "dashboard") {
                NotificationCenter.default.post(name: .showMainWindow, object: nil)
            }
            footerButton(icon: "antenna.radiowaves.left.and.right", title: "Kill Ports", iconColor: DesignColors.warning, id: "ports") {
                viewModel.openPortKiller()
            }
            footerButton(icon: "gearshape.fill", title: "Settings", iconColor: DesignColors.iron, id: "settings") {
                viewModel.openSettings()
            }

            Rectangle()
                .fill(DesignColors.linen)
                .frame(height: 1)
                .padding(.horizontal, 12)

            footerButton(icon: "power", title: "Quit", iconColor: DesignColors.error, id: "quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }

    private func footerButton(icon: String, title: String, iconColor: Color, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(iconColor.opacity(hoveredFooterAction == id ? 0.25 : 0.12))
                        .frame(width: 22, height: 22)

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignColors.rausch)
                Spacer()

                if hoveredFooterAction == id {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(DesignColors.iron.opacity(0.5))
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(hoveredFooterAction == id ? DesignColors.coral.opacity(0.06) : Color.clear)
            )
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredFooterAction = isHovered ? id : nil
            }
        }
    }
}

// MARK: - Pulsing Dot Animation

struct PulsingDot: View {
    let color: Color
    let size: CGFloat
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Draggable Project Row

struct DraggableProjectRow: View {
    let project: Project
    let status: ProcessStatus
    let gitBranch: String?
    let isHovered: Bool
    @Binding var draggedProjectId: UUID?
    let allProjects: [Project]
    let viewModel: MenuBarViewModel
    let onRun: () -> Void
    let onStop: () -> Void
    let onShowLog: () -> Void
    let onOpenInIDE: () -> Void
    let onOpenEnvironmentVariables: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var isDropTarget = false

    var body: some View {
        ProjectRow(
            project: project,
            status: status,
            isHovered: isHovered,
            lastLogLines: viewModel.getLastOutputLines(for: project),
            currentMemory: viewModel.getCurrentMemory(for: project),
            gitBranch: gitBranch,
            onRun: onRun,
            onStop: onStop,
            onShowLog: onShowLog,
            onOpenInIDE: onOpenInIDE,
            onOpenEnvironmentVariables: onOpenEnvironmentVariables,
            onDelete: onDelete,
            onHover: onHover
        )
        .opacity(draggedProjectId == project.id ? 0.4 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .fill(DesignColors.coral.opacity(0.1))
                .allowsHitTesting(false)
                .opacity(isDropTarget ? 1 : 0)
        )
        .onDrag {
            self.draggedProjectId = project.id
            return NSItemProvider(object: project.id.uuidString as NSString)
        }
        .onDrop(of: [UTType.text], delegate: ProjectDropDelegate(
            targetProject: project,
            allProjects: allProjects,
            draggedProjectId: $draggedProjectId,
            isDropTarget: $isDropTarget,
            viewModel: viewModel
        ))
    }
}

// MARK: - Project Drop Delegate

struct ProjectDropDelegate: DropDelegate {
    let targetProject: Project
    let allProjects: [Project]
    @Binding var draggedProjectId: UUID?
    @Binding var isDropTarget: Bool
    let viewModel: MenuBarViewModel

    func dropEntered(info: DropInfo) {
        guard let draggedId = draggedProjectId,
              draggedId != targetProject.id else { return }
        isDropTarget = true

        guard let fromIndex = allProjects.firstIndex(where: { $0.id == draggedId }),
              let toIndex = allProjects.firstIndex(where: { $0.id == targetProject.id }) else { return }

        if fromIndex != toIndex {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.moveProject(from: IndexSet(integer: fromIndex), to: toIndex > fromIndex ? toIndex + 1 : toIndex)
            }
        }
    }

    func dropExited(info: DropInfo) { isDropTarget = false }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool { draggedProjectId = nil; isDropTarget = false; return true }
    func validateDrop(info: DropInfo) -> Bool { true }
}

// MARK: - Group Section View

struct GroupSection: View {
    let group: ProjectGroup
    let projects: [Project]
    let isExpanded: Bool
    let isGroupRunning: Bool
    let isGroupFullyRunning: Bool
    let hoveredProjectId: UUID?
    let hoveredGroupId: UUID?
    @Binding var draggedProjectId: UUID?
    let viewModel: MenuBarViewModel
    let onToggleExpand: () -> Void
    let onRunGroup: () -> Void
    let onStopGroup: () -> Void
    let onHoverGroup: (Bool) -> Void
    let onHoverProject: (UUID, Bool) -> Void
    let onDeleteProject: (Project) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            groupHeader

            if isExpanded {
                ForEach(projects) { project in
                    DraggableProjectRow(
                        project: project,
                        status: viewModel.getStatus(for: project),
                        gitBranch: viewModel.projectGitBranches[project.id],
                        isHovered: hoveredProjectId == project.id,
                        draggedProjectId: $draggedProjectId,
                        allProjects: viewModel.projects,
                        viewModel: viewModel,
                        onRun: { viewModel.runProject(project) },
                        onStop: { viewModel.stopProject(project) },
                        onShowLog: { viewModel.showLog(for: project) },
                        onOpenInIDE: { viewModel.openInIDE(project) },
                        onOpenEnvironmentVariables: { viewModel.openEnvironmentVariables(project) },
                        onDelete: { onDeleteProject(project) },
                        onHover: { isHovered in onHoverProject(project.id, isHovered) }
                    )
                    .padding(.leading, 8)

                    if project.id != projects.last?.id {
                        Rectangle()
                            .fill(DesignColors.linen)
                            .frame(height: 1)
                            .padding(.leading, 46)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var groupHeader: some View {
        HStack(spacing: 8) {
            Button(action: onToggleExpand) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(DesignColors.iron)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
            }
            .buttonStyle(BorderlessButtonStyle())

            Circle()
                .fill(DesignColors.colorForGroupColor(group.color))
                .frame(width: 9, height: 9)

            Text(group.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(DesignColors.rausch)

            let runningCount = projects.filter { viewModel.isRunning($0) }.count
            if runningCount > 0 {
                HStack(spacing: 3) {
                    PulsingDot(color: DesignColors.success, size: 4)
                    Text("\(runningCount)/\(projects.count)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(DesignColors.success)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(DesignColors.success.opacity(0.12)))
            } else {
                Text("\(projects.count)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.iron.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(DesignColors.linen.opacity(0.2)))
            }

            Spacer()

            if hoveredGroupId == group.id {
                HStack(spacing: 4) {
                    if isGroupRunning {
                        GroupActionButton(icon: "stop.fill", color: DesignColors.warning, size: 9, action: onStopGroup, isDisabled: false, tooltip: "Stop all")
                    } else {
                        GroupActionButton(icon: "play.fill", color: DesignColors.success, size: 9, action: onRunGroup, isDisabled: false, tooltip: "Run all")
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(hoveredGroupId == group.id ? DesignColors.info.opacity(0.08) : Color.clear)
                .padding(.horizontal, 4)
        )
        .onHover { isHovered in onHoverGroup(isHovered) }
    }
}



// MARK: - Group Action Button

struct GroupActionButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    let isDisabled: Bool
    let tooltip: String

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(isHovered ? 0.2 : 0))
                    .frame(width: 20, height: 20)
                Image(systemName: icon)
                    .font(.system(size: size))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(isDisabled)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { isHovered = hovering }
        }
    }
}

// MARK: - Project Row View

struct ProjectRow: View {
    let project: Project
    let status: ProcessStatus
    let isHovered: Bool
    let lastLogLines: [CommandOutput]
    let currentMemory: MemoryData?
    let gitBranch: String?
    let onRun: () -> Void
    let onStop: () -> Void
    let onShowLog: () -> Void
    let onOpenInIDE: () -> Void
    let onOpenEnvironmentVariables: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var isHoveringQuickActions = false

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(DesignColors.iron.opacity(isHovered ? 0.5 : 0))
                    .frame(width: 14)
                    .padding(.trailing, 2)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)

                statusIndicator

                projectInfo

                Spacer()
            }

            quickActions
                .opacity(isHovered ? 1 : 0)
                .onHover { hovering in
                    isHoveringQuickActions = hovering
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? DesignColors.info.opacity(0.06) : Color.clear)
                .padding(.horizontal, 4)
        )
        .onHover { hovering in
            onHover(hovering)
        }
        .contentShape(Rectangle())
    }

    private var logPreviewPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(status.isRunning ? DesignColors.success : DesignColors.iron)
                    .frame(width: 6, height: 6)

                Text(project.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignColors.rausch)

                Spacer()

                if !lastLogLines.isEmpty {
                    Text("Last \(lastLogLines.count) lines")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(DesignColors.iron.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DesignColors.snow.opacity(0.5))

            Divider()

            if lastLogLines.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No log")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(DesignColors.iron.opacity(0.5))
                        Spacer()
                    }
                    Spacer()
                }
                .frame(height: 180)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(lastLogLines.enumerated()), id: \.offset) { _, output in
                            Text(output.text.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(output.type == .stderr ? DesignColors.error : DesignColors.rausch)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 340, height: 250)
        .background(DesignColors.white)
    }

    private var statusIndicator: some View {
        ZStack {
            if status.isRunning {
                Circle()
                    .stroke(statusColor.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 16, height: 16)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(status.isRunning ? 360 : 0))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: status.isRunning)
            }

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .frame(width: 20)
        .padding(.trailing, 8)
    }

    private var memoryIndicator: some View {
        Group {
            if let memory = currentMemory, status.isRunning {
                HStack(spacing: 3) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(memoryColor(for: memory.memoryMB))

                    Text(memory.memoryMBFormatted)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(memoryColor(for: memory.memoryMB))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(memoryColor(for: memory.memoryMB).opacity(0.12))
                )
                .padding(.trailing, 6)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func memoryColor(for mb: Double) -> Color {
        switch mb {
        case 0..<500: return DesignColors.success
        case 500..<1024: return DesignColors.warning
        case 1024..<2048: return DesignColors.warning
        default: return DesignColors.error
        }
    }

    private var projectInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(DesignColors.rausch)

            gitBranchIndicator

            memoryIndicator

            if !status.description.isEmpty && status != .idle {
                Text(status.description)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(statusColor.opacity(0.1))
                    )
            }
        }
    }

    private var gitBranchIndicator: some View {
        Group {
            if let branch = gitBranch {
                HStack(spacing: 3) {
                    Image(systemName: "git.branch")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundColor(DesignColors.gitBranch)

                    Text(branch)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignColors.gitBranch.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(
                    Capsule()
                        .fill(DesignColors.gitBranch.opacity(0.15))
                )
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 3) {
            if status.isRunning {
                QuickActionButton(icon: "stop.fill", color: DesignColors.warning, action: onStop, isDisabled: false, tooltip: "Stop")
            } else {
                QuickActionButton(icon: "play.fill", color: DesignColors.success, action: onRun, isDisabled: false, tooltip: "Run")
            }
            QuickActionButton(icon: "folder", color: DesignColors.info, action: onOpenInIDE, isDisabled: AppSettingsManager.shared.settings.ideCommand.isEmpty, tooltip: "Open in IDE")
            QuickActionButton(icon: "square.stack.3d.up", color: DesignColors.warning, action: onOpenEnvironmentVariables, isDisabled: false, tooltip: "Environment Variables")
            QuickActionButton(icon: "terminal", color: DesignColors.coral, action: onShowLog, isDisabled: false, tooltip: "View log", showPopoverOnHover: true, popoverContent: { logPreviewPopover })
            QuickActionButton(icon: "trash", color: DesignColors.error, action: onDelete, isDisabled: false, tooltip: "Delete")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(DesignColors.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.trailing, 8)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
    }

    private var statusColor: Color {
        switch status {
        case .idle:    return DesignColors.iron
        case .running: return DesignColors.success
        case .stopped: return DesignColors.coral
        case .failed:  return DesignColors.error
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    let isDisabled: Bool
    let tooltip: String
    let showPopoverOnHover: Bool
    let popoverContent: AnyView?

    @State private var isHovered = false
    @State private var showPopover = false
    @State private var hoverTimer: Timer?

    init(
        icon: String,
        color: Color,
        action: @escaping () -> Void,
        isDisabled: Bool,
        tooltip: String,
        showPopoverOnHover: Bool = false,
        @ViewBuilder popoverContent: () -> some View = { EmptyView() }
    ) {
        self.icon = icon
        self.color = color
        self.action = action
        self.isDisabled = isDisabled
        self.tooltip = tooltip
        self.showPopoverOnHover = showPopoverOnHover
        self.popoverContent = showPopoverOnHover ? AnyView(popoverContent()) : nil
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(isHovered && !isDisabled ? 0.15 : 0))
                    .frame(width: 24, height: 24)

                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isDisabled ? color.opacity(0.3) : color)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
        .disabled(isDisabled)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) { isHovered = hovering }
            if showPopoverOnHover {
                if hovering {
                    hoverTimer?.invalidate()
                    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                        DispatchQueue.main.async {
                            if self.isHovered {
                                showPopover = true
                            }
                        }
                    }
                } else {
                    hoverTimer?.invalidate()
                    hoverTimer = nil
                    showPopover = false
                }
            }
        }
        .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) {
            if let popoverContent = popoverContent {
                popoverContent
            }
        }
    }
}
