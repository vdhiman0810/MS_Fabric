param(
    [Parameter(Mandatory = $true)]
    [string] $GroupName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$groupId = az ad group list --filter "displayName eq '$GroupName'" --query "[0].id" -o tsv

if (-not $groupId) {
    throw "Microsoft Entra group '$GroupName' was not found."
}

$groupId

