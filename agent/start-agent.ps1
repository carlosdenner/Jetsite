# Start Jetsite Agent with GitHub Authentication
# This script sets up the proper environment and starts the agent

Write-Host "Starting Jetsite Agent with GitHub Authentication..." -ForegroundColor Cyan

# Get GitHub token
try {
    $token = gh auth token 2>$null
    if ($token) {
        Write-Host "OK: GitHub token found" -ForegroundColor Green
        
        # Set environment variables
        $env:GITHUB_TOKEN = $token
        $env:GH_TOKEN = $token
        
        Write-Host "OK: Environment variables set" -ForegroundColor Green
    } else {
        Write-Host "Error: No GitHub token found. Please run: gh auth login" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: GitHub CLI not available: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Change to agent directory
Set-Location "d:\repos\Jetsite\agent"

# Start the agent
Write-Host "Starting Node.js agent..." -ForegroundColor Yellow
Write-Host "API will be available at: http://localhost:3000" -ForegroundColor Gray
Write-Host ""

# Start the agent with environment
node agent.js
