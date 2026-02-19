# AGENT.md — AI Agent Rules for Termul

## Project Overview

**Termul** is a **native development environment management tool** that lets users configure projects (path + command), run/stop them, view real-time output, kill port processes, and monitor memory usage across multiple platforms.

**This is NOT a web app.** Termul is a monorepo with:
- **macOS**: Swift/SwiftUI menu bar application
- **Windows**: WPF/C# tray application (planned)
- **Linux**: GTK/Vala tray application (planned)

---

## Technology Stack

### macOS
| Layer | Technology |
|---|---|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| System Framework | AppKit (NSStatusItem, NSPopover, NSWindow) |
| Reactive | Combine Framework |
| Persistence | UserDefaults |
| Build System | Swift Package Manager (SPM) |
| Target OS | macOS 14.0+ (Sonoma) |
| App Type | Menu bar accessory (`LSUIElement = true`) |

### Windows (Planned)
| Layer | Technology |
|---|---|
| Language | C# / .NET |
| UI Framework | WPF |
| Build System | MSBuild |

### Linux (Planned)
| Layer | Technology |
|---|---|
| Language | Vala / C |
| UI Framework | GTK |
| Build System | Meson |

---

## Build & Run Commands

### macOS

```bash
# Navigate to macOS directory
cd macOS

# Build (debug)
swift build

# Build (release)
swift build -c release

# Run
swift run Termul

# Clean
swift package clean

# Build .app bundle
chmod +x build.sh && ./build.sh

# Build DMG installer
chmod +x build_installer.sh && ./build_installer.sh

# Use Makefile
make help          # Show all commands
make app           # Build .app bundle
make installer     # Build DMG installer
make run           # Run via swift build
make run-app       # Run .app bundle
make clean         # Clean build artifacts
make all           # Build app + installer
```

**Always run `swift build` after making changes to verify compilation.**

---

## Project Structure

```
termul/
├── AGENT.md                               # This file
├── README.md                              # Main repository README
├── .gitignore                             # Git ignore rules
│
├── macOS/                                 # macOS application
│   ├── Package.swift                      # SPM manifest — DO NOT add -parse-as-library
│   ├── build.sh                           # Creates .app bundle
│   ├── build_installer.sh                 # Creates .dmg installer
│   ├── uninstall.sh                       # Uninstaller script
│   ├── Makefile                           # Build automation
│   ├── notarize.sh                        # Code notarization script
│   │
│   ├── Termul/                            # All source code
│   │   ├── main.swift                      # App entry point (top-level code)
│   │   ├── AppDelegate.swift               # Menu bar, popover, window lifecycle
│   │   ├── Info.plist                      # App config (LSUIElement, bundle ID)
│   │   ├── Termul.entitlements             # Sandbox entitlements
│   │   │
│   │   ├── Models/                         # Data models (structs/enums)
│   │   │   ├── Project.swift               # Project data model (Codable)
│   │   │   ├── ProjectGroup.swift           # Project grouping model
│   │   │   ├── ProcessStatus.swift         # Process state enum
│   │   │   ├── CommandOutput.swift         # Output line model
│   │   │   ├── MemoryData.swift            # Memory usage data model
│   │   │   └── AppSettings.swift           # App-wide settings model
│   │   │
│   │   ├── Managers/                       # Business logic / services
│   │   │   ├── ProjectManager.swift        # CRUD + UserDefaults persistence
│   │   │   ├── CommandRunner.swift         # Shell command execution (Process)
│   │   │   ├── PortKiller.swift            # Port scanning & process killing
│   │   │   └── MemoryMonitor.swift         # Real-time memory monitoring
│   │   │
│   │   ├── ViewModels/                     # Presentation logic (ObservableObject)
│   │   │   ├── MenuBarViewModel.swift      # Menu bar state + quick actions
│   │   │   ├── ConfigurationViewModel.swift  # Add/edit project form logic
│   │   │   ├── GroupConfigurationViewModel.swift # Project groups management
│   │   │   └── OutputViewerViewModel.swift   # Output display + process control
│   │   │
│   │   ├── Views/                          # SwiftUI views
│   │   │   ├── MenuBarView.swift           # Dropdown menu UI
│   │   │   ├── ConfigurationView.swift     # Project configuration form
│   │   │   ├── GroupConfigurationView.swift # Project groups configuration
│   │   │   ├── OutputViewerView.swift      # Terminal-like output viewer
│   │   │   ├── MemoryChartView.swift      # Memory sparkline chart
│   │   │   ├── SettingsView.swift         # App settings UI
│   │   │   ├── PortKillerView.swift       # Port scanning & killing UI
│   │   │   └── DeleteProjectConfirmationView.swift # Delete confirmation dialog
│   │   │
│   │   └── Resources/                      # App resources
│   │       └── Assets.xcassets/            # Images, colors, icons
│   │
│   ├── .build/                             # Swift Package Manager build artifacts
│   ├── .swiftpm/                           # Swift Package Manager cache
│   └── build/                              # Build output directory
│
├── Windows/                                # Windows application (planned)
│   └── README.md                           # Windows implementation notes
│
└── Linux/                                  # Linux application (planned)
    └── README.md                           # Linux implementation notes
```

