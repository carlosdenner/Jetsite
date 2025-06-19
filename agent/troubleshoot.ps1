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
    Write-Host "   Please install GitHub CLI: winget install GitHub.cli" -ForegroundColor Yellow
}

Write-Host ""

# Check if git is configured
Write-Host "📋 Checking Git Configuration..." -ForegroundColor Yellow
try {
    $gitUser = git config --global user.name
    $gitEmail = git config --global user.email
    
    if ($gitUser -and $gitEmail) {
        Write-Host "✅ Git is configured" -ForegroundColor Green
        Write-Host "   User: $gitUser" -ForegroundColor Gray
        Write-Host "   Email: $gitEmail" -ForegroundColor Gray
    } else {
        Write-Host "❌ Git not configured" -ForegroundColor Red
        Write-Host "   Please run:" -ForegroundColor Yellow
        Write-Host "   git config --global user.name 'Your Name'" -ForegroundColor Yellow
        Write-Host "   git config --global user.email 'your.email@example.com'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Git not found" -ForegroundColor Red
}

Write-Host ""

# Test the Jetsite script directly
Write-Host "📋 Testing Jetsite Script..." -ForegroundColor Yellow
$jetsiteScript = "d:\repos\Jetsite\fork_template_repo_v2.ps1"

if (Test-Path $jetsiteScript) {
    Write-Host "✅ Jetsite script found: $jetsiteScript" -ForegroundColor Green
    
    # Test help output
    Write-Host "   Testing help output..." -ForegroundColor Gray
    try {
        & $jetsiteScript -h
        Write-Host "✅ Jetsite script help works" -ForegroundColor Green
    } catch {
        Write-Host "❌ Jetsite script error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Jetsite script not found: $jetsiteScript" -ForegroundColor Red
}

Write-Host ""

# Check agent status
Write-Host "📋 Checking Agent Status..." -ForegroundColor Yellow
try {
    $agentStatus = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 5
    Write-Host "✅ Agent is running and healthy" -ForegroundColor Green
    Write-Host "   Status: $($agentStatus.status)" -ForegroundColor Gray
    Write-Host "   Uptime: $([math]::Round($agentStatus.uptime)) seconds" -ForegroundColor Gray
} catch {
    Write-Host "❌ Agent not responding: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please start the agent: node agent.js" -ForegroundColor Yellow
}

Write-Host ""

# Provide solutions
Write-Host "🔧 Common Solutions:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. GitHub Authentication:" -ForegroundColor Yellow
Write-Host "   gh auth login --web" -ForegroundColor White
Write-Host ""
Write-Host "2. Configure Git:" -ForegroundColor Yellow
Write-Host "   git config --global user.name 'Your Name'" -ForegroundColor White
Write-Host "   git config --global user.email 'your.email@example.com'" -ForegroundColor White
Write-Host ""
Write-Host "3. Test Jetsite manually:" -ForegroundColor Yellow
Write-Host "   & '$jetsiteScript' -template 'vitejs/vite-react-ts-starter' -name 'test-project' -visibility 'public' -quiet" -ForegroundColor White
Write-Host ""
Write-Host "4. Start agent with debug:" -ForegroundColor Yellow
Write-Host "   cd d:\repos\Jetsite\agent" -ForegroundColor White
Write-Host "   node agent.js --port 3000" -ForegroundColor White
Write-Host ""

# Test with a simple template that doesn't require auth
Write-Host "🧪 Testing with Public Template..." -ForegroundColor Cyan
$testRepo = @{
    template = "vitejs/vite-react-ts-starter"
    name = "jetsite-test-$(Get-Date -Format 'HHmmss')"
    visibility = "public"
} | ConvertTo-Json

Write-Host "Request: $testRepo" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/create-repository" -Method POST -Body $testRepo -ContentType "application/json" -TimeoutSec 10
    Write-Host "✅ Test request successful!" -ForegroundColor Green
    Write-Host "   Task ID: $($response.taskId)" -ForegroundColor Gray
    
    # Check task status
    Start-Sleep -Seconds 3
    $taskStatus = Invoke-RestMethod -Uri "http://localhost:3000/task/$($response.taskId)" -Method GET
    Write-Host "   Status: $($taskStatus.status)" -ForegroundColor Gray
    if ($taskStatus.error) {
        Write-Host "   Error: $($taskStatus.error)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Test request failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "   HTTP Status: $statusCode" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "1. Fix any authentication issues above" -ForegroundColor White
Write-Host "2. Restart the agent if needed" -ForegroundColor White
Write-Host "3. Try the demo again: .\quick-demo.ps1" -ForegroundColor White
