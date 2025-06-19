# Jetsite - Complete Repository Automation Platform

A comprehensive automation platform for creating, managing, and deploying GitHub repositories from templates. Jetsite combines powerful command-line tools with self-hosted agents to provide end-to-end project creation workflows.

## 🌟 Key Features

### 🚀 **Dual Interface Options**
- **Command Line Tools**: Cross-platform scripts for direct usage
- **Automation Agents**: Self-hosted REST API servers for integration

### 🔄 **Complete Workflow Automation**
- Create repositories from any GitHub template
- Automatic local cloning and setup
- VS Code integration with GitHub Copilot ready
- Post-creation command execution
- Real-time progress monitoring

### 🌍 **Cross-Platform Support**
- 🐧 **Linux/macOS**: Bash and PowerShell scripts
- 🪟 **Windows**: PowerShell, Command Prompt, and PowerShell Core
- 🐳 **Containers**: Docker and PM2 support

### 🤖 **Self-Hosted Agents**
- **Node.js Agent**: REST API with Express.js and task queues
- **PowerShell Agent**: HTTP server with job management
- **Web Interface**: Browser-based control panel
- **API Integration**: RESTful endpoints for external systems

## Quick Start

### 🎯 **Option 1: Command Line (Direct)**
```bash
# Clone Jetsite
git clone https://github.com/your-username/jetsite.git
cd jetsite

# Create a project (cross-platform)
./fork_template_repo.sh -t "owner/template" -n "my-project"
# OR on Windows:
.\fork_template_repo.ps1 -template "owner/template" -name "my-project"
```

### 🤖 **Option 2: Self-Hosted Agent**
```bash
# Start the automation agent
cd agent
npm install
.\start-agent.ps1

# Use REST API or Web Interface
curl -X POST http://localhost:3000/create-repository \
  -H "Content-Type: application/json" \
  -d '{"template": "owner/template", "name": "my-project"}'
```

### ⚡ **Option 3: Quick Demo**
```powershell
# Complete end-to-end demo
cd agent
.\quick-demo.ps1
# Creates project → Opens in VS Code → Ready for GitHub Copilot!
```

## 📋 Prerequisites

### **Required Tools**
- **GitHub CLI (`gh`)**: Repository operations
  - Install: https://cli.github.com/
  - Authenticate: `gh auth login`
- **Git**: Repository cloning
- **Node.js** (for agents): v16+ recommended
- **VS Code** (optional): Project editing with Copilot

### **Platform Requirements**
- 🐧 **Linux/macOS**: Bash 4.0+, PowerShell Core (optional)
- 🪟 **Windows**: PowerShell 5.1+, Command Prompt support
- 🐳 **Docker**: Node.js base images supported

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  API Clients    │───▶│  Jetsite Agent  │───▶│ GitHub Template │
│  Web Interface  │    │  (Node.js/PS)   │    │   Repository    │
│  Command Line   │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                               ▼
                       ┌─────────────────┐
                       │   Local Project │
                       │   VS Code +     │
                       │ GitHub Copilot  │
                       └─────────────────┘
```

## 📚 Available Components

### **Command Line Scripts**
- `fork_template_repo.sh` - Original bash implementation
- `fork_template_repo.ps1` - Enhanced PowerShell version  
- `fork_template_repo_v2.ps1` - Advanced features
- `fork_template_repo_simple.ps1` - Reliable, minimal version
- `clone_own_repo.ps1` - Clone from user repositories
- `jetsite.bat` - Windows Command Prompt wrapper

### **Automation Agents**
- `agent/agent.js` - Node.js REST API server
- `agent/jetsite-agent.ps1` - PowerShell HTTP server
- `agent/web-interface.html` - Browser-based UI
- `agent/start-agent.ps1` - Agent startup utility

### **Testing & Utilities**
- `agent/quick-demo.ps1` - End-to-end demonstration
- `agent/test-auth.ps1` - GitHub authentication testing
- `agent/troubleshoot-new.ps1` - System diagnostics
- `agent/debug-auth.ps1` - Authentication debugging

## 🚀 Usage Examples

### **Basic Repository Creation**
```bash
# Using bash script
./fork_template_repo.sh -t "microsoft/vscode-extension-samples" -n "my-extension"

