#
# Jetsite - GitHub Template Repository Forker (Windows PowerShell Version)
# 
# This script automates the process of creating new projects from GitHub template
# repositories. It handles repository creation, fallback mechanisms, local cloning,
# and VS Code integration.
#
# Author: Jetsite Project
# Version: 1.1
# Requirements: GitHub CLI (gh), Git, VS Code (optional)
# Platform: Windows PowerShell
#

param(
    [switch]$h,
    [switch]$help,
    [string]$template,
    [string]$name,
    [string]$visibility = "public",
    [switch]$noVSCode,
    [switch]$quiet,
    [string]$postCommands
)

# Enable strict error handling
$ErrorActionPreference = "Stop"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Write-JetsiteOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$IsError,
        [switch]$IsSuccess,
        [switch]$IsWarning
    )
    
    if ($quiet -and -not $IsError) { return }
    
    if ($IsError) { $Color = "Red" }
    elseif ($IsSuccess) { $Color = "Green" }
    elseif ($IsWarning) { $Color = "Yellow" }
    
    Write-Host $Message -ForegroundColor $Color
}

# ============================================================================
# HELP SYSTEM
# ============================================================================

if ($h -or $help) {
    Write-Host ""
    Write-Host "🚀 Jetsite - GitHub Template Repository Forker" -ForegroundColor Cyan
    Write-Host "   Create new projects from GitHub template repositories" -ForegroundColor Gray
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "   .\fork_template_repo.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "   -h, -help                    Show this help message" -ForegroundColor White
    Write-Host "   -template <owner/repo>       Template repository to use" -ForegroundColor White
    Write-Host "   -name <repo-name>            Name for the new repository" -ForegroundColor White
    Write-Host "   -visibility <public|private> Repository visibility (default: public)" -ForegroundColor White
    Write-Host "   -noVSCode                    Skip opening VS Code" -ForegroundColor White
    Write-Host "   -quiet                       Suppress non-essential output" -ForegroundColor White
    Write-Host "   -postCommands <commands>     Commands to run after setup (semicolon separated)" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "   # Interactive mode" -ForegroundColor Gray
    Write-Host "   .\fork_template_repo.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "   # Non-interactive mode" -ForegroundColor Gray
    Write-Host "   .\fork_template_repo.ps1 -template 'facebook/react' -name 'my-app'" -ForegroundColor White
    Write-Host "   .\fork_template_repo.ps1 -template 'vercel/next.js' -name 'my-next-app' -visibility private" -ForegroundColor White
    Write-Host ""
    Write-Host "   # With post-creation commands" -ForegroundColor Gray
    Write-Host "   .\fork_template_repo.ps1 -template 'facebook/react' -name 'my-app' -postCommands 'npm install; npm start'" -ForegroundColor White
    Write-Host ""
    Write-Host "AGENT MODE:" -ForegroundColor Yellow
    Write-Host "   Perfect for automation and CI/CD pipelines:" -ForegroundColor White
    Write-Host "   .\fork_template_repo.ps1 -template 'my-org/template' -name 'project-001' -quiet -noVSCode" -ForegroundColor White
    Write-Host ""
    Write-Host "MORE INFO:" -ForegroundColor Yellow
    Write-Host "   • Documentation: README.md" -ForegroundColor White
    Write-Host "   • Usage Guide: docs/USAGE.md" -ForegroundColor White
    Write-Host "   • Agent Setup: agent/README.md" -ForegroundColor White
    Write-Host ""
    exit 0
}

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

Write-JetsiteOutput "🔍 Checking dependencies..." -Color "Cyan"

try {
    $null = Get-Command gh -ErrorAction Stop
    Write-JetsiteOutput "✅ GitHub CLI found" -IsSuccess
} catch {
    Write-JetsiteOutput "❌ Error: GitHub CLI (gh) is not installed." -IsError
    Write-JetsiteOutput "   Please install it from https://cli.github.com/" -Color "Yellow"
    Write-JetsiteOutput "   After installation, run 'gh auth login' to authenticate." -Color "Yellow"
    if (-not $quiet) { Read-Host "Press Enter to exit" }
    exit 1
}

