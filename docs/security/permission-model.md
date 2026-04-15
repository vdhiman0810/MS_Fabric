# Permission Model

## Purpose

This document explains the permission model used in the Microsoft Fabric learning platform. The goal is to learn with a powerful bootstrap identity while designing for a production-ready least-privilege model.

## Permission Layers

### Layer 1: Tenant Bootstrap Identity

Example:

- your Global Administrator account

Purpose:

- initial tenant onboarding
- enabling Fabric or verifying access
- creating baseline Entra groups
- setting up automation identities
- reading or changing tenant settings when required

This identity is intentionally powerful, but it should not be the steady-state operating identity for day-to-day platform work.

### Layer 2: Fabric Administrative Control

Example group:

- `sg-fabric-admins`

Purpose:

- tenant-level Fabric administration
- delegated control of approved Fabric settings
- review of governance boundaries

### Layer 3: Capacity Administration

Example group:

- `sg-fabric-capacity-admins`

Purpose:

- capacity monitoring
- workload performance oversight
- scaling and health review

### Layer 4: Platform Engineering

Example group:

- `sg-fabric-platform-engineers`

Purpose:

- workspace lifecycle automation
- deployment pipeline setup
- Git integration administration
- non-tenant-wide platform configuration

### Layer 5: Delivery Roles

Example groups:

- `sg-fabric-data-engineers`
- `sg-fabric-bi-developers`

Purpose:

- build data pipelines, notebooks, lakehouses, models, and reports
- work inside approved workspaces without broad tenant-wide control

### Layer 6: Consumer Access

Example group:

- `sg-fabric-consumers`

Purpose:

- read-only analytics consumption
- governed report and semantic model access

### Layer 7: Emergency Access

Example group:

- `sg-fabric-breakglass`

Purpose:

- controlled emergency access
- incident-only use with auditing and review

### Layer 8: Non-Human Automation

Example group:

- `sg-fabric-automation-approved-sp`

Purpose:

- tenant-level allow-list boundary for approved automation identities
- governance separation between human and non-human identities

Additional scoped groups:

- `sg-fabric-automation-api-readers-sp`
- `sg-fabric-automation-workspace-admin-sp`
- `sg-fabric-automation-deployment-sp`
- `sg-fabric-automation-monitoring-sp`

These narrower groups are used when different service principals need different responsibilities.

## Design Principles

- assign access to groups, not users
- avoid daily use of Global Admin
- separate bootstrap identity from operating identities
- keep tenant-wide permissions rare and explicit
- favor workspace-scoped access for builders
- give consumers read-only access wherever possible

## Learning Versus Production

### Good For Learning

- use a Global Admin account to unblock setup
- create disposable test users for role simulation
- verify how tenant settings affect experience

### Good For Production

- use delegated admin groups
- use least privilege
- create dedicated automation identities
- review role assignments regularly
- avoid shared passwords and direct user grants

## Initial Role Mapping

| Actor | Identity Type | Recommended Scope |
|---|---|---|
| Tenant bootstrap admin | User | temporary tenant-wide setup |
| Fabric admin | Group | tenant Fabric administration |
| Capacity admin | Group | capacity-only operations |
| Platform engineer | Group | workspace and pipeline engineering |
| Data engineer | Group | data workspace contributor roles |
| BI developer | Group | BI workspace contributor roles |
| Consumer | Group | app and report consumption |
| Automation approval | Group | approved non-human identities at the tenant boundary |
| Automation execution | Service principal plus scoped group | specific API, deployment, monitoring, or workspace actions |

## Test User Strategy

For lab exercises, create test users with:

- deterministic names
- unique temporary passwords
- no shared credentials
- optional group assignments after creation

This allows you to safely simulate real permission boundaries without normalizing insecure patterns.
