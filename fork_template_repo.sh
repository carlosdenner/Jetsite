#!/usr/bin/env bash
#
# Jetsite - GitHub Template Repository Forker
# 
# This script automates the process of creating new projects from GitHub template
# repositories. It handles repository creation, fallback mechanisms, local cloning,
# and VS Code integration.
#
# Author: Jetsite Project
# Version: 1.0
# Requirements: GitHub CLI (gh), Git, VS Code (optional)
#

# ============================================================================
# HELP SYSTEM
# ============================================================================

show_help() {
    cat << EOF

🚀 Jetsite - GitHub Template Repository Forker
   Create new projects from GitHub template repositories

USAGE:
   ./fork_template_repo.sh [OPTIONS]

OPTIONS:
   -h, --help    Show this help message

DESCRIPTION:
   This script helps you create new GitHub repositories from templates.
   It will prompt you for:
   • Template repository (owner/repo format)
   • New repository name

   The script will:
   1. Create a new repository from the template
   2. Fall back to forking if template creation fails
   3. Clone the repository locally
   4. Open the project in VS Code

REQUIREMENTS:
   • GitHub CLI (gh) - Install from https://cli.github.com/
   • Git - For cloning repositories
   • VS Code (optional) - For automatic project opening

EXAMPLES:
   ./fork_template_repo.sh
   # Follow the interactive prompts

SPECIAL CASES:
   • GitHub doesn't allow forking your own repositories
   • Use a different script for cloning your own repos

MORE INFO:
   • Documentation: README.md
   • Usage Guide: docs/USAGE.md
   • Examples: docs/EXAMPLES.md
   • Contributing: docs/CONTRIBUTING.md

EOF
}

# Check for help flags
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Enable strict error handling
# -e: Exit immediately if a command exits with a non-zero status
# -u: Treat unset variables as an error when substituting
# -o pipefail: The return value of a pipeline is the status of the last command to exit with a non-zero status
set -euo pipefail

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

# Verify that GitHub CLI is installed and available in PATH
# GitHub CLI is required for all repository operations
if ! command -v gh &>/dev/null; then
  echo "❌ Error: GitHub CLI (gh) is not installed."
  echo "   Please install it from https://cli.github.com/"
  echo "   After installation, run 'gh auth login' to authenticate."
  exit 1
fi

# ============================================================================
# USER INPUT COLLECTION
# ============================================================================
# Collect template repository information
# Format: owner/repository-name (e.g., "microsoft/vscode-extension-samples")
default_template_repo="owner/template-repo"
echo "📋 Please provide the template repository information:"
read -p "Template repo (owner/repo) [${default_template_repo}]: " TEMPLATE_REPO
TEMPLATE_REPO=${TEMPLATE_REPO:-$default_template_repo}

# Collect new repository name
# This will be the name of your new project repository
echo ""
echo "📝 Enter the name for your new repository:"
read -p "New repository name: " NEW_REPO_NAME

# Validate that repository name is not empty
if [[ -z "$NEW_REPO_NAME" ]]; then
  echo "❌ Error: New repository name cannot be empty."
  exit 1
fi

# ============================================================================
# REPOSITORY CREATION
# ============================================================================
# Primary method: Create repository from template
# This is the preferred method as it creates a clean copy without git history
echo ""
echo "🚀 Creating repository '$NEW_REPO_NAME' from template '$TEMPLATE_REPO'..."

if gh repo create "$NEW_REPO_NAME" --template "$TEMPLATE_REPO" --public; then
  echo "✅ Template-based repository created successfully."
else
  # Fallback method: Fork and rename
  # Used when template creation fails (e.g., permissions, repository type)
  echo "⚠️  Template creation failed; falling back to forking method..."
  
  # Fork the template repository
  gh repo fork "$TEMPLATE_REPO" --clone=false
  
  # Get current user's GitHub username
  OWNER=$(gh api user --jq .login)
  
  # Extract original repository name from template path
  ORIGINAL_NAME=$(basename "$TEMPLATE_REPO")
  
  # Rename the forked repository to the desired name
  echo "🔄 Renaming forked repository '$ORIGINAL_NAME' to '$NEW_REPO_NAME'..."
  gh api --method PATCH "/repos/$OWNER/$ORIGINAL_NAME" -F name="$NEW_REPO_NAME"
  
  echo "✅ Repository forked and renamed successfully."
fi

# ============================================================================
# LOCAL SETUP
# ============================================================================
# Clone the newly created repository to local machine
GITHUB_USERNAME=$(gh api user --jq .login)
REPO_URL="https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME.git"

echo ""
echo "📥 Cloning repository to local machine..."
echo "   Repository URL: $REPO_URL"

git clone "$REPO_URL"

# Navigate to the project directory
cd "$NEW_REPO_NAME"

# ============================================================================
# IDE INTEGRATION
# ============================================================================

# Open project in VS Code (if available)
echo ""
echo "🎨 Opening project in VS Code..."

if command -v code &>/dev/null; then
  code .
  echo "✅ Project opened in VS Code successfully."
else
  echo "⚠️  VS Code not found in PATH. You can manually open the project:"
  echo "   cd $NEW_REPO_NAME && code ."
fi

# ============================================================================
# COMPLETION
# ============================================================================

echo ""
echo "🎉 Setup complete! Your new project is ready."
echo "   📁 Project directory: $(pwd)"
echo "   🌐 GitHub repository: https://github.com/$GITHUB_USERNAME/$NEW_REPO_NAME"
echo ""
echo "Happy coding! 🚀"