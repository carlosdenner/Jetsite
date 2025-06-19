#
# Jetsite Agent - PowerShell Implementation
# 
# This PowerShell-based agent provides automation for Jetsite repository creation
# Perfect for Windows environments and PowerShell-first workflows
#
# Author: Jetsite Project
# Version: 1.0
#

param(
    [switch]$Install,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [string]$ConfigFile = "agent-config.json",
    [int]$Port = 3001,
    [string]$WorkDir = ".\workspace",
    [string]$LogLevel = "Info"
)

# ============================================================================
# CONFIGURATION & SETUP
# ============================================================================

$ErrorActionPreference = "Stop"

# Agent configuration
$Script:Config = @{
    Port = $Port
    WorkDir = $WorkDir
    LogLevel = $LogLevel
    PollInterval = 30 # seconds
    MaxConcurrentTasks = 3
    TaskRetentionHours = 24
    JetsiteScript = Join-Path $PSScriptRoot "..\fork_template_repo_v2.ps1"
}

# Task queue and state
$Script:TaskQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
$Script:ActiveTasks = @{}
$Script:CompletedTasks = @{}
$Script:IsRunning = $false

# ============================================================================
# LOGGING SYSTEM
# ============================================================================

function Write-AgentLog {
    param(
        [string]$Message,
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info",
        [string]$TaskId = $null
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = if ($TaskId) { "[$TaskId]" } else { "[AGENT]" }
    $logMessage = "$timestamp [$Level] $prefix $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # File logging
    $logFile = "jetsite-agent-$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path $logFile -Value $logMessage
}

# ============================================================================
# TASK MANAGEMENT
# ============================================================================

class JetsiteTask {
    [string]$Id
    [string]$Template
    [string]$Name
    [string]$Visibility
    [bool]$NoVSCode
    [string]$PostCommands
    [datetime]$CreatedAt
    [datetime]$StartedAt
    [datetime]$CompletedAt
    [string]$Status  # Pending, Running, Completed, Failed
    [string]$Result
    [string]$ErrorMessage
    [hashtable]$Metadata
      JetsiteTask([hashtable]$params) {
        $this.Id = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
        $this.Template = $params.Template
        $this.Name = $params.Name
        $this.Visibility = if ($params.Visibility) { $params.Visibility } else { "public" }
        $this.NoVSCode = if ($params.NoVSCode) { $params.NoVSCode } else { $false }
        $this.PostCommands = $params.PostCommands
        $this.CreatedAt = Get-Date
        $this.Status = "Pending"
        $this.Metadata = if ($params.Metadata) { $params.Metadata } else { @{} }
    }
}

function Add-JetsiteTask {
    param(
        [hashtable]$TaskParams
    )
    
    try {
        $task = [JetsiteTask]::new($TaskParams)
        $Script:TaskQueue.Enqueue($task)
        
        Write-AgentLog "Task queued: $($task.Name) from $($task.Template)" -Level "Info" -TaskId $task.Id
        
        return $task.Id
    } catch {
        Write-AgentLog "Failed to create task: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

function Get-NextTask {
    $task = $null
    if ($Script:TaskQueue.TryDequeue([ref]$task)) {
        return $task
    }
    return $null
}

function Update-TaskStatus {
    param(
        [string]$TaskId,
        [string]$Status,
        [string]$Result = $null,
        [string]$ErrorMessage = $null
    )
    
    if ($Script:ActiveTasks.ContainsKey($TaskId)) {
        $task = $Script:ActiveTasks[$TaskId]
        $task.Status = $Status
        
        if ($Result) { $task.Result = $Result }
        if ($ErrorMessage) { $task.ErrorMessage = $ErrorMessage }
        
        switch ($Status) {
            "Running" { $task.StartedAt = Get-Date }
            "Completed" { 
                $task.CompletedAt = Get-Date
                $Script:CompletedTasks[$TaskId] = $task
                $Script:ActiveTasks.Remove($TaskId)
            }
            "Failed" { 
                $task.CompletedAt = Get-Date
                $Script:CompletedTasks[$TaskId] = $task
                $Script:ActiveTasks.Remove($TaskId)
            }
        }
        
        Write-AgentLog "Task status updated: $Status" -Level "Info" -TaskId $TaskId
    }
}

# ============================================================================
# JETSITE AUTOMATION
# ============================================================================

function Invoke-JetsiteTask {
    param(
        [JetsiteTask]$Task
    )
    
    try {
        Write-AgentLog "Starting task execution" -Level "Info" -TaskId $Task.Id
        
        # Prepare arguments
        $arguments = @(
            "-template", $Task.Template,
            "-name", $Task.Name,
            "-visibility", $Task.Visibility,
            "-quiet"
        )
        
        if ($Task.NoVSCode) {
            $arguments += "-noVSCode"
        }
        
        if ($Task.PostCommands) {
            $arguments += "-postCommands", $Task.PostCommands
        }
        
        # Ensure work directory exists
        $taskWorkDir = Join-Path $Script:Config.WorkDir $Task.Name
        if (-not (Test-Path $Script:Config.WorkDir)) {
            New-Item -Path $Script:Config.WorkDir -ItemType Directory -Force | Out-Null
        }
        
        # Execute Jetsite script
        Write-AgentLog "Executing: $($Script:Config.JetsiteScript) $($arguments -join ' ')" -Level "Debug" -TaskId $Task.Id
        
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-File", $Script:Config.JetsiteScript
        ) + $arguments -WorkingDirectory $Script:Config.WorkDir -PassThru -Wait -NoNewWindow -RedirectStandardOutput "task-$($Task.Id)-stdout.log" -RedirectStandardError "task-$($Task.Id)-stderr.log"
        
        if ($process.ExitCode -eq 0) {
            $result = @{
                Success = $true
                ExitCode = $process.ExitCode
                WorkingDirectory = $taskWorkDir
                RepositoryName = $Task.Name
                CompletedAt = Get-Date
            }
            
            Update-TaskStatus -TaskId $Task.Id -Status "Completed" -Result ($result | ConvertTo-Json)
            Write-AgentLog "Task completed successfully" -Level "Info" -TaskId $Task.Id
            
        } else {
            $errorContent = if (Test-Path "task-$($Task.Id)-stderr.log") {
                Get-Content "task-$($Task.Id)-stderr.log" -Raw            } else {
                "Script exited with code $($process.ExitCode)"
            }
            Update-TaskStatus -TaskId $Task.Id -Status "Failed" -ErrorMessage $errorContent
            Write-AgentLog "Task failed: $errorContent" -Level "Error" -TaskId $Task.Id
        }
        
    } catch {
        $errorMessage = $_.Exception.Message
        Update-TaskStatus -TaskId $Task.Id -Status "Failed" -ErrorMessage $errorMessage
        Write-AgentLog "Task execution error: $errorMessage" -Level "Error" -TaskId $Task.Id
    }
}

# ============================================================================
# TASK PROCESSOR
# ============================================================================

function Start-TaskProcessor {
    Write-AgentLog "Task processor started" -Level "Info"
    
    while ($Script:IsRunning) {
        try {
            # Process next task if we have capacity
            if ($Script:ActiveTasks.Count -lt $Script:Config.MaxConcurrentTasks) {
                $nextTask = Get-NextTask
                
                if ($nextTask) {
                    $Script:ActiveTasks[$nextTask.Id] = $nextTask
                    Update-TaskStatus -TaskId $nextTask.Id -Status "Running"
                      # Start task in background job
                    $job = Start-Job -ScriptBlock {
                        param($TaskData, $ConfigData, $ScriptPath)
                        
                        # Import the main script to get function definitions
                        . $ScriptPath
                        
                        # Set script variables
                        $Script:Config = $ConfigData
                        
                        # Recreate task object
                        $task = [JetsiteTask]::new()
                        $task.Id = $TaskData.Id
                        $task.Template = $TaskData.Template
                        $task.Name = $TaskData.Name
                        $task.Visibility = $TaskData.Visibility
                        $task.NoVSCode = $TaskData.NoVSCode
                        $task.PostCommands = $TaskData.PostCommands
                        $task.Status = $TaskData.Status
                        $task.CreatedAt = $TaskData.CreatedAt
                        $task.StartedAt = $TaskData.StartedAt
                        $task.CompletedAt = $TaskData.CompletedAt
                        $task.Result = $TaskData.Result
                        $task.ErrorMessage = $TaskData.ErrorMessage
                        $task.Metadata = $TaskData.Metadata
                        
                        # Execute task
                        Invoke-JetsiteTask -Task $task
                        
                    } -ArgumentList $nextTask, $Script:Config, $PSCommandPath
                    
                    $nextTask.Metadata["JobId"] = $job.Id
                }
            }
            
            # Check completed jobs
            $completedJobs = Get-Job | Where-Object { $_.State -eq "Completed" -or $_.State -eq "Failed" }
            foreach ($job in $completedJobs) {
                # Find task associated with this job
                $associatedTask = $Script:ActiveTasks.Values | Where-Object { $_.Metadata.JobId -eq $job.Id }
                  if ($associatedTask) {
                    if ($job.State -eq "Failed") {
                        $jobError = Receive-Job -Job $job 2>&1 | Out-String
                        Update-TaskStatus -TaskId $associatedTask.Id -Status "Failed" -ErrorMessage $jobError
                    }
                    # Completed status should already be set by the job itself
                }
                
                Remove-Job -Job $job -Force
            }
            
            # Cleanup old completed tasks
            $cutoffTime = (Get-Date).AddHours(-$Script:Config.TaskRetentionHours)
            $tasksToRemove = $Script:CompletedTasks.Keys | Where-Object {
                $Script:CompletedTasks[$_].CompletedAt -lt $cutoffTime
            }
            
            foreach ($taskId in $tasksToRemove) {
                $Script:CompletedTasks.Remove($taskId)
                Write-AgentLog "Cleaned up old task: $taskId" -Level "Debug"
            }
            
            Start-Sleep -Seconds $Script:Config.PollInterval
            
        } catch {
            Write-AgentLog "Task processor error: $($_.Exception.Message)" -Level "Error"
            Start-Sleep -Seconds 5
        }
    }
    
    Write-AgentLog "Task processor stopped" -Level "Info"
}

# ============================================================================
# WEB API (Simple HTTP Server)
# ============================================================================

function Start-WebAPI {
    Write-AgentLog "Starting web API on port $($Script:Config.Port)" -Level "Info"
    
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://localhost:$($Script:Config.Port)/")
    $listener.Start()
    
    try {
        while ($Script:IsRunning) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            try {
                $path = $request.Url.AbsolutePath
                $method = $request.HttpMethod
                
                Write-AgentLog "API Request: $method $path" -Level "Debug"
                
                # Handle API endpoints
                $responseData = $null
                
                if ($method -eq "GET" -and $path -eq "/health") {
                    $responseData = @{
                        status = "healthy"
                        timestamp = Get-Date -Format "o"
                        uptime = [math]::Round(((Get-Date) - $Script:StartTime).TotalSeconds)
                    }
                }
                elseif ($method -eq "GET" -and $path -eq "/status") {
                    $responseData = @{
                        tasks = @{
                            pending = $Script:TaskQueue.Count
                            active = $Script:ActiveTasks.Count
                            completed = $Script:CompletedTasks.Count
                        }
                        agent = @{
                            running = $Script:IsRunning
                            workDir = $Script:Config.WorkDir
                            maxConcurrent = $Script:Config.MaxConcurrentTasks
                        }
                    }
                }
                elseif ($method -eq "POST" -and $path -eq "/create-repository") {
                    $body = [System.IO.StreamReader]::new($request.InputStream).ReadToEnd()
                    $taskParams = $body | ConvertFrom-Json -AsHashtable
                    
                    if (-not $taskParams.Template -or -not $taskParams.Name) {
                        $response.StatusCode = 400
                        $responseData = @{ error = "Missing required fields: template and name" }
                    } else {
                        $taskId = Add-JetsiteTask -TaskParams $taskParams
                        $responseData = @{
                            taskId = $taskId
                            status = "queued"
                            message = "Repository creation task queued successfully"
                        }
                    }
                }
                elseif ($method -eq "GET" -and $path -match "^/task/(.+)$") {
                    $taskId = $matches[1]
                    $task = $Script:ActiveTasks[$taskId]
                    if (-not $task) {
                        $task = $Script:CompletedTasks[$taskId]
                    }
                    
                    if ($task) {
                        $responseData = @{
                            id = $task.Id
                            template = $task.Template
                            name = $task.Name
                            status = $task.Status
                            createdAt = $task.CreatedAt
                            startedAt = $task.StartedAt
                            completedAt = $task.CompletedAt
                            result = $task.Result
                            error = $task.ErrorMessage
                        }
                    } else {
                        $response.StatusCode = 404
                        $responseData = @{ error = "Task not found" }
                    }
                }
                else {
                    $response.StatusCode = 404
                    $responseData = @{ error = "Endpoint not found" }
                }
                
                # Send response
                $jsonResponse = $responseData | ConvertTo-Json -Depth 10
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                
                $response.ContentType = "application/json"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                
            } catch {
                Write-AgentLog "API Error: $($_.Exception.Message)" -Level "Error"
                $response.StatusCode = 500
                $errorResponse = @{ error = "Internal server error" } | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorResponse)
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            } finally {
                $response.Close()
            }
        }
    } finally {
        $listener.Stop()
        Write-AgentLog "Web API stopped" -Level "Info"
    }
}

