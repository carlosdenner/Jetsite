#!/usr/bin/env pwsh
# Test script for Jetsite Agent API

param(
    [Parameter(Mandatory=$false)]
    [string]$Port = "3000",
    
    [Parameter(Mandatory=$false)]
    [string]$Template = "microsoft/vscode-extension-samples",
    
    [Parameter(Mandatory=$false)]
    [string]$Name = "my-test-repo",
    
    [Parameter(Mandatory=$false)]
    [string]$Visibility = "public"
)

$baseUrl = "http://localhost:$Port"

Write-Host ""
Write-Host "🧪 Testing Jetsite Agent API" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "1. Health Check..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$baseUrl/health" -Method GET -ContentType "application/json"
    Write-Host "   ✅ Health: $($healthResponse.status)" -ForegroundColor Green
    Write-Host "   ⏰ Uptime: $($healthResponse.uptime) seconds" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   💡 Make sure the agent is running: node agent.js --port $Port" -ForegroundColor Yellow
    exit 1
}

# Test 2: Status Check
Write-Host ""
Write-Host "2. Status Check..." -ForegroundColor Yellow
try {
    $statusResponse = Invoke-RestMethod -Uri "$baseUrl/status" -Method GET -ContentType "application/json"
    Write-Host "   📊 Tasks Pending: $($statusResponse.tasks.pending)" -ForegroundColor Blue
    Write-Host "   🔄 Tasks Active: $($statusResponse.tasks.active)" -ForegroundColor Blue
    Write-Host "   ✅ Tasks Completed: $($statusResponse.tasks.completed)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Status check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Create Repository Task
Write-Host ""
Write-Host "3. Creating Repository Task..." -ForegroundColor Yellow
Write-Host "   Template: $Template" -ForegroundColor Gray
Write-Host "   Name: $Name" -ForegroundColor Gray
Write-Host "   Visibility: $Visibility" -ForegroundColor Gray

$taskData = @{
    template = $Template
    name = $Name
    visibility = $Visibility
    noVSCode = $false
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/create-repository" -Method POST -Body $taskData -ContentType "application/json"
    $taskId = $createResponse.taskId
    
    Write-Host "   ✅ Task Created!" -ForegroundColor Green
    Write-Host "   🆔 Task ID: $taskId" -ForegroundColor Cyan
    Write-Host "   📝 Status: $($createResponse.status)" -ForegroundColor Blue
    
    # Test 4: Monitor Task Progress
    Write-Host ""
    Write-Host "4. Monitoring Task Progress..." -ForegroundColor Yellow
    
    $maxAttempts = 30
    $attempts = 0
    
    do {
        Start-Sleep -Seconds 2
        $attempts++
        
        try {
            $taskResponse = Invoke-RestMethod -Uri "$baseUrl/task/$taskId" -Method GET -ContentType "application/json"
            $status = $taskResponse.status
            
            Write-Host "   [$attempts/$maxAttempts] Status: $status" -ForegroundColor $(
                switch ($status) {
                    "queued" { "Yellow" }
                    "running" { "Blue" }
                    "completed" { "Green" }
                    "failed" { "Red" }
                    default { "Gray" }
                }
            )
            
            if ($status -eq "completed") {
                Write-Host ""
                Write-Host "🎉 Repository Created Successfully!" -ForegroundColor Green
                Write-Host "   📂 Repository: $($taskResponse.name)" -ForegroundColor Cyan
                if ($taskResponse.result) {
                    $result = $taskResponse.result | ConvertFrom-Json
                    Write-Host "   🔗 Directory: $($result.workingDirectory)" -ForegroundColor Gray
                }
                break
            } elseif ($status -eq "failed") {
                Write-Host ""
                Write-Host "❌ Repository Creation Failed!" -ForegroundColor Red
                Write-Host "   Error: $($taskResponse.error)" -ForegroundColor Red
                break
            }
            
        } catch {
            Write-Host "   ⚠️  Task check failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
    } while ($attempts -lt $maxAttempts -and $status -ne "completed" -and $status -ne "failed")
    
    if ($attempts -ge $maxAttempts) {
        Write-Host ""
        Write-Host "⏰ Timeout waiting for task completion" -ForegroundColor Yellow
        Write-Host "   Check task status manually: GET $baseUrl/task/$taskId" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "   ❌ Task creation failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Response: $responseBody" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🏁 Test Complete!" -ForegroundColor Cyan
Write-Host ""
