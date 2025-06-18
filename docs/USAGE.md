# Jetsite Usage Guide

This document provides detailed usage instructions for all Jetsite scripts and features.

## Table of Contents

- [Quick Start](#quick-start)
- [Script Reference](#script-reference)
- [Platform-Specific Usage](#platform-specific-usage)
- [Advanced Features](#advanced-features)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Install Dependencies

Ensure you have the required tools installed:

```bash
# Install GitHub CLI
# Visit: https://cli.github.com/

# Authenticate with GitHub
gh auth login

# Verify installation
gh --version
git --version
```

### 2. Choose Your Script

| Script | Purpose | Platform |
|--------|---------|----------|
| `fork_template_repo.sh` | Create from templates | Linux/macOS |
| `fork_template_repo.ps1` | Create from templates | Windows |
| `clone_own_repo.ps1` | Clone your own repos | Windows |
| `jetsite.bat` | Batch wrapper | Windows CMD |

### 3. Run and Follow Prompts

```bash
# Show help
./fork_template_repo.sh --help

# Run interactively
./fork_template_repo.sh
```

## Script Reference

### fork_template_repo.sh / fork_template_repo.ps1

**Purpose:** Create new repositories from GitHub templates

**Usage:**
```bash
./fork_template_repo.sh [OPTIONS]
```

**Options:**
- `-h, --help` - Show help message

**Interactive Prompts:**
1. **Template Repository**: Enter `owner/repository-name`
2. **New Repository Name**: Enter your project name

**Process:**
1. Validates dependencies (GitHub CLI, Git)
2. Creates repository from template
3. Falls back to fork+rename if needed
4. Clones locally
5. Opens in VS Code

### clone_own_repo.ps1

**Purpose:** Create new projects from your own repositories

**Usage:**
```powershell
.\clone_own_repo.ps1 [OPTIONS]
```

**Options:**
- `-h, --help` - Show help message

**Interactive Prompts:**
1. **Source Repository**: Your repository to copy from
2. **New Repository Name**: Name for the new project
3. **Visibility**: Public or private

**Process:**
1. Creates empty repository on GitHub
2. Clones source repository
3. Removes git history
4. Sets up fresh git history
5. Pushes to new repository
6. Opens in VS Code

## Platform-Specific Usage

### Windows PowerShell

```powershell
# Method 1: Direct PowerShell execution
.\fork_template_repo.ps1

# Method 2: Through batch wrapper
.\jetsite.bat

# Show help
.\fork_template_repo.ps1 -help
```

**Execution Policy:**
If you encounter execution policy errors:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Linux/macOS Bash

```bash
# Make executable (first time only)
chmod +x fork_template_repo.sh

# Run script
./fork_template_repo.sh

# Show help
./fork_template_repo.sh --help
```

### Windows Command Prompt

```cmd
REM Use the batch wrapper
jetsite.bat
```

## Advanced Features

### Environment Variables

You can set environment variables to customize behavior:

```bash
# Set default template
export JETSITE_DEFAULT_TEMPLATE="your-org/your-template"

# Set default clone directory
export JETSITE_CLONE_DIR="/path/to/projects"
```

### Configuration File

Edit `.jetsite.config` to set defaults:

```bash
# Default template repository
DEFAULT_TEMPLATE_REPO="microsoft/vscode-extension-samples"

# Default repository visibility
DEFAULT_VISIBILITY="public"

# Auto-open VS Code
AUTO_OPEN_VSCODE=true
```

### Batch Operations

For creating multiple projects:

```bash
#!/bin/bash
# batch_create.sh
projects=("project1" "project2" "project3")
template="your-org/template"

for project in "${projects[@]}"; do
    echo "$template" | echo "$project" | ./fork_template_repo.sh
done
```

## Troubleshooting

### Common Issues and Solutions

#### GitHub CLI Not Found
```
Error: GitHub CLI (gh) is not installed.
```
**Solution:** Install from https://cli.github.com/

#### Authentication Required
```
gh: To get started with GitHub CLI, please run: gh auth login
```
**Solution:** Run `gh auth login` and follow prompts

#### Repository Already Exists
**Solution:** 
- Choose a different name
- Delete existing repository
- Use existing repository

#### Permission Denied (PowerShell)
```
execution of scripts is disabled on this system
```
**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Can't Fork Own Repository
```
cannot be forked. A single user account cannot own both a parent and fork.
```
**Solution:** Use `clone_own_repo.ps1` instead

#### VS Code Not Opening
**Solution:** 
- Ensure VS Code is in PATH
- Install VS Code from https://code.visualstudio.com/
- Manually open: `cd project && code .`

### Debug Mode

Enable verbose output for troubleshooting:

**Bash:**
```bash
bash -x ./fork_template_repo.sh
```

**PowerShell:**
```powershell
$VerbosePreference = "Continue"
.\fork_template_repo.ps1
```

### Getting Help

1. Check this usage guide
2. Review [examples](EXAMPLES.md)
3. Check [troubleshooting section](#troubleshooting)
4. Open an issue on GitHub
5. Review GitHub CLI documentation

## Best Practices

### Repository Naming
- Use descriptive names
- Follow kebab-case convention
- Avoid special characters
- Keep under 100 characters

### Template Selection
- Choose actively maintained templates
- Verify template compatibility
- Check license compatibility
- Review template documentation

### Project Organization
- Create projects in dedicated workspace
- Use consistent naming conventions
- Organize by technology or purpose
- Keep templates bookmarked

### Security
- Review template code before use
- Keep GitHub CLI updated
- Use strong authentication
- Be cautious with private repositories
