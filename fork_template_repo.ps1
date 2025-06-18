#
# Jetsite - GitHub Template Repository Forker (Windows PowerShell Version)
# 
# This script automates the process of creating new projects from GitHub template
# repositories. It handles repository creation, fallback mechanisms, local cloning,
# and VS Code integration.
#
# Author: Jetsite Project
# Version: 1.0
# Requirements: GitHub CLI (gh), Git, VS Code (optional)
# Platform: Windows PowerShell
#

# Enable strict error handling
$ErrorActionPreference = "Stop"

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

# Verify that GitHub CLI is installed and available in PATH
# GitHub CLI is required for all repository operations
Write-Host ""
Write-Host "🔍 Checking dependencies..." -ForegroundColor Cyan

try {
    $null = Get-Command gh -ErrorAction Stop
    Write-Host "✅ GitHub CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "   Please install it from https://cli.github.com/" -ForegroundColor Yellow
    Write-Host "   After installation, run 'gh auth login' to authenticate." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Git is available
try {
    $null = Get-Command git -ErrorAction Stop
    Write-Host "✅ Git found" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Git is not installed." -ForegroundColor Red
    Write-Host "   Please install Git from https://git-scm.com/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================================
# USER INPUT COLLECTION
# ============================================================================

# Collect template repository information
# Format: owner/repository-name (e.g., "microsoft/vscode-extension-samples")
$defaultTemplateRepo = "owner/template-repo"
Write-Host ""
Write-Host "📋 Please provide the template repository information:" -ForegroundColor Cyan
$templateRepoInput = Read-Host "Template repo (owner/repo) [$defaultTemplateRepo]"

if ([string]::IsNullOrWhiteSpace($templateRepoInput)) {
    $TEMPLATE_REPO = $defaultTemplateRepo
} else {
    $TEMPLATE_REPO = $templateRepoInput.Trim()
}

# Collect new repository name
# This will be the name of your new project repository
Write-Host ""
Write-Host "📝 Enter the name for your new repository:" -ForegroundColor Cyan
$NEW_REPO_NAME = Read-Host "New repository name"

# Validate that repository name is not empty
if ([string]::IsNullOrWhiteSpace($NEW_REPO_NAME)) {
    Write-Host "❌ Error: New repository name cannot be empty." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$NEW_REPO_NAME = $NEW_REPO_NAME.Trim()

# ============================================================================
# REPOSITORY CREATION
# ============================================================================

# Primary method: Create repository from template
# This is the preferred method as it creates a clean copy without git history
Write-Host ""
Write-Host "🚀 Creating repository '$NEW_REPO_NAME' from template '$TEMPLATE_REPO'..." -ForegroundColor Cyan

try {
    # Try to create repository from template
    $createResult = & gh repo create $NEW_REPO_NAME --template $TEMPLATE_REPO --public 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Template-based repository created successfully." -ForegroundColor Green
        $creationSuccessful = $true
    } else {
        throw "Template creation failed"
    }
} catch {
    # Fallback method: Fork and rename
    # Used when template creation fails (e.g., permissions, repository type)
    Write-Host "⚠️  Template creation failed; falling back to forking method..." -ForegroundColor Yellow
    
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
        Write-Host "🔄 Renaming forked repository '$ORIGINAL_NAME' to '$NEW_REPO_NAME'..." -ForegroundColor Cyan
        & gh api --method PATCH "/repos/$OWNER/$ORIGINAL_NAME" -F name="$NEW_REPO_NAME"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to rename repository"
        }
        
        Write-Host "✅ Repository forked and renamed successfully." -ForegroundColor Green
        $creationSuccessful = $true    } catch {
        Write-Host "❌ Error: Both template creation and forking failed." -ForegroundColor Red
        Write-Host ""
        Write-Host "Common causes:" -ForegroundColor Yellow
        Write-Host "• You own the source repository (can't fork your own repo)" -ForegroundColor Yellow
        Write-Host "• Repository is not set up as a template" -ForegroundColor Yellow
        Write-Host "• Insufficient permissions" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Solutions:" -ForegroundColor Cyan
        Write-Host "• If it's your repo: Use .\clone_own_repo.ps1 instead" -ForegroundColor Cyan
        Write-Host "• Set up your repo as a template in GitHub Settings" -ForegroundColor Cyan
        Write-Host "• Try a different template repository" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ============================================================================
# LOCAL SETUP
# ============================================================================

# Clone the newly created repository to local machine
try {
    $GITHUB_USERNAME = & gh api user --jq .login
    $REPO_URL = "https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME.git"

    Write-Host ""
    Write-Host "📥 Cloning repository to local machine..." -ForegroundColor Cyan
    Write-Host "   Repository URL: $REPO_URL" -ForegroundColor Gray

    & git clone $REPO_URL
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed"
    }

    # Navigate to the project directory
    Set-Location $NEW_REPO_NAME
} catch {
    Write-Host "❌ Error: Failed to clone repository." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================================
# IDE INTEGRATION
# ============================================================================

# Open project in VS Code (if available)
Write-Host ""
Write-Host "🎨 Opening project in VS Code..." -ForegroundColor Cyan

try {
    $null = Get-Command code -ErrorAction Stop
    & code .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Project opened in VS Code successfully." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Failed to open VS Code. You can manually open the project." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  VS Code not found in PATH. You can manually open the project:" -ForegroundColor Yellow
    Write-Host "   Set-Location $NEW_REPO_NAME; code ." -ForegroundColor Gray
}

# ============================================================================
# COMPLETION
# ============================================================================

Write-Host ""
Write-Host "🎉 Setup complete! Your new project is ready." -ForegroundColor Green
Write-Host "   📁 Project directory: $(Get-Location)" -ForegroundColor Gray
Write-Host "   🌐 GitHub repository: https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME" -ForegroundColor Gray
Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Cyan

# Keep window open so user can see the results
Write-Host ""
Read-Host "Press Enter to exit"
