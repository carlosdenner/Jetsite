# Test the Jetsite Agent API
$apiUrl = "http://localhost:3000"

# Check status
Write-Host "=== Agent Status ===" -ForegroundColor Cyan
$status = Invoke-RestMethod -Uri "$apiUrl/status" -Method GET
$status | ConvertTo-Json -Depth 3

# Create a repository
Write-Host "`n=== Creating Repository ===" -ForegroundColor Cyan
$requestBody = @{
    template = "microsoft/vscode-extension-samples"
    name = "my-test-extension-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    visibility = "public"
    noVSCode = $false
    postCommands = "npm install"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$apiUrl/create-repository" -Method POST -Body $requestBody -ContentType "application/json"
    Write-Host "Task created successfully!" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
    
    # Check task status
    Start-Sleep -Seconds 2
    Write-Host "`n=== Task Status ===" -ForegroundColor Cyan
    $taskStatus = Invoke-RestMethod -Uri "$apiUrl/task/$($response.taskId)" -Method GET
    $taskStatus | ConvertTo-Json -Depth 3
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
