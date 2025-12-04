$found = $false
for ($i = 0; $i -lt 12; $i++) {
    try {
        $r = Invoke-RestMethod -UseBasicParsing -Uri 'https://api.github.com/repos/Meisam84/proj2/pulls?head=Meisam84:feature/schedule-overrides' -Headers @{ 'User-Agent' = 'CI-Checker' }
    } catch {
        $r = @()
    }
    if ($r -and $r.Count -gt 0) {
        $r[0].html_url
        $found = $true
        break
    }
    Start-Sleep -Seconds 5
}
if (-not $found) {
    Write-Output 'PR_NOT_FOUND'
}
