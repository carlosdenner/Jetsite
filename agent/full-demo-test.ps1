# ============================================================================
# JETSITE FULL DEMO TEST - Complete End-to-End Workflow
# ============================================================================
# This script demonstrates the complete Jetsite workflow:
# 1. Fork template repo → 2. Setup project → 3. Start dev server → 4. Open in VS Code → 5. Live demo

param(
    [string]$ApiUrl = "http://localhost:3000",
    [string]$Template = "carlosdenner/Jetsite_template",
    [string]$ProjectName = "jetsite-demo-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    [switch]$SkipVSCode = $false
)

Write-Host ""
Write-Host "🚀 JETSITE FULL DEMO TEST" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Template: $Template" -ForegroundColor Yellow
Write-Host "Project:  $ProjectName" -ForegroundColor Yellow
Write-Host "API:      $ApiUrl" -ForegroundColor Yellow
Write-Host ""

# Step 1: Check if agent is running
Write-Host "📡 Step 1: Checking agent status..." -ForegroundColor Green
try {
    $agentStatus = Invoke-RestMethod -Uri "$ApiUrl/health" -Method GET
    Write-Host "✅ Agent is healthy!" -ForegroundColor Green
    Write-Host "   Uptime: $([math]::Round($agentStatus.uptime, 2)) seconds" -ForegroundColor Gray
} catch {
    Write-Host "❌ Agent not responding. Please start the agent first:" -ForegroundColor Red
    Write-Host "   cd d:\repos\Jetsite\agent && node agent.js" -ForegroundColor Yellow
    exit 1
}

# Step 2: Create repository via API
Write-Host ""
Write-Host "🏗️  Step 2: Creating repository from template..." -ForegroundColor Green

