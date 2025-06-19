# Test your personal template repository
Write-Host "Testing carlosdenner/Jetsite_template..." -ForegroundColor Cyan

$testRepo = "jetsite-template-test-$(Get-Date -Format 'HHmmss')"

try {
    Write-Host "Creating repository: $testRepo" -ForegroundColor Yellow
    
    # Test creating from your template
    $result = gh repo create $testRepo --template "carlosdenner/Jetsite_template" --public --clone 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Your template works perfectly!" -ForegroundColor Green
        Write-Host "Repository created: https://github.com/carlosdenner/$testRepo" -ForegroundColor Gray
        
        # Check what's in the template
        if (Test-Path $testRepo) {
            Write-Host "`nTemplate contents:" -ForegroundColor Cyan
            Get-ChildItem $testRepo | Select-Object Name, LastWriteTime | Format-Table -AutoSize
            
            # Clean up
            Set-Location ..
            Remove-Item $testRepo -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Optionally delete the test repo (uncomment if you want auto-cleanup)
        # gh repo delete "carlosdenner/$testRepo" --yes 2>$null
        Write-Host "Test repository kept for inspection: $testRepo" -ForegroundColor Gray
        
    } else {
        Write-Host "FAILED: Template test failed" -ForegroundColor Red
        Write-Host "Error: $result" -ForegroundColor Yellow
        
        if ($result -like "*not a template repository*") {
            Write-Host "`nTo fix this:" -ForegroundColor Cyan
            Write-Host "1. Go to https://github.com/carlosdenner/Jetsite_template/settings" -ForegroundColor White
            Write-Host "2. Check 'Template repository' checkbox" -ForegroundColor White
            Write-Host "3. Save settings" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nNow try the demo: .\quick-demo.ps1" -ForegroundColor Cyan
