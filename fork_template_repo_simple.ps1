# Simple working Jetsite script that bypasses syntax issues
param(
    [string]$template,
    [string]$name,
    [string]$visibility = "public",
    [switch]$noVSCode,
    [string]$postCommands,
    [switch]$quiet,
    [switch]$help
)

if ($help) {
    Write-Host "Simple Jetsite Script - Creates repositories from templates"
    Write-Host "Usage: script.ps1 -template user/repo -name newname [-visibility public|private]"
    exit 0
}

try {
    # Set up environment
    if (-not $env:GITHUB_TOKEN) {
        $env:GITHUB_TOKEN = gh auth token 2>$null
    }
    
    Write-Host "Creating repository: $name from template: $template" -ForegroundColor Cyan
    
    # Create repository from template
    $result = gh repo create $name --template $template --$visibility --clone 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Success: Repository created and cloned to: $name" -ForegroundColor Green
        
        # Change to the new directory
        if (Test-Path $name) {
            Set-Location $name
            
            # Run post commands if specified
            if ($postCommands) {
                Write-Host "Running post commands: $postCommands" -ForegroundColor Yellow
                Invoke-Expression $postCommands
            }
            
            # Open in VS Code if not disabled
            if (-not $noVSCode) {
                try {
                    Start-Process "code" -ArgumentList "." -NoNewWindow
                    Write-Host "Opened in VS Code" -ForegroundColor Green
                } catch {
                    Write-Host "Could not open VS Code: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
        
        exit 0
    } else {
        throw "Repository creation failed: $result"
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
