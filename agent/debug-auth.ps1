# Debug script to test PowerShell execution directly
Write-Host "=== DEBUGGING JETSITE SCRIPT EXECUTION ===" -ForegroundColor Cyan

# Test 1: Check environment variables
Write-Host "`n1. Environment Variables:" -ForegroundColor Yellow
Write-Host "   GITHUB_TOKEN: $(if ($env:GITHUB_TOKEN) { 'SET (' + $env:GITHUB_TOKEN.Substring(0,8) + '...)' } else { 'NOT SET' })" -ForegroundColor $(if ($env:GITHUB_TOKEN) { 'Green' } else { 'Red' })
Write-Host "   GH_TOKEN: $(if ($env:GH_TOKEN) { 'SET (' + $env:GH_TOKEN.Substring(0,8) + '...)' } else { 'NOT SET' })" -ForegroundColor $(if ($env:GH_TOKEN) { 'Green' } else { 'Red' })

# Test 2: Get GitHub token from CLI
Write-Host "`n2. GitHub CLI Token:" -ForegroundColor Yellow
try {
    $ghToken = gh auth token 2>$null
    if ($ghToken) {
        Write-Host "   Token from CLI: $($ghToken.Substring(0,8))..." -ForegroundColor Green
        $env:GITHUB_TOKEN = $ghToken
        $env:GH_TOKEN = $ghToken
        Write-Host "   Environment updated" -ForegroundColor Green
    } else {
        Write-Host "   No token from CLI" -ForegroundColor Red
    }
} catch {
    Write-Host "   Error getting token: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Test GitHub API directly
Write-Host "`n3. Direct GitHub API Test:" -ForegroundColor Yellow
try {
    $headers = @{
        'Authorization' = "token $env:GITHUB_TOKEN"
        'User-Agent' = 'jetsite-debug'
    }
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
    Write-Host "   API Success: Authenticated as $($user.login)" -ForegroundColor Green
} catch {
    Write-Host "   API Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test a simple gh command
Write-Host "`n4. GitHub CLI Command Test:" -ForegroundColor Yellow
try {
    $ghUser = gh api user | ConvertFrom-Json
    Write-Host "   CLI Success: $($ghUser.login)" -ForegroundColor Green
} catch {
    Write-Host "   CLI Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Try the actual Jetsite script with help
Write-Host "`n5. Jetsite Script Test:" -ForegroundColor Yellow
$jetsiteScript = "d:\repos\Jetsite\fork_template_repo_v2.ps1"
try {
    & $jetsiteScript -help 2>$null | Out-Null
    Write-Host "   Script help works" -ForegroundColor Green
} catch {
    Write-Host "   Script error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   This might be the issue!" -ForegroundColor Yellow
}

# Test 6: Try to fork a simple repo manually
Write-Host "`n6. Manual Repository Creation Test:" -ForegroundColor Yellow
$testRepoName = "jetsite-debug-test-$(Get-Date -Format 'HHmmss')"
try {
    $result = gh repo create $testRepoName --template octocat/Hello-World --public --clone 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Manual creation SUCCESS: $testRepoName" -ForegroundColor Green
        # Clean up
        Remove-Item -Path $testRepoName -Recurse -Force -ErrorAction SilentlyContinue
        gh repo delete $testRepoName --yes 2>$null
    } else {
        Write-Host "   Manual creation FAILED: $result" -ForegroundColor Red
    }
} catch {
    Write-Host "   Manual creation ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
Write-Host "If manual creation worked but the agent fails," -ForegroundColor White
Write-Host "the issue is in how the agent calls the PowerShell script." -ForegroundColor White
Write-Host ""
