Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$invokeScript = Join-Path $scriptRoot "Invoke-FabricApi.ps1"

& $invokeScript `
    -Method GET `
    -Uri "https://api.fabric.microsoft.com/v1/workspaces" |
Select-Object -ExpandProperty value |
Select-Object `
    @{Name = "WorkspaceId"; Expression = { $_.id } },
    @{Name = "Name"; Expression = { $_.displayName } },
    @{Name = "Description"; Expression = { $_.description } },
    @{Name = "Type"; Expression = { $_.type } } |
Format-Table -AutoSize

