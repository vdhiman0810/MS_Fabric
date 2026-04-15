Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Phase 1 initialization checklist"
Write-Host "1. Sign in with Azure CLI: az login"
Write-Host "2. Confirm Fabric trial is active in the portal"
Write-Host "3. Confirm your account has Fabric admin or delegated rights as needed"
Write-Host "4. Review platform/workspaces/workspaces.yaml"
Write-Host "5. Run Get-FabricTenantSettings.ps1 to capture the tenant baseline"
Write-Host "6. Run New-FabricWorkspace.ps1 to create the first development workspace"

