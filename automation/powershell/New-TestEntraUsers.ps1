param(
    [Parameter(Mandatory = $true)]
    [string] $Domain,

    [Parameter(Mandatory = $false)]
    [string] $Prefix = "fabriclab",

    [Parameter(Mandatory = $false)]
    [int] $Count = 5,

    [Parameter(Mandatory = $false)]
    [string] $DisplayNamePrefix = "Fabric Lab User",

    [Parameter(Mandatory = $false)]
    [int] $StartIndex = 1,

    [Parameter(Mandatory = $false)]
    [string] $OutputCsvPath = ".\test-users-created.csv",

    [Parameter(Mandatory = $false)]
    [switch] $ForceChangePasswordNextSignIn,

    [Parameter(Mandatory = $false)]
    [string[]] $TargetGroups = @(
        "sg-fabric-admins",
        "sg-fabric-capacity-admins",
        "sg-fabric-platform-engineers",
        "sg-fabric-data-engineers",
        "sg-fabric-bi-developers",
        "sg-fabric-consumers",
        "sg-fabric-breakglass"
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-RandomPassword {
    param(
        [int] $Length = 18
    )

    $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    $lower = "abcdefghijkmnopqrstuvwxyz"
    $digits = "23456789"
    $special = "!@$%*?-_"
    $all = ($upper + $lower + $digits + $special).ToCharArray()

    $passwordChars = @()
    $passwordChars += $upper[(Get-Random -Minimum 0 -Maximum $upper.Length)]
    $passwordChars += $lower[(Get-Random -Minimum 0 -Maximum $lower.Length)]
    $passwordChars += $digits[(Get-Random -Minimum 0 -Maximum $digits.Length)]
    $passwordChars += $special[(Get-Random -Minimum 0 -Maximum $special.Length)]

    for ($i = $passwordChars.Count; $i -lt $Length; $i++) {
        $passwordChars += $all[(Get-Random -Minimum 0 -Maximum $all.Length)]
    }

    -join ($passwordChars | Sort-Object { Get-Random })
}

if ($Count -lt 1) {
    throw "Count must be at least 1."
}

if ($StartIndex -lt 1) {
    throw "StartIndex must be at least 1."
}

$createdUsers = @()
$groupLookup = @{}

foreach ($groupName in $TargetGroups) {
    $groupId = az ad group list --filter "displayName eq '$groupName'" --query "[0].id" -o tsv

    if (-not $groupId) {
        Write-Warning "Group '$groupName' was not found. Membership assignment for this group will be skipped."
        continue
    }

    $groupLookup[$groupName] = $groupId
}

for ($offset = 0; $offset -lt $Count; $offset++) {
    $i = $StartIndex + $offset
    $suffix = "{0:D2}" -f $i
    $userName = "$Prefix$suffix"
    $upn = "$userName@$Domain"
    $displayName = "$DisplayNamePrefix $suffix"
    $mailNickname = $userName.ToLower()
    $password = $null
    $existingUserId = az ad user list --filter "userPrincipalName eq '$upn'" --query "[0].id" -o tsv

    if ($existingUserId) {
        Write-Host "User already exists, skipping creation: $upn"
        $userId = $existingUserId
        $password = "[existing-user-password-not-reset]"
    }
    else {
        $password = New-RandomPassword

        Write-Host "Creating test user: $upn"

        az ad user create `
            --display-name $displayName `
            --password $password `
            --user-principal-name $upn `
            --mail-nickname $mailNickname `
            --force-change-password-next-sign-in $ForceChangePasswordNextSignIn.IsPresent `
            --output none

        $userId = az ad user list --filter "userPrincipalName eq '$upn'" --query "[0].id" -o tsv
    }

    $assignedGroup = $null
    if ($groupLookup.Count -gt 0) {
        $assignedGroup = $TargetGroups[($i - 1) % $TargetGroups.Count]
        $assignedGroupId = $groupLookup[$assignedGroup]

        if ($assignedGroupId) {
            $isMember = az ad group member check `
                --group $assignedGroupId `
                --member-id $userId `
                --query value `
                -o tsv 2>$null

            if ($isMember -eq "true") {
                Write-Host "User is already a member of $assignedGroup, skipping membership add: $upn"
            }
            else {
                Write-Host "Adding $upn to $assignedGroup"
                az ad group member add --group $assignedGroupId --member-id $userId
            }
        }
    }

    $createdUsers += [pscustomobject]@{
        DisplayName = $displayName
        UserPrincipalName = $upn
        TemporaryPassword = $password
        ForceChangePasswordNextSignIn = $ForceChangePasswordNextSignIn.IsPresent
        AssignedGroup = $assignedGroup
    }
}

$outputDirectory = Split-Path -Parent $OutputCsvPath
if ($outputDirectory -and -not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$createdUsers | Export-Csv -NoTypeInformation -Path $OutputCsvPath

Write-Host "Created $Count test users."
Write-Host "Credentials exported to $OutputCsvPath"
Write-Host "Testing only: protect this CSV and delete it after the lab."
