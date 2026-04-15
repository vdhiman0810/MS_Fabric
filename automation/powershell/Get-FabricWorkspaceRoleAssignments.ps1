param(
    [Parameter(Mandatory = $true)]
    [string] $WorkspaceId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$invokeScript = Join-Path $scriptRoot "Invoke-FabricApi.ps1"

& $invokeScript `
    -Method GET `
    -Uri "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/roleAssignments"

