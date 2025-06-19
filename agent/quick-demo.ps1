# Quick Jetsite Demo Test
# Usage: .\quick-demo.ps1

$apiUrl = "http://localhost:3000"
$template = "carlosdenner/Jetsite_template"  # Your personal template repository
$projectName = "jetsite-quick-demo-$(Get-Date -Format 'HHmmss')"

Write-Host "Quick Jetsite Demo" -ForegroundColor Cyan
Write-Host "Creating: $projectName from $template"

# Test agent health first
try {
    $health = Invoke-RestMethod -Uri "$apiUrl/health" -Method GET
    Write-Host "OK: Agent is healthy (uptime: $([math]::Round($health.uptime, 1))s)" -ForegroundColor Green
} catch {
    Write-Host "Error: Agent not responding. Please start it with: .\start-agent.ps1" -ForegroundColor Red
    exit 1
}

# Create repository
$body = @{
    template = $template
    name = $projectName
    visibility = "public"
    noVSCode = $false
    postCommands = "echo 'Repository created successfully'"
} | ConvertTo-Json

Write-Host "Sending request..." -ForegroundColor Yellow

try {
    $response = Invoke-RestMethod -Uri "$apiUrl/create-repository" -Method POST -Body $body -ContentType "application/json"
    Write-Host "OK: Task created: $($response.taskId)" -ForegroundColor Green
    
    # Monitor progress
    $maxWait = 60  # 1 minute max
    $waited = 0
    
    do {
        Start-Sleep 3
        $waited += 3
        
        $status = Invoke-RestMethod -Uri "$apiUrl/task/$($response.taskId)" -Method GET
        Write-Host "Status: $($status.status) (${waited}s)" -ForegroundColor Yellow
          if ($status.status -eq "completed") {
            Write-Host "Success: Repository created successfully!" -ForegroundColor Green
            
            # Try to parse result, but handle errors gracefully
            try {
                if ($status.result -and $status.result -ne "@{}" -and $status.result -like "{*}") {
                    $result = $status.result | ConvertFrom-Json
                    Write-Host "Path: $($result.workingDirectory)" -ForegroundColor Gray
                } else {
                    Write-Host "Result: Task completed successfully" -ForegroundColor Gray
                }
            } catch {
                Write-Host "Result: Task completed (details not available)" -ForegroundColor Gray
            }
            
            # Try to open in VS Code
            if (Test-Path $result.workingDirectory) {
                $openVSCode = Read-Host "Open in VS Code? (Y/n)"
                if ($openVSCode -ne 'n' -and $openVSCode -ne 'N') {
                    Start-Process "code" -ArgumentList $result.workingDirectory
                    Write-Host "OK: Opened in VS Code!" -ForegroundColor Green
                }
            }
            break
        }
        elseif ($status.status -eq "failed") {
            Write-Host "Error: Task failed: $($status.error)" -ForegroundColor Red
            break
        }
        
    } while ($waited -lt $maxWait)
    
    if ($waited -ge $maxWait) {
        Write-Host "Warning: Task timed out after $maxWait seconds" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*401*") {
        Write-Host "This is a GitHub authentication issue." -ForegroundColor Yellow
        Write-Host "Please restart the agent with: .\start-agent.ps1" -ForegroundColor Yellow
    }
}