---

## Architecture Rules

### 1. Clean Architecture (MVVM)

```
Views → ViewModels → Managers → Models
```

- **Views** (`Views/`): SwiftUI views only. No business logic. Bind to ViewModels.
- **ViewModels** (`ViewModels/`): `ObservableObject` classes with `@Published` properties. Contain presentation logic.
- **Managers** (`Managers/`): Business logic, system interactions, persistence. No UI dependencies.
- **Models** (`Models/`): Plain data types (`struct`, `enum`). Must be `Codable` if persisted.

### 2. Communication Pattern

- **Views ↔ ViewModels**: Direct binding via `@ObservedObject` / `@StateObject`
- **ViewModels → AppDelegate**: Via `NotificationCenter` (post notifications)
- **AppDelegate → Window creation**: Handles all `NSWindow` lifecycle
- **Managers**: Called directly by ViewModels, never by Views

### 3. Notification Names

All notification names are defined in `MenuBarViewModel.swift` as extensions on `Notification.Name`:

```swift
extension Notification.Name {
    static let showOutputViewer = Notification.Name("showOutputViewer")
    static let closeOutputViewer = Notification.Name("closeOutputViewer")
    static let commandOutput = Notification.Name("commandOutput")
    static let showConfiguration = Notification.Name("showConfiguration")
    static let showPortKiller = Notification.Name("showPortKiller")
    static let showGroupConfiguration = Notification.Name("showGroupConfiguration")
    static let showSettings = Notification.Name("showSettings")
    static let showDeleteConfirmation = Notification.Name("showDeleteConfirmation")
    static let memoryDataUpdate = Notification.Name("memoryDataUpdate")
}
```

**When adding new windows/features**, follow this pattern:
1. Add a notification name in the extension above
2. Add a method in the relevant ViewModel to post the notification
3. Add an observer + handler in `AppDelegate.swift`
4. Create the window in the handler

---

## Critical Rules

### DO:
- ✅ Always use the user's shell (`$SHELL`) with `-l` flag for command execution
- ✅ Source Nix profiles and run `direnv export` before executing user commands (see `CommandRunner.run()`)
- ✅ Store one `CommandRunner` per project in `MenuBarViewModel.commandRunners`
- ✅ Accumulate output per project in `MenuBarViewModel.projectOutputs`
- ✅ Close the popover (`closePopover()`) before showing any window
- ✅ Use global event monitors (`addGlobalMonitorForEvents`) for outside-click detection
- ✅ Set `isReleasedWhenClosed = false` on all windows
- ✅ Set `applicationShouldTerminateAfterLastWindowClosed` to `false` (menu bar app)
- ✅ Run `swift build` after every code change to verify compilation
- ✅ Use `DispatchQueue.main.async` for all UI updates from background threads
- ✅ Start memory monitoring when process starts via `MemoryMonitor.startMonitoring()`
- ✅ Store memory history (max 300 points) per project in `MenuBarViewModel.projectMemoryData`
- ✅ Stop memory monitoring when process stops via `MemoryMonitor.stopMonitoring()`
- ✅ Use `AppSettings.shared` for accessing application settings
- ✅ Validate project deletion by requiring users to type the project name
- ✅ Fetch git branch info when project runs via `CommandRunner.fetchGitBranch()` and persist in `Project.currentGitBranch`

