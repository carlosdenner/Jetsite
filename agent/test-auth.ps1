# Test GitHub Authentication for Jetsite Agent
Write-Host "Testing GitHub Authentication..." -ForegroundColor Cyan

# Check GitHub CLI auth status
Write-Host "1. GitHub CLI Status:" -ForegroundColor Yellow
try {
    $ghStatus = gh auth status 2>&1
    Write-Host "   $ghStatus" -ForegroundColor Green
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Get GitHub token
Write-Host "`n2. GitHub Token:" -ForegroundColor Yellow
try {
    $token = gh auth token 2>$null
    if ($token) {
        Write-Host "   Token found: $($token.Substring(0,8))..." -ForegroundColor Green
        
        # Set environment variable for the session
        $env:GITHUB_TOKEN = $token
        $env:GH_TOKEN = $token
        
        Write-Host "   Environment variables set" -ForegroundColor Green
    } else {
        Write-Host "   No token found" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test a simple GitHub API call
Write-Host "`n3. Testing GitHub API:" -ForegroundColor Yellow
try {
    $user = gh api user | ConvertFrom-Json
    Write-Host "   Authenticated as: $($user.login)" -ForegroundColor Green
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4. Environment Check:" -ForegroundColor Yellow
Write-Host "   GITHUB_TOKEN: $(if ($env:GITHUB_TOKEN) { 'Set' } else { 'Not set' })" -ForegroundColor $(if ($env:GITHUB_TOKEN) { 'Green' } else { 'Red' })
Write-Host "   GH_TOKEN: $(if ($env:GH_TOKEN) { 'Set' } else { 'Not set' })" -ForegroundColor $(if ($env:GH_TOKEN) { 'Green' } else { 'Red' })

Write-Host "`nRestarting agent with proper environment..." -ForegroundColor Cyan
Write-Host "Please restart the Node.js agent now:" -ForegroundColor Yellow
Write-Host "   Ctrl+C to stop current agent" -ForegroundColor Gray
Write-Host "   cd d:\repos\Jetsite\agent" -ForegroundColor Gray
Write-Host "   `$env:GITHUB_TOKEN = '$($env:GITHUB_TOKEN)'" -ForegroundColor Gray
Write-Host "   node agent.js" -ForegroundColor Gray