# ============================================================================
# AGENT CONTROL FUNCTIONS
# ============================================================================

function Install-JetsiteAgent {
    Write-Host "Install: Installing Jetsite Agent..." -ForegroundColor Cyan
    
    # Create work directory
    if (-not (Test-Path $Script:Config.WorkDir)) {
        New-Item -Path $Script:Config.WorkDir -ItemType Directory -Force | Out-Null
        Write-Host "OK: Work directory created: $($Script:Config.WorkDir)" -ForegroundColor Green
    }
    
    # Create config file
    $configPath = Join-Path $PSScriptRoot $ConfigFile
    $Script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
    Write-Host "OK: Configuration saved: $configPath" -ForegroundColor Green
    
    # Install as Windows Service (optional)
    $installService = Read-Host "Install as Windows Service? (y/N)"
    if ($installService -eq 'y' -or $installService -eq 'Y') {
        # This would require additional service wrapper - placeholder for now
        Write-Host "Warning: Service installation not implemented yet. Run manually with -Start parameter." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Success: Jetsite Agent installation complete!" -ForegroundColor Green
    Write-Host "   Start the agent with: .\jetsite-agent.ps1 -Start" -ForegroundColor Gray
    Write-Host ""
}

function Start-JetsiteAgent {
    Write-Host "Start: Starting Jetsite Agent..." -ForegroundColor Cyan
    
    $Script:IsRunning = $true
    $Script:StartTime = Get-Date
    
    Write-AgentLog "Jetsite Agent starting..." -Level "Info"
    Write-AgentLog "Work directory: $($Script:Config.WorkDir)" -Level "Info"
    Write-AgentLog "API Port: $($Script:Config.Port)" -Level "Info"
    Write-AgentLog "Poll interval: $($Script:Config.PollInterval) seconds" -Level "Info"
      # Start components in background
    $apiJob = Start-Job -ScriptBlock {
        param($ScriptPath, $ConfigData)
        . $ScriptPath
        $Script:Config = $ConfigData
        $Script:IsRunning = $true
        Start-WebAPI
    } -ArgumentList $PSCommandPath, $Script:Config
    
    $processorJob = Start-Job -ScriptBlock {
        param($ScriptPath, $ConfigData)
        . $ScriptPath
        $Script:Config = $ConfigData
        $Script:IsRunning = $true
        Start-TaskProcessor
    } -ArgumentList $PSCommandPath, $Script:Config
    
    Write-Host "OK: Agent started successfully!" -ForegroundColor Green
    Write-Host "   API: http://localhost:$($Script:Config.Port)" -ForegroundColor Gray
    Write-Host "   Logs: jetsite-agent-$(Get-Date -Format 'yyyy-MM-dd').log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the agent" -ForegroundColor Yellow
    
    try {
        # Keep main thread alive
        while ($Script:IsRunning) {
            Start-Sleep -Seconds 1
        }
    } finally {
        # Cleanup
        $Script:IsRunning = $false
        Stop-Job -Job $apiJob, $processorJob -PassThru | Remove-Job -Force
        Write-AgentLog "Agent stopped" -Level "Info"
    }
}

function Stop-JetsiteAgent {
    $Script:IsRunning = $false
    Write-Host "Stop: Stopping Jetsite Agent..." -ForegroundColor Yellow
}

function Get-JetsiteAgentStatus {
    Write-Host ""
    Write-Host "Status: Jetsite Agent Status" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Running: $Script:IsRunning" -ForegroundColor $(if ($Script:IsRunning) { "Green" } else { "Red" })
    Write-Host "Tasks Pending: $($Script:TaskQueue.Count)" -ForegroundColor Yellow
    Write-Host "Tasks Active: $($Script:ActiveTasks.Count)" -ForegroundColor Blue
    Write-Host "Tasks Completed: $($Script:CompletedTasks.Count)" -ForegroundColor Green
    Write-Host "Work Directory: $($Script:Config.WorkDir)" -ForegroundColor Gray
    Write-Host "API Port: $($Script:Config.Port)" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Handle Ctrl+C gracefully
[Console]::TreatControlCAsInput = $false
$null = Register-ObjectEvent -InputObject ([Console]) -EventName CancelKeyPress -Action {
    $Script:IsRunning = $false
}

# Execute based on parameters
switch ($true) {
    $Install { Install-JetsiteAgent }
    $Start { Start-JetsiteAgent }
    $Stop { Stop-JetsiteAgent }
    $Status { Get-JetsiteAgentStatus }
    default {
        Write-Host ""
        Write-Host "Agent: Jetsite Agent - PowerShell Implementation" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "USAGE:" -ForegroundColor Yellow
        Write-Host "   .\jetsite-agent.ps1 -Install    # Install and configure agent" -ForegroundColor White
        Write-Host "   .\jetsite-agent.ps1 -Start      # Start the agent daemon" -ForegroundColor White
        Write-Host "   .\jetsite-agent.ps1 -Stop       # Stop the agent daemon" -ForegroundColor White
        Write-Host "   .\jetsite-agent.ps1 -Status     # Show agent status" -ForegroundColor White
        Write-Host ""
        Write-Host "OPTIONS:" -ForegroundColor Yellow
        Write-Host "   -Port <number>        API port (default: 3001)" -ForegroundColor White
        Write-Host "   -WorkDir <path>       Work directory (default: .\workspace)" -ForegroundColor White
        Write-Host "   -LogLevel <level>     Log level (Debug|Info|Warning|Error)" -ForegroundColor White
        Write-Host ""
        Write-Host "EXAMPLES:" -ForegroundColor Yellow
        Write-Host "   .\jetsite-agent.ps1 -Start -Port 8080 -WorkDir C:\Projects" -ForegroundColor White
        Write-Host ""
    }
}
