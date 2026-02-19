# Termul for Windows

**Status**: 🚧 Planned - Under Development

Termul for Windows is the Windows counterpart to the macOS version, designed to provide the same seamless development environment management experience through a system tray application.

---

## 🎯 Overview

Termul for Windows will be a native Windows application that lives in the system tray, allowing you to:
- Configure and run multiple development projects with a single click
- Monitor real-time output from running processes
- Kill processes on occupied ports
- Track memory usage over time
- Organize projects into groups
- Import/export configurations

---

## 🛠️ Technology Stack (Planned)

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Language** | C# 11+ | Modern, performant, great Windows integration |
| **UI Framework** | WPF (Windows Presentation Foundation) | Native Windows UI, good styling support |
| **Build System** | MSBuild | Standard .NET build tool |
| **Target Framework** | .NET 8.0+ | Latest LTS with performance improvements |
| **Package Manager** | NuGet | Rich ecosystem of libraries |
| **Icons** | .ico format | Native Windows icon format |

---

## 📁 Project Structure (Planned)

```
Windows/
├── Termul.Windows/                 # Main application project
│   ├── App.xaml                    # Application entry point
│   ├── App.xaml.cs                 # Application code-behind
│   ├── MainWindow.xaml             # Main window (configuration UI)
│   ├── MainWindow.xaml.cs          # Main window code-behind
│   ├── TrayIcon/                   # System tray icon management
│   │   ├── TrayIconService.cs      # Tray icon service
│   │   └── TrayIconMenu.xaml       # Context menu
│   │
│   ├── Models/                     # Data models (shared concepts)
│   │   ├── Project.cs              # Project model
│   │   ├── ProjectGroup.cs         # Project group model
│   │   ├── ProcessStatus.cs        # Process state enum
│   │   ├── CommandOutput.cs        # Output line model
│   │   ├── MemoryData.cs           # Memory usage data model
│   │   └── AppSettings.cs          # App-wide settings model
│   │
│   ├── Services/                   # Business logic
│   │   ├── ProjectManager.cs       # CRUD + persistence
│   │   ├── CommandRunner.cs        # Process execution
│   │   ├── PortKiller.cs           # Port scanning & killing
│   │   └── MemoryMonitor.cs       # Memory tracking
│   │
│   ├── ViewModels/                 # MVVM view models
│   │   ├── TrayViewModel.cs        # Tray icon state
│   │   ├── ConfigurationViewModel.cs  # Project configuration
│   │   ├── GroupConfigurationViewModel.cs  # Group management
│   │   └── OutputViewerViewModel.cs  # Output display
│   │
│   ├── Views/                      # WPF views
│   │   ├── ConfigurationView.xaml # Project configuration UI
│   │   ├── OutputViewerView.xaml  # Output viewer UI
│   │   ├── PortKillerView.xaml    # Port killer UI
│   │   ├── MemoryChartView.xaml   # Memory chart UI
│   │   └── SettingsView.xaml      # Settings UI
│   │
│   ├── Resources/                  # App resources
│   │   ├── Icons/                  # Application icons
│   │   └── Styles/                 # XAML styles
│   │
│   └── Properties/
│       └── app.manifest           # Application manifest
│
├── Termul.Windows.Tests/           # Unit tests
│   └── ...
│
├── Termul.Windows.sln              # Solution file
└── README.md                       # This file
```

---

## ✨ Planned Features

### Core Features
- ✅ System tray icon with context menu
- ✅ Add, edit, and delete projects
- ✅ Run and stop processes
- ✅ Real-time output viewing
- ✅ Process status monitoring
- ✅ Port scanning and killing
- ✅ Project configuration persistence
- ✅ Auto-start at Windows login

### Advanced Features
- 🚧 Memory usage tracking
- 🚧 Memory usage charts with OxyPlot or LiveCharts
- 🚧 Project groups for organization
- 🚧 Import/export configurations (JSON)
- 🚧 Keyboard shortcuts
- 🚧 Dark mode support

