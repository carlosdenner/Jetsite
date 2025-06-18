# Jetsite - GitHub Template Repository Forker

A cross-platform utility that streamlines the process of creating new projects from GitHub template repositories, with automatic cloning and VS Code integration.

## Overview

This project provides a convenient way to:
- Create new repositories from GitHub templates
- Automatically clone the new repository locally
- Open the project in VS Code
- Handle fallback scenarios when template creation fails

**Platform Support:**
- 🐧 **Linux/macOS**: Use `fork_template_repo.sh` (Bash script)
- 🪟 **Windows**: Use `fork_template_repo.ps1` (PowerShell script)

## Prerequisites

- **GitHub CLI (`gh`)**: Required for repository operations
  - Install from: https://cli.github.com/
  - Must be authenticated (`gh auth login`)
- **Git**: For cloning repositories
- **VS Code**: For automatically opening the project (optional)

**Platform-Specific Requirements:**
- 🐧 **Linux/macOS**: Bash-compatible shell
- 🪟 **Windows**: PowerShell 5.1+ (included with Windows 10/11)

## Installation

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

1. Fork this repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Related Tools

- [GitHub CLI](https://cli.github.com/) - Official GitHub command line tool
- [cookiecutter](https://github.com/cookiecutter/cookiecutter) - Python-based project templating
- [degit](https://github.com/Rich-Harris/degit) - Straightforward project scaffolding

## Support

If you encounter issues or have questions:
1. Check the troubleshooting section above
2. Create an issue in this repository
3. Consult the GitHub CLI documentation
