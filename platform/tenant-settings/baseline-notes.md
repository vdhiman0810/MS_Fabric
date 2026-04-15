# Tenant Settings Baseline Notes

Record the current tenant baseline after reading it from the Fabric Admin API.

Suggested capture workflow:

1. run `Get-FabricTenantSettings.ps1`
2. save the JSON response to a controlled file outside the repo if it contains sensitive identifiers
3. summarize approved baseline decisions in this repository

Recommended tenant settings to review first:

- who can use Fabric
- who can start trials
- who can create workspaces
- who can connect workspaces to Git
- who can use service principals with Fabric APIs
- who can create workspaces, connections, and deployment pipelines by service principal

