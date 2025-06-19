#!/usr/bin/env pwsh
# Test script to validate syntax

param(
    [string]$template,
    [string]$name,
    [string]$visibility = "public",
    [switch]$noVSCode,
    [switch]$quiet,
    [string]$postCommands,
    [switch]$h,
    [switch]$help
)

# Enable strict error handling
$ErrorActionPreference = "Stop"

function Write-JetsiteOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$IsError,
        [switch]$IsSuccess,
        [switch]$IsWarning
    )
    
    if ($quiet -and -not $IsError) { return }
    
    if ($IsError) { $Color = "Red" }
    elseif ($IsSuccess) { $Color = "Green" }
    elseif ($IsWarning) { $Color = "Yellow" }
    
    Write-Host $Message -ForegroundColor $Color
}

# Test the function
Write-JetsiteOutput "Test message" -Color "Green"
Write-Host "Syntax test completed successfully"
