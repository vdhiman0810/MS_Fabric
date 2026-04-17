[CmdletBinding()]
param(
    [string]$StateFilePath = ".\backlog\learning-state.json",
    [string]$LastUpdated = (Get-Date -Format "yyyy-MM-dd"),
    [int]$OverallPercent,
    [string]$CurrentPhase,
    [string]$CurrentPhaseName,
    [int]$CurrentPhasePercent,
    [string]$Status,
    [string[]]$WorkingOn,
    [string[]]$NextSteps
)

$ErrorActionPreference = "Stop"

$resolvedPath = Resolve-Path -LiteralPath $StateFilePath -ErrorAction Stop
$state = Get-Content -LiteralPath $resolvedPath -Raw | ConvertFrom-Json

$state.project.last_updated = $LastUpdated

if ($PSBoundParameters.ContainsKey("OverallPercent")) {
    $state.progress.overall_percent = $OverallPercent
}

if ($PSBoundParameters.ContainsKey("CurrentPhase")) {
    $state.progress.current_phase = $CurrentPhase
}

if ($PSBoundParameters.ContainsKey("CurrentPhaseName")) {
    $state.progress.current_phase_name = $CurrentPhaseName
}

if ($PSBoundParameters.ContainsKey("CurrentPhasePercent")) {
    $state.progress.current_phase_percent = $CurrentPhasePercent
}

if ($PSBoundParameters.ContainsKey("Status")) {
    $state.progress.status = $Status
}

if ($PSBoundParameters.ContainsKey("WorkingOn")) {
    $state.current_state.working_on = @($WorkingOn)
}

if ($PSBoundParameters.ContainsKey("NextSteps")) {
    $state.current_state.next_steps = @($NextSteps)
}

if ($PSBoundParameters.ContainsKey("CurrentPhase")) {
    foreach ($phase in $state.full_roadmap) {
        if ($phase.phase -eq $CurrentPhase) {
            if ($PSBoundParameters.ContainsKey("Status")) {
                $phase.status = $Status
            } elseif ($PSBoundParameters.ContainsKey("CurrentPhasePercent")) {
                if ($CurrentPhasePercent -ge 100) {
                    $phase.status = "completed"
                } elseif ($CurrentPhasePercent -gt 0) {
                    $phase.status = "in_progress"
                }
            }
        }
    }
}

$state | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $resolvedPath -Encoding utf8

Write-Host "Learning state updated:" -ForegroundColor Green
Write-Host "  File: $resolvedPath"
Write-Host "  Date: $($state.project.last_updated)"
Write-Host "  Overall: $($state.progress.overall_percent)%"
Write-Host "  Phase: $($state.progress.current_phase) - $($state.progress.current_phase_name)"
Write-Host "  Phase Progress: $($state.progress.current_phase_percent)%"
Write-Host "  Status: $($state.progress.status)"