$requestBody = @{
    template = $Template
    name = $ProjectName
    visibility = "public"
    noVSCode = $SkipVSCode
    postCommands = @(
        "npm install",
        "npm run dev"
    ) -join "; "
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$ApiUrl/create-repository" -Method POST -Body $requestBody -ContentType "application/json"
    Write-Host "✅ Repository creation queued!" -ForegroundColor Green
    Write-Host "   Task ID: $($createResponse.taskId)" -ForegroundColor Gray
    
    $taskId = $createResponse.taskId
    
} catch {
    Write-Host "❌ Failed to create repository: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Monitor task progress
Write-Host ""
Write-Host "⏳ Step 3: Monitoring task progress..." -ForegroundColor Green

$maxWaitTime = 300  # 5 minutes max
$waitTime = 0
$pollInterval = 5

do {
    Start-Sleep -Seconds $pollInterval
    $waitTime += $pollInterval
    
    try {
        $taskStatus = Invoke-RestMethod -Uri "$ApiUrl/task/$taskId" -Method GET
        
        Write-Host "   Status: $($taskStatus.status) (${waitTime}s elapsed)" -ForegroundColor Yellow
        
        if ($taskStatus.status -eq "completed") {
            Write-Host "✅ Repository created successfully!" -ForegroundColor Green
            $result = $taskStatus.result | ConvertFrom-Json
            $projectPath = $result.workingDirectory
            Write-Host "   Path: $projectPath" -ForegroundColor Gray
            break
        }
        elseif ($taskStatus.status -eq "failed") {
            Write-Host "❌ Task failed: $($taskStatus.error)" -ForegroundColor Red
            exit 1
        }
        
    } catch {
        Write-Host "⚠️  Error checking task status: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
} while ($waitTime -lt $maxWaitTime)

if ($waitTime -ge $maxWaitTime) {
    Write-Host "❌ Task timed out after $maxWaitTime seconds" -ForegroundColor Red
    exit 1
}

# Step 4: Verify project setup
Write-Host ""
Write-Host "🔍 Step 4: Verifying project setup..." -ForegroundColor Green

$expectedPath = "d:\repos\Jetsite\agent\workspace\$ProjectName"
if (Test-Path $expectedPath) {
    Write-Host "✅ Project directory found: $expectedPath" -ForegroundColor Green
    
    # Check key files
    $packageJsonPath = Join-Path $expectedPath "package.json"
    if (Test-Path $packageJsonPath) {
        $packageJson = Get-Content $packageJsonPath | ConvertFrom-Json
        Write-Host "   Project: $($packageJson.name)" -ForegroundColor Gray
        Write-Host "   Version: $($packageJson.version)" -ForegroundColor Gray
        Write-Host "   Scripts: $($packageJson.scripts.PSObject.Properties.Name -join ', ')" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Project directory not found: $expectedPath" -ForegroundColor Red
    exit 1
}

# Step 5: Start development server
Write-Host ""
Write-Host "🌐 Step 5: Starting development server..." -ForegroundColor Green

# Check if there's already a dev server running
$devServerRunning = $false
try {
    $testResponse = Invoke-WebRequest -Uri "http://localhost:5173" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($testResponse.StatusCode -eq 200) {
        $devServerRunning = $true
        Write-Host "✅ Development server already running on http://localhost:5173" -ForegroundColor Green
    }
} catch {
    # Server not running, we'll start it
}

if (-not $devServerRunning) {
    Write-Host "   Starting dev server in background..." -ForegroundColor Yellow
    
    # Start the dev server in background
    $devServerJob = Start-Job -ScriptBlock {
        param($ProjectPath)
        Set-Location $ProjectPath
        npm run dev
    } -ArgumentList $expectedPath
    
    # Wait for server to start
    $serverStarted = $false
    $serverWaitTime = 0
    $maxServerWait = 60
    
    Write-Host "   Waiting for server to start..." -ForegroundColor Yellow
    
    do {
        Start-Sleep -Seconds 2
        $serverWaitTime += 2
        
        try {
            $testResponse = Invoke-WebRequest -Uri "http://localhost:5173" -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($testResponse.StatusCode -eq 200) {
                $serverStarted = $true
                Write-Host "✅ Development server started on http://localhost:5173" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host "   ⏳ Still waiting... (${serverWaitTime}s)" -ForegroundColor Gray
        }
        
    } while ($serverWaitTime -lt $maxServerWait)
    
    if (-not $serverStarted) {
        Write-Host "⚠️  Server didn't start within $maxServerWait seconds" -ForegroundColor Yellow
        Write-Host "   You may need to start it manually: cd '$expectedPath' && npm run dev" -ForegroundColor Gray
    }
}

# Step 6: Open in VS Code with Copilot
if (-not $SkipVSCode) {
    Write-Host ""
    Write-Host "💻 Step 6: Opening in VS Code..." -ForegroundColor Green
    
    try {
        # Open the project in VS Code
        Start-Process "code" -ArgumentList $expectedPath -NoNewWindow
        Write-Host "✅ VS Code opened with project!" -ForegroundColor Green
        Write-Host "   GitHub Copilot should be available for AI-assisted coding" -ForegroundColor Gray
        
        # Create a sample file to demonstrate Copilot
        $sampleFilePath = Join-Path $expectedPath "COPILOT-DEMO.md"
        $sampleContent = @"
# GitHub Copilot Demo

This file was created by Jetsite to demonstrate GitHub Copilot integration.

## Try these Copilot prompts:

1. **Create a React component**: Type \`// Create a button component\` and let Copilot suggest
2. **Add TypeScript types**: Type \`// Define interface for user data\` 
3. **Write tests**: Type \`// Test the button component\`
4. **Add styling**: Type \`// Add CSS styles for the button\`

## Development Commands

\`\`\`bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
\`\`\`

## Live Demo URL
http://localhost:5173

Generated by Jetsite on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
        
        Set-Content -Path $sampleFilePath -Value $sampleContent
        Write-Host "   Created Copilot demo file: COPILOT-DEMO.md" -ForegroundColor Gray
        
    } catch {
        Write-Host "⚠️  Could not open VS Code: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Manually open: code '$expectedPath'" -ForegroundColor Gray
    }
}

# Step 7: Final summary and demo instructions
Write-Host ""
Write-Host "🎉 JETSITE DEMO COMPLETE!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Repository created: $ProjectName" -ForegroundColor Green
Write-Host "✅ Project path: $expectedPath" -ForegroundColor Green
Write-Host "✅ Development server: http://localhost:5173" -ForegroundColor Green
if (-not $SkipVSCode) {
    Write-Host "✅ VS Code opened with GitHub Copilot ready" -ForegroundColor Green
}
Write-Host ""
Write-Host "🚀 WHAT'S NEXT:" -ForegroundColor Cyan
Write-Host "   1. Open your browser: http://localhost:5173" -ForegroundColor White
Write-Host "   2. Edit files in VS Code and see live updates" -ForegroundColor White
Write-Host "   3. Use GitHub Copilot for AI-assisted coding" -ForegroundColor White
Write-Host "   4. Try the suggestions in COPILOT-DEMO.md" -ForegroundColor White
Write-Host ""
Write-Host "🔧 MANUAL COMMANDS (if needed):" -ForegroundColor Yellow
Write-Host "   cd '$expectedPath'" -ForegroundColor Gray
Write-Host "   npm run dev" -ForegroundColor Gray
Write-Host "   code ." -ForegroundColor Gray
Write-Host ""

# Optional: Open browser automatically
$openBrowser = Read-Host "Open browser to http://localhost:5173? (Y/n)"
if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
    try {
        Start-Process "http://localhost:5173"
        Write-Host "✅ Browser opened!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not open browser automatically" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎊 Enjoy your live demo with GitHub Copilot!" -ForegroundColor Magenta
Write-Host ""
