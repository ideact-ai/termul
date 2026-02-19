//
//  MainWindowView.swift
//  Termul
//
//  Main dashboard window with sophisticated modern design
//

import SwiftUI

struct MainWindowView: View {
    // MARK: - Properties

    @StateObject private var viewModel: MainWindowViewModel
    @State private var selectedTab: DashboardTab = .projects
    @State private var hoveredTab: DashboardTab?
    @State private var isAnimating: Bool = false

    // MARK: - Initialization

    /// Creates a new main window view
    /// - Parameter viewModel: The view model managing dashboard state
    init(viewModel: MainWindowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignColors.gradientBackground
                    .ignoresSafeArea()

                // Main content
                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)

                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    Rectangle()
                        .fill(DesignColors.divider)
                        .frame(height: 1)

                    // Content area
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .projects:
                                projectsContent
                            case .groups:
                                groupsContent
                            case .overview:
                                overviewContent
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .frame(minWidth: 1000, minHeight: 700)
            .background(DesignColors.background)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.openSettings()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(DesignColors.surface.opacity(0.8))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            // App icon
            if let nsImage = loadTermulIcon() {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .shadow(color: DesignColors.primary.shadowColor(0.25), radius: 12, x: 0, y: 6)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignColors.gradientPrimary)
                        .frame(width: 48, height: 48)
                        .shadow(color: DesignColors.primary.shadowColor(0.3), radius: 12, x: 0, y: 6)