---

## 🔧 Development Notes

### Compatibility with macOS Version

To ensure consistency across platforms:

1. **Data Models**: Share similar structure with macOS version
   - Use same property names where possible
   - Maintain JSON serialization compatibility
   - Support configuration import/export between platforms

2. **UserDefaults vs. Windows Registry/Settings**
   - macOS uses `UserDefaults`
   - Windows will use `ApplicationSettingsBase` or JSON file storage
   - Both should support import/export of configurations

3. **Shell Command Execution**
   - macOS uses `$SHELL -l -c` with Nix/direnv support
   - Windows will use `cmd.exe /c` or PowerShell
   - Consider supporting WSL (Windows Subsystem for Linux) environments

### Key Technical Considerations

#### 1. System Tray Icon
```csharp
// Using WPF NotifyIcon or Hardcodet.NotifyIcon.Wpf
public class TrayIconService
{
    private NotifyIcon _notifyIcon;
    
    public void Initialize()
    {
        _notifyIcon = new NotifyIcon
        {
            Icon = new Icon("Resources/Icons/tray.ico"),
            Visible = true,
            Text = "Termul"
        };
        
        _notifyIcon.ContextMenuStrip = CreateContextMenu();
    }
}
```

#### 2. Process Execution
```csharp
public class CommandRunner
{
    public void RunCommand(string workingDirectory, string command)
    {
        var processStartInfo = new ProcessStartInfo
        {
            FileName = "cmd.exe",
            Arguments = $"/c \"{command}\"",
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        
        var process = Process.Start(processStartInfo);
        // Handle output streams
    }
}
```

#### 3. Port Scanning
```csharp
public class PortKiller
{
    public static bool IsPortInUse(int port)
    {
        var ipGlobalProperties = IPGlobalProperties.GetIPGlobalProperties();
        var tcpConnections = ipGlobalProperties.GetActiveTcpConnections();
        
        return tcpConnections.Any(x => x.LocalEndPoint.Port == port);
    }
}
```

#### 4. Memory Monitoring
```csharp
public class MemoryMonitor
{
    public long GetMemoryUsage(int processId)
    {
        var process = Process.GetProcessById(processId);
        return process.WorkingSet64;
    }
}
```

---

## 📦 Installation (Planned)

### Prerequisites
- Windows 10 version 1809+ or Windows 11
- .NET 8.0 Runtime (will be included in installer)

### Distribution Options
- **MSI Installer**: Traditional Windows installer
- **ClickOnce**: Web-based deployment
- **Portable ZIP**: No installation required

### Quick Installation (Planned)
```powershell
# Download and run MSI installer
# Follow setup wizard
# Termul will start automatically and add to startup
```

---

## 🚀 Building from Source (Planned)

```powershell
# Clone repository
git clone https://github.com/yourusername/termul.git
cd termul/Windows

# Build solution
dotnet build Termul.Windows.sln

# Run
dotnet run --project Termul.Windows
```

---

## 🤝 Contributing

We welcome contributions for the Windows version! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/windows-amazing-feature`)
3. Make your changes
4. Write tests for new functionality
5. Submit a pull request

### Code Style
- Follow C# coding conventions
- Use async/await for I/O operations
- Implement MVVM pattern consistently
- Add XML documentation comments for public APIs

---

## 📚 Documentation

- [Main README](../../README.md) - Project overview
- [AGENT.md](../../AGENT.md) - Development guidelines
- [macOS README](../macOS/) - macOS implementation reference

---

## 🐛 Known Issues

*This section will be updated as development progresses.*

---

## 📞 Contact

- 📧 **Email**: support@termul.dev
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/termul/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/termul/discussions)

---

## 📜 License

MIT License — see [LICENSE](../../LICENSE) file for details.

---

**Note**: This is a placeholder for the Windows version. Implementation is in progress. Check back soon for updates!