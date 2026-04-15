param(
    [Parameter(Mandatory = $false)]
    [string] $ManifestPath = "..\..\platform\workspaces\workspaces.yaml",

    [Parameter(Mandatory = $false)]
    [string[]] $WorkspaceNames
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-WorkspaceManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $resolvedPath = Resolve-Path -LiteralPath $Path
    $lines = Get-Content -LiteralPath $resolvedPath

    $workspaces = @()
    $current = $null
    $currentListName = $null
    $inGitSection = $false
    $inWorkspacesSection = $false

    foreach ($line in $lines) {
        if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line -match '^workspaces:\s*$') {
            $inWorkspacesSection = $true
            continue
        }

        if ($line -match '^deploymentPipelines:\s*$') {
            if ($null -ne $current) {
                $workspaces += [pscustomobject]$current
                $current = $null
            }

            $inWorkspacesSection = $false
            $currentListName = $null
            $inGitSection = $false
            continue
        }

        if (-not $inWorkspacesSection) {
            continue
        }

        if ($line -match '^  - name: (.+)$') {
            if ($null -ne $current) {
                $workspaces += [pscustomobject]$current
            }

            $current = @{
                name = $matches[1].Trim()
                domain = $null
                environment = $null
                description = $null
                ownerGroup = $null
                adminGroups = @()
                contributorGroups = @()
                viewerGroups = @()
                git = @{
                    provider = $null
                    branch = $null
                    repository = $null
                }
            }

            $currentListName = $null
            $inGitSection = $false
            continue
        }

        if ($null -eq $current) {
            continue
        }

        if ($line -match '^    git:$') {
            $inGitSection = $true
            $currentListName = $null
            continue
        }

        if ($line -match '^    (adminGroups|contributorGroups|viewerGroups):\s*$') {
            $currentListName = $matches[1]
            $inGitSection = $false
            continue
        }

        if ($line -match '^      - (.+)$' -and $null -ne $currentListName) {
            $current[$currentListName] += $matches[1].Trim()
            continue
        }

        if ($line -match '^    domain: (.+)$') {
            $current.domain = $matches[1].Trim()
            $currentListName = $null
            $inGitSection = $false
            continue
        }

        if ($line -match '^    environment: (.+)$') {
            $current.environment = $matches[1].Trim()
            $currentListName = $null
            $inGitSection = $false
            continue
        }

        if ($line -match '^    description: (.+)$') {
            $current.description = $matches[1].Trim()
            $currentListName = $null
            $inGitSection = $false
            continue
        }

        if ($line -match '^    ownerGroup: (.+)$') {
            $current.ownerGroup = $matches[1].Trim()
            $currentListName = $null
            $inGitSection = $false
            continue
        }

        if ($inGitSection -and $line -match '^      provider: (.+)$') {
            $current.git.provider = $matches[1].Trim()
            continue
        }

        if ($inGitSection -and $line -match '^      branch: (.+)$') {
            $current.git.branch = $matches[1].Trim()
            continue
        }

        if ($inGitSection -and $line -match '^      repository: (.+)$') {
            $current.git.repository = $matches[1].Trim()
            continue
        }
    }

    if ($null -ne $current) {
        $workspaces += [pscustomobject]$current
    }

    $workspaces
}

function Resolve-EntraGroupId {
    param(
        [Parameter(Mandatory = $true)]
        [string] $GroupName
    )

    $groupId = az ad group list --filter "displayName eq '$GroupName'" --query "[0].id" -o tsv

    if (-not $groupId) {
        throw "Microsoft Entra group '$GroupName' was not found."
    }

    $groupId
}

function Get-WorkspaceLookup {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InvokeScript
    )

    $workspaceResponse = & $InvokeScript `
        -Method GET `
        -Uri "https://api.fabric.microsoft.com/v1/workspaces"

    $lookup = @{}
    foreach ($workspace in $workspaceResponse.value) {
        $lookup[$workspace.displayName] = $workspace
    }

    $lookup
}

