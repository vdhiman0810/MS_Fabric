param(
    [Parameter(Mandatory = $false)]
    [string] $ConfigDirectory = "..\..\platform\workspaces\dev"
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

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$resolvedDirectory = if ([System.IO.Path]::IsPathRooted($ConfigDirectory)) {
    Resolve-Path -LiteralPath $ConfigDirectory
} elseif (Test-Path -LiteralPath $ConfigDirectory) {
    Resolve-Path -LiteralPath $ConfigDirectory
} else {
    Resolve-Path -LiteralPath (Join-Path $scriptRoot $ConfigDirectory)
}

if (-not (Test-Path $resolvedDirectory)) {
    throw "Workspace config directory not found: $resolvedDirectory"
}

$files = Get-ChildItem -LiteralPath $resolvedDirectory -Filter *.json | Sort-Object Name

if (-not $files) {
    throw "No workspace config files were found in $resolvedDirectory"
}

$allowedRoles = @("Admin", "Member", "Contributor", "Viewer")
$workspaceNames = @()

foreach ($file in $files) {
    Write-Host "Validating $($file.Name)"
    $config = Get-Content -LiteralPath $file.FullName | ConvertFrom-Json

    foreach ($required in @("name", "description", "ownerGroup", "roles")) {
        if (-not $config.PSObject.Properties[$required]) {
            throw "Missing required property '$required' in $($file.Name)"
        }
    }

    if ([string]::IsNullOrWhiteSpace($config.name)) {
        throw "Property 'name' must not be empty in $($file.Name)"
    }

    if ([string]::IsNullOrWhiteSpace($config.description)) {
        throw "Property 'description' must not be empty in $($file.Name)"
    }

    if ([string]::IsNullOrWhiteSpace($config.ownerGroup)) {
        throw "Property 'ownerGroup' must not be empty in $($file.Name)"
    }

    if ($workspaceNames -contains $config.name) {
        throw "Duplicate workspace name '$($config.name)' found across workspace config files."
    }

    $workspaceNames += $config.name

    foreach ($roleProperty in $config.roles.PSObject.Properties.Name) {
        if ($allowedRoles -notcontains $roleProperty) {
            throw "Unsupported role '$roleProperty' in $($file.Name). Allowed roles: $($allowedRoles -join ', ')"
        }
    }

    foreach ($allowedRole in $allowedRoles) {
        $groupList = Get-RoleGroupList -RolesObject $config.roles -RoleName $allowedRole
        $duplicates = $groupList | Group-Object | Where-Object { $_.Count -gt 1 }

        if ($duplicates) {
            $duplicateNames = ($duplicates | Select-Object -ExpandProperty Name) -join ", "
            throw "Duplicate group entries found in role '$allowedRole' for $($file.Name): $duplicateNames"
        }
    }

    $adminGroups = Get-RoleGroupList -RolesObject $config.roles -RoleName "Admin"
    if ($adminGroups.Count -eq 0) {
        throw "At least one Admin group is required in $($file.Name)"
    }

    if ($adminGroups -notcontains $config.ownerGroup) {
        throw "ownerGroup '$($config.ownerGroup)' must also appear in the Admin role list in $($file.Name)"
    }

    if ($config.PSObject.Properties["git"]) {
        if (-not $config.git.PSObject.Properties["provider"] -or [string]::IsNullOrWhiteSpace($config.git.provider)) {
            throw "git.provider must not be empty in $($file.Name)"
        }

        if (-not $config.git.PSObject.Properties["branch"] -or [string]::IsNullOrWhiteSpace($config.git.branch)) {
            throw "git.branch must not be empty in $($file.Name)"
        }

        if (-not $config.git.PSObject.Properties["repository"] -or [string]::IsNullOrWhiteSpace($config.git.repository)) {
            throw "git.repository must not be empty in $($file.Name)"
        }
    }
}

Write-Host "Workspace config validation passed for $($files.Count) file(s)."