try {
    $null = Get-Command git -ErrorAction Stop
    Write-JetsiteOutput "✅ Git found" -IsSuccess
} catch {
    Write-JetsiteOutput "❌ Error: Git is not installed." -IsError
    Write-JetsiteOutput "   Please install Git from https://git-scm.com/" -Color "Yellow"
    if (-not $quiet) { Read-Host "Press Enter to exit" }
    exit 1
}

# ============================================================================
# INPUT HANDLING (Interactive or Parameter-based)
# ============================================================================

# Handle template repository
if ([string]::IsNullOrWhiteSpace($template)) {
    $defaultTemplateRepo = "owner/template-repo"
    Write-JetsiteOutput "" 
    Write-JetsiteOutput "📋 Please provide the template repository information:" -Color "Cyan"
    $templateRepoInput = Read-Host "Template repo (owner/repo) [$defaultTemplateRepo]"
    
    if ([string]::IsNullOrWhiteSpace($templateRepoInput)) {
        $TEMPLATE_REPO = $defaultTemplateRepo
    } else {
        $TEMPLATE_REPO = $templateRepoInput.Trim()
    }
} else {
    $TEMPLATE_REPO = $template.Trim()
    Write-JetsiteOutput "Template: Using template repository: $TEMPLATE_REPO" -Color "Cyan"
}

# Handle repository name
if ([string]::IsNullOrWhiteSpace($name)) {
    Write-JetsiteOutput ""
    Write-JetsiteOutput "Name: Enter the name for your new repository:" -Color "Cyan"
    $NEW_REPO_NAME = Read-Host "New repository name"
} else {
    $NEW_REPO_NAME = $name.Trim()
    Write-JetsiteOutput "Name: Creating repository: $NEW_REPO_NAME" -Color "Cyan"
}

# Validate repository name
if ([string]::IsNullOrWhiteSpace($NEW_REPO_NAME)) {
    Write-JetsiteOutput "❌ Error: New repository name cannot be empty." -IsError
    if (-not $quiet) { Read-Host "Press Enter to exit" }
    exit 1
}

# Validate visibility
if ($visibility -ne "public" -and $visibility -ne "private") {
    Write-JetsiteOutput "⚠️  Invalid visibility '$visibility', defaulting to 'public'" -IsWarning
    $visibility = "public"
}

# ============================================================================
# REPOSITORY CREATION
# ============================================================================

Write-JetsiteOutput ""
Write-JetsiteOutput "🚀 Creating repository '$NEW_REPO_NAME' from template '$TEMPLATE_REPO'..." -Color "Cyan"

$visibilityFlag = if ($visibility -eq "private") { "--private" } else { "--public" }

try {
    # Try to create repository from template
    & gh repo create $NEW_REPO_NAME --template $TEMPLATE_REPO $visibilityFlag 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-JetsiteOutput "✅ Template-based repository created successfully." -IsSuccess
    } else {
        throw "Template creation failed"
    }
} catch {
    # Fallback method: Fork and rename
    Write-JetsiteOutput "⚠️  Template creation failed; falling back to forking method..." -IsWarning
    
    try {
        # Fork the template repository
        & gh repo fork $TEMPLATE_REPO --clone=false
        if ($LASTEXITCODE -ne 0) {
            throw "Fork failed"
        }
        
        # Get current user's GitHub username
        $OWNER = & gh api user --jq .login
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to get username"
        }
        
        # Extract original repository name from template path
        $ORIGINAL_NAME = Split-Path $TEMPLATE_REPO -Leaf
        
        # Rename the forked repository to the desired name
        Write-JetsiteOutput "🔄 Renaming forked repository '$ORIGINAL_NAME' to '$NEW_REPO_NAME'..." -Color "Cyan"
        & gh api --method PATCH "/repos/$OWNER/$ORIGINAL_NAME" -F name="$NEW_REPO_NAME"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to rename repository"
        }
        
        Write-JetsiteOutput "✅ Repository forked and renamed successfully." -IsSuccess
    } catch {
        Write-JetsiteOutput "❌ Error: Both template creation and forking failed." -IsError
        Write-JetsiteOutput ""
        Write-JetsiteOutput "Common causes:" -Color "Yellow"
        Write-JetsiteOutput "• You own the source repository (can't fork your own repo)" -Color "Yellow"
        Write-JetsiteOutput "• Repository is not set up as a template" -Color "Yellow"
        Write-JetsiteOutput "• Insufficient permissions" -Color "Yellow"
        Write-JetsiteOutput ""
        Write-JetsiteOutput "Solutions:" -Color "Cyan"
        Write-JetsiteOutput "• If it's your repo: Use .\clone_own_repo.ps1 instead" -Color "Cyan"
        Write-JetsiteOutput "• Set up your repo as a template in GitHub Settings" -Color "Cyan"
        Write-JetsiteOutput "• Try a different template repository" -Color "Cyan"
        Write-JetsiteOutput ""
        if (-not $quiet) { Read-Host "Press Enter to exit" }
        exit 1
    }
}

