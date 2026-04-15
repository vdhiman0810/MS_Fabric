param(
    [Parameter(Mandatory = $false)]
    [string] $ConfigDirectory = "..\..\platform\workspaces\dev"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$deployScript = Join-Path $scriptRoot "Deploy-FabricWorkspaceConfig.ps1"
$resolvedDirectory = Resolve-Path -LiteralPath (Join-Path $scriptRoot $ConfigDirectory)

$configFiles = Get-ChildItem -LiteralPath $resolvedDirectory -Filter *.json | Sort-Object Name

if (-not $configFiles) {
    throw "No workspace config files were found in $resolvedDirectory."
}

foreach ($configFile in $configFiles) {
    Write-Host "Processing workspace config: $($configFile.Name)"
    & $deployScript -ConfigPath $configFile.FullName
}

Write-Host "Workspace config deployment batch complete."