# Using PowerShell
.\fork_template_repo.ps1 -template "microsoft/vscode-extension-samples" -name "my-extension" -visibility "public"
```

### **Agent API Usage**
```javascript
// Create repository via API
const response = await fetch('http://localhost:3000/create-repository', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    template: 'microsoft/vscode-extension-samples',
    name: 'my-extension',
    visibility: 'public',
    noVSCode: false
  })
});

const { taskId } = await response.json();

// Monitor progress
const task = await fetch(`http://localhost:3000/task/${taskId}`);
const status = await task.json();
```

### **Advanced Automation**
```powershell
# Full workflow with post-commands
.\fork_template_repo.ps1 `
  -template "your-username/react-template" `
  -name "my-react-app" `
  -visibility "private" `
  -postCommands "npm install && npm run dev" `
  -quiet
```

## 📖 Documentation

### **User Guides**
- [📘 Usage Guide](docs/USAGE.md) - Comprehensive usage instructions
- [🔧 Implementation Details](docs/IMPLEMENTATION.md) - Technical documentation
- [🚀 Examples](docs/EXAMPLES.md) - Real-world usage examples
- [🗺️ Roadmap](docs/ROADMAP.md) - Future development plans

### **API Reference**
- [🤖 Agent API](agent/README.md) - REST API documentation
- [🌐 Web Interface](agent/web-interface.html) - Browser-based control

### **Development**
- [🤝 Contributing](docs/CONTRIBUTING.md) - Contribution guidelines
- [📝 Changelog](docs/CHANGELOG.md) - Version history

## 🔧 Configuration

### **Environment Variables**
```bash
# GitHub Authentication
export GITHUB_TOKEN="gho_your_token_here"

# Agent Configuration
export PORT=3000
export WORK_DIR="./workspace"
export LOG_LEVEL="info"

# Script Selection
export JETSITE_SCRIPT="fork_template_repo_simple.ps1"
```

### **Agent Configuration**
```json
{
  "port": 3000,
  "workDir": "./workspace",
  "maxConcurrentTasks": 3,
  "taskRetentionHours": 24,
  "jetsiteScript": "../fork_template_repo_simple.ps1"
}
```

## 🎯 Real-World Examples

### **Create a React App**
```bash
# Command line
./fork_template_repo.sh -t "facebook/create-react-app" -n "my-react-project"

# API call
curl -X POST http://localhost:3000/create-repository \
  -H "Content-Type: application/json" \
  -d '{"template": "facebook/create-react-app", "name": "my-react-project"}'
```

### **VS Code Extension Development**
```powershell
# With automatic VS Code opening
.\fork_template_repo.ps1 -template "microsoft/vscode-extension-samples" -name "my-extension"

# Opens in VS Code with GitHub Copilot ready for AI-assisted development
```

### **Full Development Workflow**
```powershell
# Complete automation: Create → Setup → Develop
.\quick-demo.ps1
# Result: Repository created, dependencies installed, VS Code opened, development server running
```

## 🚀 Deployment Options

### **Local Development**
```bash
# Start agent locally
cd agent
npm install
.\start-agent.ps1
```

### **Process Manager (PM2)**
```bash
# Production deployment
npm install -g pm2
pm2 start ecosystem.config.js
pm2 monit
```

### **Docker (Future)**
```bash
# Containerized deployment
docker build -t jetsite-agent .
docker run -p 3000:3000 jetsite-agent
```

## 🛠️ Troubleshooting

### **Quick Diagnostics**
```powershell
# Run system diagnostics
.\agent\troubleshoot-new.ps1

# Test authentication
.\agent\debug-auth.ps1

# Validate templates
.\agent\test-template-check.ps1
```