                    Image(systemName: "terminal.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Termul")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.textPrimary)

                Text("Development Environment Manager")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignColors.textSecondary)
            }

            Spacer()

            // Quick stats
            HStack(spacing: 16) {
                quickStat(
                    icon: "play.fill",
                    value: "\(viewModel.runningCount)",
                    label: "Running",
                    color: DesignColors.running
                )

                Rectangle()
                    .fill(DesignColors.divider)
                    .frame(width: 1, height: 30)

                quickStat(
                    icon: "stop.fill",
                    value: "\(viewModel.stoppedCount)",
                    label: "Stopped",
                    color: DesignColors.stopped
                )

                Rectangle()
                    .fill(DesignColors.divider)
                    .frame(width: 1, height: 30)

                quickStat(
                    icon: "chart.bar.fill",
                    value: formatMemory(viewModel.statistics.totalMemoryUsage),
                    label: "Memory",
                    color: DesignColors.memory
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignColors.border, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.shadowColor(0.05), radius: 8, x: 0, y: 4)
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : -10)
        }
    }

    private func quickStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.textPrimary)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignColors.textTertiary)
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignColors.border, lineWidth: 0.5)
                )
        )
    }

    private func tabButton(for tab: DashboardTab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(tab.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(selectedTab == tab ? .white : DesignColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab ? AnyShapeStyle(tabBackground(for: tab)) : AnyShapeStyle(Color.clear))
                    .shadow(
                        color: tabColor(for: tab).shadowColor(selectedTab == tab ? 0.3 : 0),
                        radius: selectedTab == tab ? 8 : 0,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func tabColor(for tab: DashboardTab) -> Color {
        switch tab {
        case .projects: return DesignColors.primary
        case .groups: return DesignColors.secondary
        case .overview: return DesignColors.tertiary
        }
    }

    private func tabBackground(for tab: DashboardTab) -> some ShapeStyle {
        switch tab {
        case .projects: return DesignColors.gradientPrimary
        case .groups: return DesignColors.gradientSecondary
        case .overview: return LinearGradient(
            colors: [DesignColors.tertiary, DesignColors.tertiaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        }
    }

    // MARK: - Projects Content

    private var projectsContent: some View {
        VStack(spacing: 20) {
            // Search and filters
            searchAndFilters

            // Quick actions
            quickActions

            // Project list
            if viewModel.filteredProjects.isEmpty {
                emptyState
            } else {
                projectGrid
            }
        }
    }

    private var searchAndFilters: some View {
        HStack(spacing: 16) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignColors.textTertiary)

                TextField("Search projects...", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .foregroundColor(DesignColors.textPrimary)

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignColors.textSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DesignColors.border, lineWidth: 0.5)
                    )
            )

            // Filter dropdown
            Menu {
                ForEach(ProjectFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        viewModel.setFilter(filter)
                    }) {
                        HStack {
                            Image(systemName: filter.icon)
                                .font(.system(size: 12))
                            Text(filter.displayName)
                                .font(.system(size: 13))
                            if viewModel.selectedFilter == filter {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignColors.primary)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.selectedFilter.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(filterColor(for: viewModel.selectedFilter))

                    Text(viewModel.selectedFilter.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignColors.textPrimary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(DesignColors.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DesignColors.border, lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()
        }
    }

    private func filterColor(for filter: ProjectFilter) -> Color {
        switch filter {
        case .all: return DesignColors.primary
        case .running: return DesignColors.running
        case .stopped: return DesignColors.stopped
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            actionButton(
                icon: "play.fill",
                title: "Run All",
                color: DesignColors.success
            ) {
                viewModel.runAllProjects()
            }

            actionButton(
                icon: "stop.fill",
                title: "Stop All",
                color: DesignColors.error
            ) {
                viewModel.stopAllProjects()
            }

            actionButton(
                icon: "plus",
                title: "Add Project",
                color: DesignColors.primary
            ) {
                viewModel.openAddProject()
            }

            Spacer()

            actionButton(
                icon: "folder",
                title: "Manage Groups",
                color: DesignColors.secondary
            ) {
                viewModel.openGroupConfiguration()
            }
        }
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var projectGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(viewModel.filteredProjects, id: \.id) { project in
                ProjectCardView(
                    project: project,
                    status: viewModel.getProjectStatus(project),
                    memoryUsage: viewModel.getCurrentMemoryUsage(for: project).map { UInt64($0) } ?? 0,
                    gitBranch: viewModel.getGitBranch(for: project),
                    groupName: viewModel.groupName(for: project),
                    onRun: { viewModel.runProject(project) },
                    onStop: { viewModel.stopProject(project) },
                    onOpenInIDE: { viewModel.openInIDE(project) },
                    onDelete: { viewModel.deleteProject(project) }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignColors.textMuted)

            Text("No projects found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DesignColors.textPrimary)

            Text("Add your first project to get started")
                .font(.system(size: 13))
                .foregroundColor(DesignColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Groups Content

    private var groupsContent: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Project Groups")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.textPrimary)

                Spacer()

                Button(action: {
                    viewModel.openAddGroup()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Add Group")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(DesignColors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignColors.primary.opacity(0.12))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Groups grid
            if viewModel.groups.isEmpty {
                emptyGroupsState
            } else {
                groupsGrid
            }
        }
    }

    private var groupsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(viewModel.groups, id: \.id) { group in
                GroupCardView(
                    group: group,
                    projectCount: projectCount(for: group.id),
                    runningCount: runningCount(for: group.id),
                    onRun: { viewModel.runGroup(group) },
                    onStop: { viewModel.stopGroup(group) },
                    onDelete: { viewModel.deleteGroup(groupId: group.id) }
                )
            }
        }
    }

    private func projectCount(for groupId: UUID) -> Int {
        return (viewModel.filteredProjects.filter { $0.groupId == groupId }).count
    }

    private func runningCount(for groupId: UUID) -> Int {
        let groupProjects = viewModel.filteredProjects.filter { $0.groupId == groupId }
        return groupProjects.filter { project in
            viewModel.getProjectStatus(project).isRunning
        }.count
    }

    private var emptyGroupsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(DesignColors.textMuted)

            Text("No groups yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DesignColors.textPrimary)

            Text("Create groups to organize your projects")
                .font(.system(size: 13))
                .foregroundColor(DesignColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        VStack(spacing: 24) {
            // Statistics cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Projects",
                    value: "\(viewModel.statistics.totalProjects)",
                    icon: "folder.fill",
                    color: DesignColors.primary
                )

                StatCard(
                    title: "Running",
                    value: "\(viewModel.statistics.runningProjects)",
                    icon: "play.fill",
                    color: DesignColors.running
                )

                StatCard(
                    title: "Memory Usage",
                    value: formatMemory(viewModel.statistics.totalMemoryUsage),
                    icon: "chart.bar.fill",
                    color: DesignColors.memory
                )

                StatCard(
                    title: "Groups",
                    value: "\(viewModel.statistics.totalGroups)",
                    icon: "square.grid.2x2",
                    color: DesignColors.secondary
                )
            }

            // Memory chart placeholder
            VStack(spacing: 16) {
                HStack {
                    Text("Memory Usage Over Time")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignColors.textPrimary)

                    Spacer()
                }

                Rectangle()
                    .fill(DesignColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(DesignColors.border, lineWidth: 0.5)
                    )
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(DesignColors.textMuted)

                            Text("Memory tracking chart")
                                .font(.system(size: 13))
                                .foregroundColor(DesignColors.textTertiary)
                        }
                    )
            }
        }
    }

    // MARK: - Helper Functions

    private func formatMemory(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        } else {
            return String(format: "%.0f MB", mb)
        }
    }
}

// MARK: - Project Card View

struct ProjectCardView: View {
    let project: Project
    let status: ProcessStatus
    let memoryUsage: UInt64
    let gitBranch: String?
    let groupName: String?
    let onRun: () -> Void
    let onStop: () -> Void
    let onOpenInIDE: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignColors.textPrimary)
                        .lineLimit(1)

                    if let groupName = groupName {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(DesignColors.secondary)
                                .frame(width: 6, height: 6)

                            Text(groupName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Status indicator
                HStack(spacing: 6) {
                    PulsingDot(color: DesignColors.colorForProcessStatus(status), size: 8)

                    Text(status.description)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DesignColors.colorForProcessStatus(status))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(DesignColors.backgroundColorForProcessStatus(status))
                )
            }

            // Git branch and command
            VStack(alignment: .leading, spacing: 6) {
                if let branch = gitBranch {
                    HStack(spacing: 6) {
                        Image(systemName: "git.branch")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(DesignColors.gitBranch)

                        Text(branch)
                            .font(.system(size: 11, weight: .medium).monospaced())
                            .foregroundColor(DesignColors.gitBranch)
                            .lineLimit(1)
                    }
                }

                Text(project.command)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(DesignColors.textSecondary)
                    .lineLimit(2)
            }

            Divider()
                .background(DesignColors.divider)

            // Memory and actions
            HStack(spacing: 12) {
                // Memory usage
                if status.isRunning {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(DesignColors.memory)

                        Text(formatMemory(memoryUsage))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignColors.textSecondary)
                    }
                } else {
                    Text("Not running")
                        .font(.system(size: 11))
                        .foregroundColor(DesignColors.textMuted)
                }

                Spacer()

                // Actions
                HStack(spacing: 6) {
                    if status.isRunning {
                        actionIconButton(icon: "stop.fill", color: DesignColors.error) {
                            onStop()
                        }
                    } else {
                        actionIconButton(icon: "play.fill", color: DesignColors.running) {
                            onRun()
                        }
                    }

                    actionIconButton(icon: "terminal", color: DesignColors.terminal) {
                        onOpenInIDE()
                    }

                    actionIconButton(icon: "trash", color: DesignColors.textTertiary) {
                        onDelete()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignColors.gradientCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isHovered ? DesignColors.primary.opacity(0.3) : DesignColors.border,
                            lineWidth: isHovered ? 1.5 : 0.5
                        )
                )
                .shadow(
                    color: Color.black.shadowColor(isHovered ? 0.08 : 0.04),
                    radius: isHovered ? 12 : 6,
                    x: 0,
                    y: 4
                )
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }

    private func actionIconButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.12))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        } else {
            return String(format: "%.0f MB", mb)
        }
    }
}

