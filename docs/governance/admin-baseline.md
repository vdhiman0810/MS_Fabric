# Administration Baseline

## Phase 1 Objectives

- enable Fabric for the tenant or verify it is already enabled
- confirm who can start trials
- verify who can create workspaces, connect to Git, and use service principals
- define the delegated administration model

## Tenant Settings Approach

Treat tenant settings as governance controls, not primary security boundaries. They are useful to shape platform behavior, but access must still be controlled through Entra groups, workspace roles, and data security.

## Delegated Model

- Fabric admins own tenant-wide controls
- capacity admins own performance and usage guardrails
- platform engineers own automation and workspace lifecycle
- data product teams own assets inside approved workspaces

## Baseline Decisions To Record

- trial expiration date
- allowed Git providers
- allowed service principal groups
- workspace creation policy
- domain ownership model
- audit and monitoring baseline