### **Common Issues**
1. **401 Unauthorized**: Run `gh auth login` and restart agent
2. **Template not found**: Ensure repository is marked as template
3. **Script errors**: Use `fork_template_repo_simple.ps1` for reliability
4. **VS Code not opening**: Check VS Code installation and PATH

## 🎉 Success Stories

### **Complete Workflow Achievement**
✅ **Template → Repository → Local Setup → VS Code → GitHub Copilot**

The system successfully demonstrates:
- Repository creation from templates in **15-30 seconds**
- Automatic local cloning and dependency installation
- VS Code opening with GitHub Copilot ready for AI-assisted coding
- Real-time progress monitoring and error handling
- Cross-platform compatibility and reliability

## 📈 Performance

- **Task Creation**: < 1 second
- **Repository Creation**: 15-30 seconds  
- **Complete Workflow**: 30-60 seconds
- **Concurrent Tasks**: 3 (configurable)
- **Memory Usage**: ~50MB per agent
- **Supported Platforms**: Windows, Linux, macOS

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### **Quick Contribution**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 Acknowledgments

- **GitHub CLI Team** - For the excellent `gh` tool
- **VS Code Team** - For the amazing editor and GitHub Copilot
- **PowerShell Team** - For cross-platform PowerShell support
- **Open Source Community** - For inspiration and feedback

---

**Ready to automate your project creation workflow?**