function Get-ExistingAssignments {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InvokeScript,

        [Parameter(Mandatory = $true)]
        [string] $WorkspaceId
    )

    $response = & $InvokeScript `
        -Method GET `
        -Uri "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/roleAssignments"

    if ($response.value) {
        return @($response.value)
    }

    @()
}

function Ensure-WorkspaceRoleAssignment {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InvokeScript,

        [Parameter(Mandatory = $true)]
        [psobject] $Workspace,

        [Parameter(Mandatory = $true)]
        [psobject[]] $ExistingAssignments,

        [Parameter(Mandatory = $true)]
        [string] $GroupName,

        [Parameter(Mandatory = $true)]
        [string] $Role
    )

    $groupId = Resolve-EntraGroupId -GroupName $GroupName
    $existingAssignment = $ExistingAssignments | Where-Object {
        $_.principal.type -eq "Group" -and $_.principal.id -eq $groupId
    } | Select-Object -First 1

    if ($null -eq $existingAssignment) {
        Write-Host "Adding $GroupName as $Role on $($Workspace.displayName)"

        $body = @{
            principal = @{
                id = $groupId
                type = "Group"
            }
            role = $Role
        }

        & $InvokeScript `
            -Method POST `
            -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($Workspace.id)/roleAssignments" `
            -Body $body | Out-Null

        return
    }

    if ($existingAssignment.role -eq $Role) {
        Write-Host "Role already correct for $GroupName on $($Workspace.displayName): $Role"
        return
    }

    Write-Host "Updating $GroupName on $($Workspace.displayName) from $($existingAssignment.role) to $Role"

    $updateBody = @{
        role = $Role
    }

    & $InvokeScript `
        -Method PATCH `
        -Uri "https://api.fabric.microsoft.com/v1/workspaces/$($Workspace.id)/roleAssignments/$($existingAssignment.id)" `
        -Body $updateBody | Out-Null
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$invokeScript = Join-Path $scriptRoot "Invoke-FabricApi.ps1"
$manifestFullPath = if ([System.IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath } else { Join-Path $scriptRoot $ManifestPath }

$workspaceDefinitions = Read-WorkspaceManifest -Path $manifestFullPath

if ($WorkspaceNames -and $WorkspaceNames.Count -gt 0) {
    $workspaceDefinitions = $workspaceDefinitions | Where-Object { $WorkspaceNames -contains $_.name }
}

$workspaceLookup = Get-WorkspaceLookup -InvokeScript $invokeScript

foreach ($workspaceDefinition in $workspaceDefinitions) {
    if (-not $workspaceLookup.ContainsKey($workspaceDefinition.name)) {
        throw "Fabric workspace '$($workspaceDefinition.name)' was not found."
    }

    $workspace = $workspaceLookup[$workspaceDefinition.name]
    $existingAssignments = Get-ExistingAssignments -InvokeScript $invokeScript -WorkspaceId $workspace.id

    foreach ($groupName in $workspaceDefinition.adminGroups) {
        Ensure-WorkspaceRoleAssignment `
            -InvokeScript $invokeScript `
            -Workspace $workspace `
            -ExistingAssignments $existingAssignments `
            -GroupName $groupName `
            -Role "Admin"
    }

    foreach ($groupName in $workspaceDefinition.contributorGroups) {
        Ensure-WorkspaceRoleAssignment `
            -InvokeScript $invokeScript `
            -Workspace $workspace `
            -ExistingAssignments $existingAssignments `
            -GroupName $groupName `
            -Role "Contributor"
    }

    foreach ($groupName in $workspaceDefinition.viewerGroups) {
        Ensure-WorkspaceRoleAssignment `
            -InvokeScript $invokeScript `
            -Workspace $workspace `
            -ExistingAssignments $existingAssignments `
            -GroupName $groupName `
            -Role "Viewer"
    }
}

Write-Host "Workspace role assignment reconciliation complete."

