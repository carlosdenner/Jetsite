#
# Jetsite - Own Repository Cloner (Windows PowerShell Version)
# 
# This script helps when you want to create a new project based on your own repository
# (which cannot be forked due to GitHub's restrictions)
#
# Author: Jetsite Project
# Version: 1.0
#

# Enable strict error handling
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "🔄 Jetsite - Own Repository Cloner" -ForegroundColor Cyan
Write-Host "   Use this when you want to create a new project from your own repository" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

Write-Host "🔍 Checking dependencies..." -ForegroundColor Cyan

try {
    $null = Get-Command gh -ErrorAction Stop
    Write-Host "✅ GitHub CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "   Please install it from https://cli.github.com/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

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

# Get source repository
Write-Host ""
Write-Host "📋 Source repository information:" -ForegroundColor Cyan
$SOURCE_REPO = Read-Host "Source repository (owner/repo)"

if ([string]::IsNullOrWhiteSpace($SOURCE_REPO)) {
    Write-Host "❌ Error: Source repository cannot be empty." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Get new repository name
Write-Host ""
Write-Host "📝 New project information:" -ForegroundColor Cyan
$NEW_REPO_NAME = Read-Host "New repository name"

if ([string]::IsNullOrWhiteSpace($NEW_REPO_NAME)) {
    Write-Host "❌ Error: New repository name cannot be empty." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$NEW_REPO_NAME = $NEW_REPO_NAME.Trim()

# Ask about repository visibility
Write-Host ""
$visibilityChoice = Read-Host "Repository visibility (public/private) [public]"
if ([string]::IsNullOrWhiteSpace($visibilityChoice)) {
    $visibility = "public"
} else {
    $visibility = $visibilityChoice.ToLower().Trim()
}

if ($visibility -ne "public" -and $visibility -ne "private") {
    $visibility = "public"
    Write-Host "⚠️  Invalid visibility choice, defaulting to public" -ForegroundColor Yellow
}

# ============================================================================
# REPOSITORY CREATION AND SETUP
# ============================================================================

Write-Host ""
Write-Host "🚀 Creating and setting up your new project..." -ForegroundColor Cyan

try {
    # Step 1: Create empty repository
    Write-Host "📁 Creating empty repository '$NEW_REPO_NAME'..." -ForegroundColor Gray
    if ($visibility -eq "private") {
        & gh repo create $NEW_REPO_NAME --private --clone=false
    } else {
        & gh repo create $NEW_REPO_NAME --public --clone=false
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create repository"
    }
    
    Write-Host "✅ Empty repository created" -ForegroundColor Green

    # Step 2: Clone the source repository
    Write-Host "📥 Cloning source repository..." -ForegroundColor Gray
    $tempDir = "temp_$NEW_REPO_NAME"
    & git clone "https://github.com/$SOURCE_REPO.git" $tempDir
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone source repository"
    }

    # Step 3: Remove git history and set up new remote
    Set-Location $tempDir
    
    Write-Host "🔄 Setting up new repository..." -ForegroundColor Gray
    
    # Remove existing git history
    Remove-Item -Recurse -Force .git
    
    # Initialize new git repository
    & git init
    
    # Get current user
    $GITHUB_USERNAME = & gh api user --jq .login
    
    # Add new remote
    & git remote add origin "https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME.git"
    
    # Stage all files
    & git add .
    
    # Create initial commit
    & git commit -m "Initial commit from $SOURCE_REPO"
    
    # Push to new repository
    Write-Host "📤 Pushing to new repository..." -ForegroundColor Gray
    & git push -u origin main
    
    if ($LASTEXITCODE -ne 0) {
        # Try with 'master' branch if 'main' fails
        & git branch -M main
        & git push -u origin main
    }
    
    Write-Host "✅ Repository setup complete" -ForegroundColor Green

} catch {
    Write-Host "❌ Error during repository setup: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location ..
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================================
# CLEANUP AND FINALIZATION
# ============================================================================

# Rename directory to final name
Set-Location ..
if (Test-Path $NEW_REPO_NAME) {
    Remove-Item -Recurse -Force $NEW_REPO_NAME
}
Rename-Item $tempDir $NEW_REPO_NAME
Set-Location $NEW_REPO_NAME

# ============================================================================
# IDE INTEGRATION
# ============================================================================

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
Write-Host "   🔗 Source repository: https://github.com/$SOURCE_REPO" -ForegroundColor Gray
Write-Host ""
Write-Host "ℹ️  Note: This is a fresh copy without git history from the source repository." -ForegroundColor Cyan
Write-Host ""
Write-Host "Happy coding! 🚀" -ForegroundColor Cyan

Write-Host ""
Read-Host "Press Enter to exit"