### DON'T:
- ❌ Never add `-parse-as-library` to `Package.swift` — it breaks `main.swift`
- ❌ Never use local event monitors (`addLocalMonitorForEvents`) on the popover — it intercepts button clicks
- ❌ Never use `-i` (interactive) shell flag — no TTY available from GUI apps
- ❌ Never hardcode `/bin/bash` — use `ProcessInfo.processInfo.environment["SHELL"]`
- ❌ Never set `process.currentDirectoryURL` for user commands — use `cd` in the command to trigger direnv
- ❌ Never capture `process.processIdentifier` before calling `process.run()` — PID is 0 until launched
- ❌ Never create a new `CommandRunner` in `AppDelegate.handleShowOutputViewer` — reuse the one from `MenuBarViewModel`
- ❌ Never use `@main` attribute — the app uses a manual `main.swift` entry point
- ❌ Don't add `.xcodeproj` or Xcode-specific build steps — this project uses SPM only
- ❌ Never store memory history without limiting to 300 points to avoid memory bloat
- ❌ Never poll memory faster than 1-second intervals to avoid performance impact

---

## Adding a New Feature (Checklist)

1. **Model** (if needed): Create a new file in `Models/`
2. **Manager** (if needed): Create a new file in `Managers/`
3. **ViewModel**: Add methods to existing ViewModel or create a new one in `ViewModels/`
4. **View**: Create the SwiftUI view in `Views/`
5. **Notification**: Add notification name in `MenuBarViewModel.swift` extension
6. **AppDelegate**: Add observer in `setupNotifications()`, add handler method, create window
7. **Menu bar entry**: Add button in `MenuBarView.swift` footer section
8. **Build**: Run `swift build` to verify
9. **Test**: Run `swift run Termul` to verify functionality

---

## Shell Command Execution

The app must support users with **Nix + direnv** environments. Commands are wrapped as:

```bash
$SHELL -l -c "
  [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh;
  [ -e \"$HOME/.nix-profile/etc/profile.d/nix.sh\" ] && . \"$HOME/.nix-profile/etc/profile.d/nix.sh\";
  cd '<project_path>' &&
  if command -v direnv >/dev/null 2>&1; then eval \"$(direnv export zsh 2>/dev/null)\"; fi;
  <user_command>
"
```

This ensures:
1. Nix profiles are sourced (tools like `direnv` become available)
2. `cd` into the project directory
3. `direnv export` loads the project's `.envrc` / Nix dev environment
4. The user's command runs with the full environment

---

## Data Persistence

- **Projects**: Stored in `UserDefaults` under key `"com.termul.projects"`
- **Project Groups**: Stored in `UserDefaults` under key `"com.termul.groups"`
- **App Settings**: Stored in `UserDefaults` under key `"com.termul_app_settings"`
- Data is encoded/decoded using `JSONEncoder`/`JSONDecoder`
- Backups are stored under key `"com.termul.projects_backup"`
- All persistence logic is in `ProjectManager.swift` and `AppSettings.swift`

---

## Memory Tracking

### Overview
Termul provides real-time memory monitoring for all running processes. This feature:
- Polls memory usage every 2 seconds (configurable)
- Stores up to 300 data points per project (10 minutes history)
- Displays current usage with color-coded indicators
- Shows sparkline charts with gradients
- Provides statistics (min, max, average)

### Memory Thresholds
| Usage Level | Memory Range | Color |
|------------|--------------|-------|
| Low | < 500 MB | Green |
| Medium | 500 MB - 1 GB | Yellow |
| High | 1 GB - 2 GB | Orange |
| Critical | > 2 GB | Red |

### Components
- **MemoryMonitor** (`Managers/MemoryMonitor.swift`): Polls system using `proc_pidinfo`
- **MemoryData** (`Models/MemoryData.swift`): Memory data model with formatting
- **MemoryChartView** (`Views/MemoryChartView.swift`): Sparkline chart UI
- **AppSettings** (`Models/AppSettings.swift`): Configurable settings

### Integration
1. When a process starts, `CommandRunner` calls `MemoryMonitor.startMonitoring(pid:projectId:)`
2. `MemoryMonitor` publishes memory updates via Combine streams
3. `MenuBarViewModel` stores history in `projectMemoryData: [UUID: [MemoryData]]`
4. `OutputViewerViewModel` exposes stats to the view
5. `OutputViewerView` displays the chart and current usage

