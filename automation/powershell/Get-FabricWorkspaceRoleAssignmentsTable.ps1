param(
    [Parameter(Mandatory = $true)]
    [string] $WorkspaceId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$getAssignmentsScript = Join-Path $scriptRoot "Get-FabricWorkspaceRoleAssignments.ps1"

& $getAssignmentsScript -WorkspaceId $WorkspaceId |
Select-Object -ExpandProperty value |
Select-Object `
    @{Name = "AssignmentId"; Expression = { $_.id } },
    @{Name = "PrincipalName"; Expression = { $_.principal.displayName } },
    @{Name = "PrincipalType"; Expression = { $_.principal.type } },
    @{Name = "PrincipalId"; Expression = { $_.principal.id } },
    @{Name = "Role"; Expression = { $_.role } } |
Format-Table -AutoSize

