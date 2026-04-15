# GitHub Actions for Fabric Workspace Deployment

## Purpose

This workflow runs the config-driven Fabric workspace deployment from GitHub Actions instead of from a local machine.

Workflow file:

- `.github/workflows/deploy-fabric-workspaces.yml`

## Execution Model

- validate workspace JSON configs on push to `master`
- allow manual `workflow_dispatch` runs
- allow manual deployment for the selected environment folder

## Authentication Model

Preferred approach:

- GitHub Actions OIDC with `azure/login`

Required GitHub secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

## Important Fabric Tenant Dependency

The GitHub Actions identity can only fully create Fabric workspaces if the Fabric tenant setting for service principals to create workspaces, connections, and deployment pipelines is enabled for the approved service principal scope.

Current known tenant state during Phase 1:

- service principals can call Fabric public APIs = `True`
- service principals can create workspaces, connections, and deployment pipelines = `False`

Implication:

- validation in GitHub Actions is fully viable now
- full workspace creation from GitHub Actions may be blocked until tenant settings are updated
- local bootstrap or delegated user execution remains the fallback until the tenant setting is changed

## Recommended Operating Pattern

### Current-state learning mode

- push config changes to GitHub
- let the workflow validate them
- use manual deployment carefully while tenant settings are being finalized

### Target-state enterprise mode

- allow approved service principals to create workspaces
- run full workspace creation and role reconciliation from GitHub Actions
- keep local execution for troubleshooting only

## Example Run Path

1. Edit JSON files under `platform/workspaces/dev/`
2. Push to `master`
3. Validation job runs automatically
4. Trigger manual workflow with `mode=deploy`
5. Workflow runs the same PowerShell deployment scripts used locally

