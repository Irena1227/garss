# GARSS daily paper watchdog (2026-08-28, by Kimi)
# Background: GitHub scheduled workflow missed/delayed two days in a row
# (githubstatus clean, so it is scheduler congestion, not an outage).
# A Windows scheduled task runs this at 06:30 Beijing time:
# if the garss repo has no Actions run today (Beijing date), dispatch one manually.
# Requires: gh CLI logged in as Irena1227. Logs to ensure-daily-paper.log.

$ErrorActionPreference = 'Stop'
$repo = 'Irena1227/garss'
$logPath = Join-Path $PSScriptRoot 'ensure-daily-paper.log'

function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

try {
    # Local machine is Beijing time; today 00:00 local -> UTC cutoff
    $bjTodayStart = Get-Date -Hour 0 -Minute 0 -Second 0
    $utcCutoff = $bjTodayStart.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    $runsJson = gh run list --repo $repo --limit 10 --json createdAt,event 2>&1
    if ($LASTEXITCODE -ne 0) { Log "run list query failed: $runsJson"; exit 1 }

    $runs = $runsJson | ConvertFrom-Json
    $todayRuns = @($runs | Where-Object { $_.createdAt -ge $utcCutoff })

    if ($todayRuns.Count -gt 0) {
        Log "today already has $($todayRuns.Count) run(s) ($($todayRuns[0].event)); no dispatch needed."
        exit 0
    }

    $trigger = gh workflow run main.yml --repo $repo --ref main 2>&1
    if ($LASTEXITCODE -ne 0) { Log "manual dispatch failed: $trigger"; exit 1 }
    Log "no run today; dispatched manually. $trigger"
    exit 0
} catch {
    Log "watchdog exception: $_"
    exit 1
}
