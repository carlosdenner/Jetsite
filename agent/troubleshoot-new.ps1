# Jetsite Demo Setup and Troubleshooting
# This script helps diagnose and fix common issues

Write-Host "Troubleshooting: Jetsite Demo Troubleshooting" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub CLI is installed and authenticated
Write-Host "Check: Checking GitHub Authentication..." -ForegroundColor Yellow
try {
    $ghAuth = gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK: GitHub CLI is authenticated" -ForegroundColor Green
        Write-Host "   $ghAuth" -ForegroundColor Gray
    } else {
        Write-Host "Error: GitHub CLI not authenticated" -ForegroundColor Red
        Write-Host "   Please run: gh auth login" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: GitHub CLI not installed" -ForegroundColor Red
    Write-Host "   Please install GitHub CLI: https://cli.github.com/" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Check: Checking Git Configuration..." -ForegroundColor Yellow
try {
    $gitUser = git config user.name 2>$null
    $gitEmail = git config user.email 2>$null
    
    if ($gitUser -and $gitEmail) {
        Write-Host "OK: Git is configured" -ForegroundColor Green
        Write-Host "   User: $gitUser" -ForegroundColor Gray
        Write-Host "   Email: $gitEmail" -ForegroundColor Gray
    } else {
        Write-Host "Error: Git not configured" -ForegroundColor Red
        Write-Host "   Please run: git config --global user.name 'Your Name'" -ForegroundColor Yellow
        Write-Host "   Please run: git config --global user.email 'your.email@example.com'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: Git not found" -ForegroundColor Red
    Write-Host "   Please install Git: https://git-scm.com/" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Check: Testing Jetsite Script..." -ForegroundColor Yellow
$jetsiteScript = "d:\repos\Jetsite\fork_template_repo_v2.ps1"

if (Test-Path $jetsiteScript) {
    Write-Host "OK: Jetsite script found: $jetsiteScript" -ForegroundColor Green
    
    # Test if script works
    try {
        $helpOutput = & $jetsiteScript -help
        Write-Host "OK: Jetsite script help works" -ForegroundColor Green
    } catch {
        Write-Host "Error: Jetsite script error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Error: Jetsite script not found: $jetsiteScript" -ForegroundColor Red
    Write-Host "   Please ensure the Jetsite repository is cloned correctly" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Check: Checking Agent Status..." -ForegroundColor Yellow
try {
    $agentHealth = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET
    Write-Host "OK: Agent is running and healthy" -ForegroundColor Green
    Write-Host "   Uptime: $([math]::Round($agentHealth.uptime, 2)) seconds" -ForegroundColor Gray
} catch {
    Write-Host "Error: Agent not responding: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please start the agent: cd d:\repos\Jetsite\agent && node agent.js" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Solutions: Common Solutions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. GitHub Authentication:" -ForegroundColor White
Write-Host "   gh auth login" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Configure Git:" -ForegroundColor White
Write-Host "   git config --global user.name 'Your Name'" -ForegroundColor Gray
Write-Host "   git config --global user.email 'your.email@example.com'" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Start the Agent:" -ForegroundColor White
Write-Host "   cd d:\repos\Jetsite\agent" -ForegroundColor Gray
Write-Host "   node agent.js" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Test API manually:" -ForegroundColor White
Write-Host "   curl -X GET http://localhost:3000/health" -ForegroundColor Gray
Write-Host ""

# Try a simple test request
Write-Host "Test: Testing API with simple request..." -ForegroundColor Yellow

$testBody = @{
    template = "carlosdenner/Jetsite_template"
    name = "test-repo-$(Get-Date -Format 'HHmmss')"
    visibility = "public"
} | ConvertTo-Json

try {
    $testResponse = Invoke-RestMethod -Uri "http://localhost:3000/create-repository" -Method POST -Body $testBody -ContentType "application/json"
    Write-Host "OK: Test request successful!" -ForegroundColor Green
    Write-Host "   Task ID: $($testResponse.taskId)" -ForegroundColor Gray
    
    # Check task status
    Start-Sleep 2
    $taskStatus = Invoke-RestMethod -Uri "http://localhost:3000/task/$($testResponse.taskId)" -Method GET
    Write-Host "   Task Status: $($taskStatus.status)" -ForegroundColor Gray
    
    if ($taskStatus.status -eq "failed") {
        Write-Host "   Error: $($taskStatus.error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error: Test request failed: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*401*") {
        Write-Host "   This is likely a GitHub authentication issue" -ForegroundColor Yellow
        Write-Host "   Make sure you're logged in with: gh auth login" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "1. Fix any authentication issues above" -ForegroundColor White
Write-Host "2. Restart the agent if needed" -ForegroundColor White
Write-Host "3. Try the demo again: .\quick-demo.ps1" -ForegroundColor White
Write-Host ""