🚀 [Get Started](#quick-start) | 📖 [Read the Docs](docs/) | 🤝 [Contribute](docs/CONTRIBUTING.md) | 🐛 [Report Issues](https://github.com/your-username/jetsite/issues)

1. Clone or download this repository:
   ```bash
   # Linux/macOS
   git clone <this-repo-url>
   cd Jetsite
   ```
   ```powershell
   # Windows PowerShell
   git clone <this-repo-url>
   Set-Location Jetsite
   ```

2. Make the script executable:

   **Linux/macOS:**
   ```bash
   chmod +x fork_template_repo.sh
   ```

   **Windows:**
   ```powershell
   # PowerShell scripts are executable by default
   # You may need to set execution policy if restricted:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. Optionally, add to your PATH for global access:

   **Linux/macOS:**
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/Jetsite"
   ```

   **Windows:**
   ```powershell
   # Add to PowerShell profile or system PATH
   # Or create an alias in your PowerShell profile:
   Set-Alias jetsite "C:\path\to\Jetsite\fork_template_repo.ps1"
   ```

## Usage

Run the appropriate script for your platform and follow the interactive prompts:

**Linux/macOS:**
```bash
./fork_template_repo.sh
```

**Windows PowerShell:**
```powershell
.\fork_template_repo.ps1
```

**Windows Command Prompt:**
```cmd
jetsite.bat
```

### Special Case: Using Your Own Repository

If you want to create a new project based on your own repository (which can't be forked), use the special clone script:

**Windows:**
```powershell
.\clone_own_repo.ps1
```

### Interactive Prompts

1. **Template Repository**: Enter the GitHub repository to use as a template
   - Format: `owner/repository-name`
   - Default: `owner/template-repo`
   - Example: `microsoft/vscode-extension-samples`

2. **New Repository Name**: Enter the name for your new repository
   - Must not be empty
   - Will be created under your GitHub account

### Example Session

**Linux/macOS:**
```bash
$ ./fork_template_repo.sh
📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: facebook/react
New repository name: my-awesome-app
🚀 Creating repository 'my-awesome-app' from template 'facebook/react'...
✅ Template-based repository created successfully.
📥 Cloning repository to local machine...
🎨 Opening project in VS Code...
🎉 Setup complete! Your new project is ready.
Happy coding! 🚀
```

**Windows:**
```powershell
PS> .\fork_template_repo.ps1
🔍 Checking dependencies...
✅ GitHub CLI found
✅ Git found

📋 Please provide the template repository information:
Template repo (owner/repo) [owner/template-repo]: facebook/react
New repository name: my-awesome-app
🚀 Creating repository 'my-awesome-app' from template 'facebook/react'...
✅ Template-based repository created successfully.
📥 Cloning repository to local machine...
🎨 Opening project in VS Code...
🎉 Setup complete! Your new project is ready.
Happy coding! 🚀
Press Enter to exit
```

## How It Works

The script follows this workflow:

1. **Validation**: Checks if GitHub CLI is installed and available
2. **Input Collection**: Prompts for template repository and new project name
3. **Repository Creation**: 
   - First attempts to create a repository from template using `gh repo create --template`
   - If that fails, falls back to forking and renaming the repository
4. **Local Setup**: 
   - Clones the new repository to your local machine
   - Changes to the project directory
   - Opens the project in VS Code

## Fallback Mechanism

If the primary template creation method fails, the script automatically:
1. Forks the template repository
2. Renames the forked repository to your desired name
3. Continues with the cloning process

This ensures maximum compatibility across different repository types and permissions.

## Error Handling

The script includes robust error handling:
- Validates GitHub CLI installation
- Ensures repository name is not empty
- Uses `set -euo pipefail` for strict error checking
- Provides clear error messages and exit codes

## Customization

You can modify the script to:
- Change the default template repository
- Add additional post-creation steps
- Integrate with different editors
- Add custom project initialization

## Troubleshooting

### Common Issues

1. **GitHub CLI not found**
   ```
   Error: GitHub CLI (gh) is not installed.
   ```
   **Solution**: Install GitHub CLI from https://cli.github.com/

2. **Authentication required**
   ```
   gh: To get started with GitHub CLI, please run: gh auth login
   ```
   **Solution**: Run `gh auth login` and follow the prompts

3. **Repository already exists**
   **Solution**: Choose a different repository name or delete the existing repository

4. **Permission denied**
   **Solution**: Ensure you have permission to create repositories in your GitHub account

## Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details.

## Documentation

- 📖 **[Usage Guide](docs/USAGE.md)** - Detailed usage instructions and advanced features
- 💡 **[Examples](docs/EXAMPLES.md)** - Practical examples and popular templates
- 🗺️ **[Roadmap](docs/ROADMAP.md)** - Planned features and development timeline
- 📝 **[Changelog](docs/CHANGELOG.md)** - Version history and release notes
- 🤝 **[Contributing](docs/CONTRIBUTING.md)** - How to contribute to the project

## What's Next?

We're actively developing Jetsite with exciting features planned:

### 🎯 Version 1.1 (Q3 2025)
- **Enhanced CLI**: Non-interactive mode, verbose output, progress indicators
- **Configuration Management**: Global config files, template bookmarking
- **PowerShell Improvements**: Core compatibility, tab completion

### 🚀 Version 1.2 (Q4 2025)
- **Multi-IDE Support**: IntelliJ, Sublime Text, Vim integration
- **Automation**: Post-creation hooks, dependency installation
- **VS Code Enhancements**: Extension recommendations, workspace setup

### 🌟 Version 2.0 (Q2 2026)
- **Container Support**: Docker integration, devcontainer setup
- **Cloud Integration**: AWS, Azure, Google Cloud platform support
- **AI Features**: Intelligent template recommendations

See our complete [Roadmap](docs/ROADMAP.md) for detailed plans and how to get involved!

## License

This project is open source. Please check the LICENSE file for details.

## Related Tools

- [GitHub CLI](https://cli.github.com/) - Official GitHub command line tool
- [cookiecutter](https://github.com/cookiecutter/cookiecutter) - Python-based project templating
- [degit](https://github.com/Rich-Harris/degit) - Straightforward project scaffolding

## Support

If you encounter issues or have questions:
1. Check the [Usage Guide](docs/USAGE.md) and [troubleshooting section](docs/USAGE.md#troubleshooting)
2. Review the [Examples](docs/EXAMPLES.md) for common scenarios
3. Create an issue in this repository
4. Consult the GitHub CLI documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
