# Direct test of the simple script (bypass agent)
Write-Host "Testing simple script directly..." -ForegroundColor Cyan

$testRepo = "jetsite-direct-test-$(Get-Date -Format 'HHmmss')"

try {
    # Test the simple script directly
    & "d:\repos\Jetsite\fork_template_repo_simple.ps1" -template "octocat/Hello-World" -name $testRepo -visibility "public" -noVSCode -quiet
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Direct script execution worked!" -ForegroundColor Green
        Write-Host "The issue is definitely in the agent's script execution" -ForegroundColor Yellow
        
        # Clean up
        if (Test-Path $testRepo) {
            Set-Location ..
            Remove-Item $testRepo -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Delete the test repo
        gh repo delete "carlosdenner/$testRepo" --yes 2>$null
        
    } else {
        Write-Host "FAILED: Direct script execution failed too" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
