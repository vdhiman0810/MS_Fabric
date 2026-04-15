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
- `platform/`: naming, environments, workspace manifests, tenant settings baselines
- `automation/`: PowerShell scripts and REST helpers
- `cicd/`: Azure DevOps starter pipeline
- `backlog/`: roadmap, risks, and technical debt

## Phase 1 Hands-On Flow

1. Complete Fabric trial onboarding in the portal.
2. Create Entra security groups and the automation service principal.
3. Capture current tenant settings into source control.
4. Define environment manifests and workspace naming.
5. Create the first Fabric workspace by REST API.
6. Prepare Git integration and deployment pipeline automation.

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
