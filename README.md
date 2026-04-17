# Microsoft Fabric Northwind Platform

This repository is the hands-on lab and platform engineering workspace for building an end-to-end Microsoft Fabric solution with an automation-first mindset.

## Phase 1 Scope

Phase 1 establishes the platform foundation:

- Fabric trial and tenant baseline
- identity and access model
- workspace and environment strategy
- Git and CI/CD foundations
- first PowerShell automation for Fabric REST APIs

## Delivery Principles

- `CI/CD first`
- `CLI second`
- `Portal only as the last option`

## Repository Map

- `docs/`: architecture, governance, security, operations
- `platform/`: naming, environments, workspace configs, tenant settings baselines
- `automation/`: PowerShell scripts and REST helpers
- `sample-data/`: source-controlled CSV and JSON data packs for ingestion labs
- `backlog/`: roadmap, risks, and technical debt

## Resume State

To continue this project on another computer, use the repo-native state file:

- `backlog/learning-state.json`

Resume guide:

- `docs/operations/resume-on-new-computer.md`

Helper script for updating progress:

- `automation/powershell/Update-LearningState.ps1`

## Phase 1 Hands-On Flow

1. Complete Fabric trial onboarding in the portal.
2. Create Entra security groups and the automation service principal.
3. Capture current tenant settings into source control.
4. Define environment manifests, workspace naming, and per-workspace JSON configs.
5. Use config-driven deployment for Fabric workspaces and role assignments.
6. Prepare GitHub Actions based automation.

## Default Tenant Domain

Use `varundhiman08outlook.onmicrosoft.com` for tenant-scoped examples and test-user creation unless a later step explicitly says otherwise.

## What Goes In Source Control

- manifests and standards
- automation scripts
- pipeline YAML
- operational decisions
- risks and technical debt

## What Stays Out Of Source Control

- user tokens
- client secrets
- certificate private keys
- ad hoc portal screenshots unless needed for runbooks

## Workspace Deployment Pattern

Workspace deployment is now config-driven:

- one JSON file per workspace under `platform/workspaces/dev/`
- `Deploy-FabricWorkspaceConfig.ps1` deploys one workspace from one config
- `Deploy-FabricWorkspaceConfigs.ps1` deploys the full directory

The scripts create missing workspaces, skip existing workspaces, assign group roles from config, and skip or update role assignments as needed.

## Fallback Scripts

The repo also keeps manual and fallback scripts for learning and troubleshooting:

- `New-FabricWorkspace.ps1` for direct single-workspace creation
- `Set-FabricWorkspaceAccessFromManifest.ps1` for YAML-manifest-based access reconciliation
- `Get-EntraGroupId.ps1` for direct Entra group resolution

The primary path remains JSON workspace configs plus GitHub Actions, but these scripts are intentionally retained as fallback options.

## CI/CD Execution Pattern

Workspace config deployment is designed to run from GitHub Actions through `.github/workflows/deploy-fabric-workspaces.yml`.

- push to `master` validates workspace configs
- manual workflow dispatch can run deployment
- preferred authentication is GitHub OIDC with Azure login
- full non-human workspace creation depends on the Fabric tenant setting that allows service principals to create workspaces
