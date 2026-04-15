param(
    [Parameter(Mandatory = $true)]
    [string] $ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RoleGroupList {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $RolesObject,

        [Parameter(Mandatory = $true)]
        [string] $RoleName
    )

    $property = $RolesObject.PSObject.Properties[$RoleName]

    if ($null -eq $property -or $null -eq $property.Value) {
        return @()
    }

    @($property.Value)
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

function Get-FabricWorkspaceByName {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InvokeScript,

        [Parameter(Mandatory = $true)]
        [string] $WorkspaceName
    )

    $workspaceResponse = & $InvokeScript `
        -Method GET `
        -Uri "https://api.fabric.microsoft.com/v1/workspaces"

    $workspaceResponse.value | Where-Object { $_.displayName -eq $WorkspaceName } | Select-Object -First 1
}

function Ensure-FabricWorkspace {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InvokeScript,

        [Parameter(Mandatory = $true)]
        [pscustomobject] $Config
    )

    $existingWorkspace = Get-FabricWorkspaceByName -InvokeScript $InvokeScript -WorkspaceName $Config.name

    if ($null -ne $existingWorkspace) {
        Write-Host "Workspace already exists, skipping creation: $($Config.name)"
        return $existingWorkspace
    }

    Write-Host "Creating workspace: $($Config.name)"

    $body = @{
        displayName = $Config.name
        description = $Config.description
    }

    try {
        & $InvokeScript `
            -Method POST `
            -Uri "https://api.fabric.microsoft.com/v1/workspaces" `
            -Body $body | Out-Null
    }
    catch {
        $errorText = $_.ToString()

        if ($errorText -match "WorkspaceNameAlreadyExists") {
            Write-Host "Workspace already exists according to Fabric create response, re-querying: $($Config.name)"
        }
        else {
            throw
        }
    }

    $createdWorkspace = Get-FabricWorkspaceByName -InvokeScript $InvokeScript -WorkspaceName $Config.name

    if ($null -eq $createdWorkspace) {
        throw "Workspace '$($Config.name)' exists or was created, but could not be retrieved afterward."
    }

    $createdWorkspace
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
        [ValidateSet("Admin", "Member", "Contributor", "Viewer")]
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
$resolvedConfigPath = Resolve-Path -LiteralPath $ConfigPath
$config = Get-Content -LiteralPath $resolvedConfigPath | ConvertFrom-Json

$workspace = Ensure-FabricWorkspace -InvokeScript $invokeScript -Config $config
$existingAssignments = Get-ExistingAssignments -InvokeScript $invokeScript -WorkspaceId $workspace.id
$adminGroups = Get-RoleGroupList -RolesObject $config.roles -RoleName "Admin"
$memberGroups = Get-RoleGroupList -RolesObject $config.roles -RoleName "Member"
$contributorGroups = Get-RoleGroupList -RolesObject $config.roles -RoleName "Contributor"
$viewerGroups = Get-RoleGroupList -RolesObject $config.roles -RoleName "Viewer"

foreach ($groupName in $adminGroups) {
    Ensure-WorkspaceRoleAssignment `
        -InvokeScript $invokeScript `
        -Workspace $workspace `
        -ExistingAssignments $existingAssignments `
        -GroupName $groupName `
        -Role "Admin"
}

foreach ($groupName in $memberGroups) {
    Ensure-WorkspaceRoleAssignment `
        -InvokeScript $invokeScript `
        -Workspace $workspace `
        -ExistingAssignments $existingAssignments `
        -GroupName $groupName `
        -Role "Member"
}

foreach ($groupName in $contributorGroups) {
    Ensure-WorkspaceRoleAssignment `
        -InvokeScript $invokeScript `
        -Workspace $workspace `
        -ExistingAssignments $existingAssignments `
        -GroupName $groupName `
        -Role "Contributor"
}

foreach ($groupName in $viewerGroups) {
    Ensure-WorkspaceRoleAssignment `
        -InvokeScript $invokeScript `
        -Workspace $workspace `
        -ExistingAssignments $existingAssignments `
        -GroupName $groupName `
        -Role "Viewer"
}

Write-Host "Workspace deployment from config complete: $($config.name)"
