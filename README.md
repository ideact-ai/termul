# Termul

**Your Development Environment, One Click Away**

Termul is a cross-platform development environment management tool that runs your entire development stack with a single click. Whether you're managing a microservices architecture, a full-stack web app, or multiple development environments — Termul keeps everything running at your fingertips.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Linux](https://img.shields.io/badge/Linux-Planned-yellow)
![Windows](https://img.shields.io/badge/Windows-Planned-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 Why You Need Termul

**The Problem:**
- 10+ terminal windows crowding your screen
- Constant context switching between editor and terminal
- Forgotten processes eating up your RAM
- Setting up your dev environment every morning takes 15+ minutes
- "Which port was that running on again?"

**The Solution:**
- One tap to run your entire development stack
- All processes visible from your system tray/menu bar
- Automatic environment setup (Nix, direnv, virtualenv — it handles them all)
- Zero overhead when you're not using it
- Instant access to real-time logs

**Result:** You stay in flow, your machine stays fast, and your projects are always ready to go.

---

## 🌍 Cross-Platform Support

Termul is designed to work across all major operating systems:

| Platform | Status | UI Framework |
|----------|--------|--------------|
| **macOS** | ✅ Available | SwiftUI |
| **Windows** | 🚧 Planned | WPF |
| **Linux** | 🚧 Planned | GTK |

This README covers the **macOS version**. Windows and Linux versions are under development.

---

## ⚡ What Termul Does

### 🚀 **One-Click Execution**
Configure any project once — run it forever. `make run-dev`, `npm start`, `docker-compose up`, `go run` — Termul executes it all with a single click from your menu bar.

### 🔄 **Automatic Environment Setup**
Termul understands your development environment. It automatically:
- Sources your Nix profiles
- Loads `.envrc` files via direnv
- Activates virtual environments
- Applies project-specific configurations

No more "command not found" errors. No more manual setup every morning.

### 📊 **Real-Time Visibility**
Need to see what's happening? One click opens a terminal-like output viewer with:
- Color-coded output (stdout, stderr, system messages)
- Auto-scrolling to show latest logs
- Copy to clipboard or save to file
- Clear output to reduce clutter

### 💾 **Memory Tracking**
Monitor your project's memory usage in real-time:
- Track memory usage over time
- Visual sparkline charts with gradients
- Color-coded thresholds (green/yellow/orange/red)
- Detailed statistics (min, max, average)

### 🎛️ **Instant Control**
- **Start** any project instantly
- **Stop** processes gracefully
- **Monitor** status with visual indicators
- **Kill** processes on stuck ports (port 3000 taken again? Not anymore.)

### 💎 **Native & Lightweight**
Built with SwiftUI for macOS. No Electron bloat. No background CPU usage. It uses ~30MB RAM and 0% CPU when idle. It's so light you'll forget it's running — until you need it.

---

## 🛠️ How It Works

### 1. Add Your Projects (One-Time Setup)
```
Click + → Select folder → Enter command → Done
```

Example configurations:
```
React App:     npm start
Django API:    python manage.py runserver
Go Service:    go run main.go
Docker Stack:  docker-compose up
Makefile:      make dev
```

### 2. Run Everything Instantly
Click your project in the menu bar → It starts. That's it.

### 3. Monitor & Control
- See all running projects at a glance
- Click any project to view real-time logs
- Stop, restart, or delete projects instantly
- Kill processes occupying your ports
- Monitor memory usage over time

---

## 📦 Installation

### Prerequisites (macOS)
- macOS 14.0+ (Sonoma or later)
- Swift 5.9+ (comes with Xcode Command Line Tools)

Install Xcode Command Line Tools if needed:
```bash
xcode-select --install
```

### Quick Start (3 Minutes)

#### Option 1: Build from Source (Recommended)
```bash
# Clone the repository
git clone https://github.com/yourusername/termul.git
cd termul/macOS

# Build
swift build

# Run
swift run Termul
```

#### Option 2: Build .app Bundle
```bash
cd termul/macOS
chmod +x build.sh
./build.sh
open build/Termul.app
```

#### Option 3: Create Disk Image Installer (.dmg)
```bash
cd termul/macOS

# First build the .app bundle
chmod +x build.sh && ./build.sh

# Then create the DMG installer
chmod +x build_installer.sh && ./build_installer.sh

# Open the DMG
open build/Termul-Installer.dmg

# Drag Termul to Applications folder
```

#### Option 4: Using Makefile (Easiest)
```bash
cd termul/macOS

# Show all available commands
make help

# Build .app bundle
make app

# Build macOS disk image installer
make installer

# Run the app
make run-app

# Build everything (app + installer)
make all

# Clean build artifacts
make clean

# Uninstall from /Applications
make uninstall

# Open the DMG installer
make install
```

### Auto-Start at Login
1. **System Settings** → **General** → **Login Items**
2. Click **+** → Add `Termul.app`
3. Enable it → Done

Your entire development stack is now one click away, every time you start your Mac.

---

## 🎨 Who Is This For?

- **Full-Stack Developers**: Run frontend, backend, and databases simultaneously
- **Microservices Architects**: Manage 10+ services without terminal chaos
- **Freelancers**: Switch between client projects instantly
- **Consultants**: Spin up demo environments in seconds
- **Students**: Focus on learning, not environment setup
- **Anyone** who's tired of terminal tab fatigue

---

## 📚 Common Use Cases

### Full-Stack Development
```
Frontend (React)    → npm start (port 3000)
Backend (Node.js)   → npm run api (port 4000)
Database (Mongo)    → docker-compose up (port 27017)
Cache (Redis)       → redis-server (port 6379)
```
Click 4 times → Entire stack running. No terminal needed.

### Microservices
```
User Service        → go run cmd/user/main.go (port 8001)
Auth Service        → go run cmd/auth/main.go (port 8002)
Payment Service     → go run cmd/payment/main.go (port 8003)
Notification Svc    → go run cmd/notify/main.go (port 8004)
API Gateway         → nginx -c nginx.conf (port 8080)
```
5 microservices, 1 menu bar.

### Contract Work
```
Client A (Laravel)  → php artisan serve (port 8000)
Client B (Django)   → manage.py runserver (port 9000)
Client C (Rails)    → rails server (port 3000)
Personal Project    → npm start (port 5000)
```
Switch contexts in seconds, not minutes.

---

## 🔧 Technical Highlights (macOS)

### Architecture
- **MVVM Pattern** with SwiftUI for clean, maintainable code
- **Combine Framework** for reactive state management
- **Native AppKit Integration** for seamless menu bar experience
- **UserDefaults Persistence** — your configurations sync automatically

### Security & Performance
- **Sandbox-safe** with proper entitlements
- **Minimal footprint**: ~30MB RAM, 0% CPU idle
- **No background processes** — only runs when you use it
- **Privacy-first**: No telemetry, no data collection

### Supported Stack
- **Languages**: JavaScript, TypeScript, Python, Go, Rust, Java, Ruby, PHP, C/C++, and more
- **Package Managers**: npm, yarn, pnpm, pip, poetry, cargo, gradle, maven, bundler, composer
- **Orchestrators**: Docker, Docker Compose, Kubernetes (kubectl), Nomad
- **Build Systems**: Make, CMake, Meson, Bazel, Webpack, Vite, Turbopack

---

## 🏗️ Project Structure

```
termul/
├── README.md                    # This file
├── AGENT.md                     # AI Agent rules for development
├── .gitignore                   # Git ignore rules
│
├── macOS/                       # macOS implementation (Swift)
│   ├── Package.swift           # Swift Package Manager manifest
│   ├── build.sh                # App bundle build script
│   ├── build_installer.sh      # DMG installer build script
│   ├── uninstall.sh            # Uninstaller script
│   ├── Makefile                # Build automation
│   ├── notarize.sh             # Code notarization script
│   │
│   ├── Termul/                 # Source code
│   │   ├── main.swift
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   ├── Termul.entitlements
│   │   ├── Models/
│   │   ├── Managers/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   └── Resources/
│   │
│   ├── .build/                 # SPM build artifacts
│   ├── .swiftpm/               # SPM cache
│   └── build/                  # Build output
│
├── Windows/                    # Windows implementation (planned)
│   └── README.md
│
└── Linux/                      # Linux implementation (planned)
    └── README.md
```

---

## 🎯 Feature Highlights

### ✅ Done in v1.0 (macOS)
- Add, edit, and delete projects
- Run and stop any command
- Real-time output viewing
- Automatic environment loading (Nix + direnv)
- Process status monitoring
- Port scanning and killing
- Project configuration persistence
- Native macOS menu bar integration
- Real-time memory tracking
- Memory usage charts and statistics
- Project groups for organization

### 🚀 Coming Soon
- **Windows Version**: WPF-based tray application
- **Linux Version**: GTK-based tray application
- Multiple commands per project
- Custom keyboard shortcuts
- Import/export configurations
- Project templates
- Git status indicators
- Build status notifications
- Team configuration sharing

---

## 💡 Pro Tips

### 1. Use Meaningful Names
Instead of "Project 1", use "Client A - Production" or "Auth Service - Dev"

### 2. Leverage Environment Loading
Termul automatically loads `.envrc` files — put your environment variables there instead of hardcoding them in commands.

### 3. Group Related Projects
Use project groups to organize your work by environment (dev, staging, production) or by client.

### 4. Use Port Killer
If a process is stuck, use the Port Killer to free up the port without hunting down PIDs in Terminal.

### 5. Monitor Memory Usage
Keep an eye on memory-intensive projects using the built-in memory tracking. Set appropriate thresholds in Settings.

---

## 🤝 Contributing

Want to make Termul even better? We'd love your help!

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

Check [AGENT.md](AGENT.md) for detailed development guidelines and architecture rules.

### Platform-Specific Development
- **macOS**: See [macOS/README.md](macOS/) for macOS-specific development setup
- **Windows**: See [Windows/README.md](Windows/) for Windows implementation notes (planned)
- **Linux**: See [Linux/README.md](Linux/) for Linux implementation notes (planned)

---

## 🐛 Reporting Issues

Found a bug? Have a feature request?

- Check existing [Issues](https://github.com/yourusername/termul/issues) first
- Create a new issue with:
  - Clear title and description
  - Steps to reproduce
  - Expected vs actual behavior
  - System information (OS version, Termul version)
  - Screenshots or logs if applicable

---

## 📜 License

MIT License — feel free to use Termul in personal and commercial projects.

See [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Built with ❤️ for developers who value their time and mental energy.

Inspired by the daily frustration of managing 15 terminal tabs just to run a simple web application.

---

## 📞 Get in Touch

- 📧 **Email**: support@termul.dev
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/termul/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/termul/discussions)
- ⭐ **Star us on GitHub** if Termul saves you time!

---

## 🎉 Ready to Simplify Your Workflow?

**Stop managing terminals. Start building.**

```bash
git clone https://github.com/yourusername/termul.git
cd termul/macOS
make installer
open build/Termul-Installer.dmg
# Drag Termul to Applications folder
```

Your development environment, one click away. 🚀

---

*Made with ❤️ for developers who demand speed, simplicity, and sanity across all platforms.*