// MARK: - Group Card View

struct GroupCardView: View {
    let group: ProjectGroup
    let projectCount: Int
    let runningCount: Int
    let onRun: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DesignColors.textPrimary)

                    Text("\(projectCount) project\(projectCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(DesignColors.textTertiary)
                }

                Spacer()

                // Color indicator
                Circle()
                    .fill(DesignColors.colorForGroupColor(group.color))
                    .frame(width: 12, height: 12)

            }

            // Running indicator
            if runningCount > 0 {
                HStack(spacing: 6) {
                    PulsingDot(color: DesignColors.running, size: 8)

                    Text("\(runningCount) running")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignColors.running)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.running.opacity(0.1))
                )
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(DesignColors.stopped)
                        .frame(width: 8, height: 8)

                    Text("All stopped")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignColors.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignColors.stopped.opacity(0.1))
                )
            }

            Divider()
                .background(DesignColors.divider)

            // Actions
            HStack(spacing: 8) {
                if runningCount > 0 {
                    Button(action: onStop) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Stop All")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(DesignColors.error)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignColors.error.opacity(0.12))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                } else {
                    Button(action: onRun) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Run All")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(DesignColors.running)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignColors.running.opacity(0.12))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DesignColors.surface.opacity(0.8))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignColors.gradientCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isHovered ? DesignColors.colorForGroupColor(group.color).opacity(0.3) : DesignColors.border,
                            lineWidth: isHovered ? 1.5 : 0.5
                        )
                )
                .shadow(
                    color: Color.black.shadowColor(isHovered ? 0.08 : 0.04),
                    radius: isHovered ? 12 : 6,
                    x: 0,
                    y: 4
                )
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(color.opacity(0.12))
                    )

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignColors.textPrimary)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(DesignColors.textTertiary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignColors.gradientCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignColors.border, lineWidth: 0.5)
                )
                .shadow(color: Color.black.shadowColor(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Preview
// MARK: - Dashboard Tab

enum DashboardTab: String, CaseIterable {
    case projects = "Projects"
    case groups = "Groups"
    case overview = "Overview"

    var displayName: String {
        return rawValue
    }

    var icon: String {
        switch self {
        case .projects: return "square.grid.2x2"
        case .groups: return "folder.fill"
        case .overview: return "chart.bar.fill"
        }
    }
}

// MARK: - Icon Loading Helper

private func loadTermulIcon() -> NSImage? {
    // Method 1: Try loading directly from bundle (assets catalog)
    if let image = Bundle.main.image(forResource: "MenuBarIcon") {
        return image
    }

    // Method 2: Try loading from specific file paths (SPM and app bundle)
    var iconImage: NSImage?

    // Try SPM Bundle.module
    #if SWIFT_PACKAGE
    if #available(macOS 14.0, *) {
        let spmIconPath = Bundle.module.bundlePath + "/Assets.xcassets/MenuBarIcon.imageset/48.png"
        if FileManager.default.fileExists(atPath: spmIconPath) {
            iconImage = NSImage(contentsOfFile: spmIconPath)
        }
    }
    #endif

    // Try main bundle
    if iconImage == nil {
        let mainBundleIconPath = Bundle.main.bundlePath + "/Contents/Resources/Assets.xcassets/MenuBarIcon.imageset/48.png"
        if FileManager.default.fileExists(atPath: mainBundleIconPath) {
            iconImage = NSImage(contentsOfFile: mainBundleIconPath)
        }
    }

    if let img = iconImage {
        img.size = NSSize(width: 48, height: 48)
        return img
    }

    return nil
}

// MARK: - Preview

struct MainWindowView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = MainWindowViewModel()
        MainWindowView(viewModel: viewModel)
            .frame(width: 1200, height: 800)
    }
}
