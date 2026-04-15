param(
    [Parameter(Mandatory = $true)]
    [string] $DisplayName,

    [Parameter(Mandatory = $false)]
    [string] $Description = "Created by automation"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$invokeScript = Join-Path $scriptRoot "Invoke-FabricApi.ps1"

$body = @{
    displayName = $DisplayName
    description = $Description
}

& $invokeScript `
    -Method POST `
    -Uri "https://api.fabric.microsoft.com/v1/workspaces" `
    -Body $body

