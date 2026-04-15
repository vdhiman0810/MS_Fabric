param(
    [string] $Prefix = "sg-fabric",
    [string] $MailNicknamePrefix = "sgfabric"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$groups = @(
    "admins",
    "capacity-admins",
    "platform-engineers",
    "data-engineers",
    "bi-developers",
    "consumers",
    "breakglass",
    "automation-sp"
)

foreach ($group in $groups) {
    $displayName = "$Prefix-$group"
    $mailNickname = ($MailNicknamePrefix + ($group -replace "-", "")).ToLower()

    Write-Host "Creating group: $displayName"
    az ad group create `
        --display-name $displayName `
        --mail-nickname $mailNickname | Out-Null
}

Write-Host "Entra security group bootstrap complete."