# ============================================================================
# LOCAL SETUP
# ============================================================================

try {    $GITHUB_USERNAME = & gh api user --jq .login
    $REPO_URL = "https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME.git"
    Write-JetsiteOutput ""
    Write-JetsiteOutput "Clone: Cloning repository to local machine..." -Color "Cyan"
    Write-JetsiteOutput "   Repository URL: $REPO_URL" -Color "Gray"

    & git clone $REPO_URL
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed"
    }

    # Navigate to the project directory
    Set-Location $NEW_REPO_NAME
    Write-JetsiteOutput "✅ Repository cloned successfully." -IsSuccess
} catch {
    Write-JetsiteOutput "❌ Error: Failed to clone repository." -IsError
    if (-not $quiet) { Read-Host "Press Enter to exit" }
    exit 1
}

# ============================================================================
# POST-CREATION COMMANDS
# ============================================================================

if (-not [string]::IsNullOrWhiteSpace($postCommands)) {
    Write-JetsiteOutput ""
    Write-JetsiteOutput "⚙️  Running post-creation commands..." -Color "Cyan"
    
    $commands = $postCommands -split ';'
    foreach ($cmd in $commands) {
        $cmd = $cmd.Trim()
        if (-not [string]::IsNullOrWhiteSpace($cmd)) {
            Write-JetsiteOutput "   > $cmd" -Color "Gray"
            try {
                Invoke-Expression $cmd
                if ($LASTEXITCODE -ne 0) {
                    Write-JetsiteOutput "⚠️  Command failed: $cmd" -IsWarning
                }
            } catch {
                Write-JetsiteOutput "⚠️  Error running command: $cmd" -IsWarning
            }
        }
    }
    Write-JetsiteOutput "✅ Post-creation commands completed." -IsSuccess
}

# ============================================================================
# IDE INTEGRATION
# ============================================================================

if (-not $noVSCode) {
    Write-JetsiteOutput ""
    Write-JetsiteOutput "🎨 Opening project in VS Code..." -Color "Cyan"

    try {
        $null = Get-Command code -ErrorAction Stop
        & code .
        if ($LASTEXITCODE -eq 0) {
            Write-JetsiteOutput "✅ Project opened in VS Code successfully." -IsSuccess
        } else {
            Write-JetsiteOutput "⚠️  Failed to open VS Code. You can manually open the project." -IsWarning
        }
    } catch {
        Write-JetsiteOutput "⚠️  VS Code not found in PATH. You can manually open the project:" -IsWarning
        Write-JetsiteOutput "   Set-Location $NEW_REPO_NAME; code ." -Color "Gray"
    }
}

# ============================================================================
# COMPLETION
# ============================================================================

Write-JetsiteOutput ""
Write-JetsiteOutput "🎉 Setup complete! Your new project is ready." -IsSuccess
Write-JetsiteOutput "   📁 Project directory: $(Get-Location)" -Color "Gray"
Write-JetsiteOutput "   🌐 GitHub repository: https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME" -Color "Gray"
Write-JetsiteOutput ""
Write-JetsiteOutput "Happy coding! 🚀" -Color "Cyan"

# Keep window open if running in interactive mode and not quiet
if (-not $quiet -and [string]::IsNullOrWhiteSpace($template)) {
    Write-JetsiteOutput ""
    Read-Host "Press Enter to exit"
}
