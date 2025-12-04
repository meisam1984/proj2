# Poll GitHub for PR and monitor workflow runs for the branch
$owner = 'Meisam84'
$repo = 'proj2'
$branch = 'feature/schedule-overrides'
$headers = @{ 'User-Agent' = 'CI-Monitor' }
$pr = $null
$maxPolls = 120  # 120 * 5s = 600s = 10 minutes
for ($i = 0; $i -lt $maxPolls; $i++) {
    try {
        $url = "https://api.github.com/repos/${owner}/${repo}/pulls?head=${owner}:${branch}"
        $prs = Invoke-RestMethod -UseBasicParsing -Uri $url -Headers $headers
    } catch {
        $prs = @()
    }
    if ($prs -and $prs.Count -gt 0) {
        $pr = $prs[0]
        Write-Output "PR_FOUND $($pr.html_url)"
        break
    }
    Start-Sleep -Seconds 5
}
if (-not $pr) {
    Write-Output 'PR_NOT_FOUND'
    exit 0
}
# Monitor workflow runs for the branch
Write-Output "Monitoring workflow runs for branch $branch..."
$maxRunPolls = 240  # poll for runs for up to 60 minutes (240 * 15s)
for ($j = 0; $j -lt $maxRunPolls; $j++) {
    try {
        $runsResp = Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/$owner/$repo/actions/runs?branch=$branch" -Headers $headers
    } catch {
        $runsResp = $null
    }
    if ($runsResp -and $runsResp.workflow_runs -and $runsResp.workflow_runs.Count -gt 0) {
        foreach ($run in $runsResp.workflow_runs) {
            $status = $run.status
            $conclusion = $run.conclusion
            Write-Output "Run: $($run.name) - ID:$($run.id) - status:$status - conclusion:$conclusion - url:$($run.html_url)"
        }
        # find most recent in progress or completed
        $active = $runsResp.workflow_runs | Where-Object { $_.status -ne 'completed' } | Sort-Object created_at -Descending
        if ($active.Count -gt 0) {
            Write-Output "There is an active run: $($active[0].id) (status: $($active[0].status))"
        } else {
            # No active runs; check latest run conclusion
            $latest = $runsResp.workflow_runs | Sort-Object created_at -Descending | Select-Object -First 1
            if ($latest) {
                Write-Output "Latest run completed: ID:$($latest.id) conclusion:$($latest.conclusion) url:$($latest.html_url)"
                if ($latest.conclusion -eq 'success') {
                    Write-Output 'CI_SUCCESS'
                    exit 0
                } else {
                    Write-Output 'CI_FAILED'
                    exit 2
                }
            }
        }
    } else {
        Write-Output 'No workflow runs yet for this branch.'
    }
    Start-Sleep -Seconds 15
}
Write-Output 'TIMED_OUT_MONITORING'
exit 3