---

## Project Groups

### Overview
Project groups allow users to:
- Group related projects together
- Run/stop multiple projects with one click
- Organize projects by environment (dev, staging, production)
- Color-code groups for visual identification

### Components
- **ProjectGroup** (`Models/ProjectGroup.swift`): Group data model
- **GroupConfigurationViewModel** (`ViewModels/GroupConfigurationViewModel.swift`): Group management logic
- **GroupConfigurationView** (`Views/GroupConfigurationView.swift`): Group UI

### Storage
Groups are persisted in UserDefaults under `"com.termul.groups"` key and managed by `ProjectManager`.

---

## Window Management

- All windows are created in `AppDelegate.swift`
- The popover (menu bar dropdown) uses `.transient` behavior
- Output viewer windows are tracked per project ID in `outputViewerWindows: [UUID: NSWindow]`
- Configuration and Port Killer windows are singleton references
- Settings and Group Configuration windows are singleton references
- Windows use `setFrameAutosaveName` for position restoration

---

## Error Handling

- `ProjectError` enum in `ProjectManager.swift` for project-specific errors
- `CommandRunner` sets `.failed(error)` status on process errors
- ViewModels expose `errorMessage: String?` for UI display
- Always validate file paths with `FileManager.default.fileExists(atPath:)`
- Memory monitoring gracefully handles process termination by stopping polling

---

## Feature: Delete Confirmation

To prevent accidental project deletion:
1. User clicks "Delete" button in menu
2. Delete confirmation dialog appears
3. User must type the project name exactly to confirm
4. Only then is the deletion allowed
5. This is implemented in `DeleteProjectConfirmationView.swift`

---

## Feature: App Settings

Users can configure app-wide settings via `SettingsView.swift`:
- Toggle memory tracking on/off
- Adjust memory polling interval (1-10 seconds)
- Set maximum memory history points (50-1000)
- Toggle memory chart visibility

Settings are persisted via `AppSettings` model and accessible via `AppSettings.shared`.

---

## Feature: Git Branch Tracking

### Overview
Termul automatically detects and displays the current git branch for each project. This feature:
- Checks if a project directory is a git repository
- Fetches the current branch name using `git branch --show-current`
- Displays the branch name as a small indicator next to the project name
- Persists branch information in the Project model
- Updates branch info when a project is run

### Components
- **Project** (`Models/Project.swift`): Added `currentGitBranch: String?` property
- **CommandRunner** (`Managers/CommandRunner.swift`): Added `fetchGitBranch(projectPath:)` method
- **MenuBarViewModel** (`ViewModels/MenuBarViewModel.swift`): Added `projectGitBranches` dictionary and `fetchGitBranch(for:)` method
- **MenuBarView** (`Views/MenuBarView.swift`): Added `gitBranchIndicator` view component

### Integration
1. When a project runs, `MenuBarViewModel.runProject()` calls `fetchGitBranch(for:)`
2. `CommandRunner.fetchGitBranch()` checks if `.git` directory exists and runs git command
3. Branch name is stored in `MenuBarViewModel.projectGitBranches` and persisted in Project model
4. `MenuBarView` displays branch as a small badge with git branch icon

### UI Display
The git branch indicator shows:
- Git branch icon (small git.branch icon)
- Branch name in monospace font
- Sage green color scheme
- Truncates long branch names with ellipsis
- Only displays if branch info is available

---

## Cross-Platform Development

### Common Patterns

When implementing Windows or Linux versions, follow these architectural principles:

1. **Core Logic Separation**: Platform-specific implementations should share:
   - Data models (Project, ProjectGroup, ProcessStatus, etc.)
   - Storage persistence concepts (though implementation differs)
   - Business logic patterns

2. **Platform-Specific UI**: Each platform uses its native UI framework:
   - macOS: SwiftUI
   - Windows: WPF
   - Linux: GTK

3. **Configuration Compatibility**: Use a compatible configuration format (JSON) across platforms to allow importing/exporting settings.

### Shared Code Strategy

When adding shared functionality:
- Document the expected interface/protocol
- Provide implementation notes in each platform's README
- Keep data models compatible through serialization (JSON)
- Maintain feature parity where platform capabilities allow