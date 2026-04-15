# Target Architecture

## Scenario

Northwind Unified Commerce is the reference learning project used across all phases. The platform supports batch and real-time analytics for retail sales, inventory, suppliers, and store operations.

## Environment Model

- `dev`: engineering and experimentation
- `tst`: integration and pre-release validation
- `prd`: controlled production

## Workspace Strategy

- `ws-npw-platform-{env}`
- `ws-npw-data-{env}`
- `ws-npw-bi-{env}`

In trial, the design may be collapsed to fewer workspaces to fit capacity limits. The enterprise target remains separate workspaces by ownership and lifecycle.

## Architecture Summary

- OneLake medallion layers for bronze, silver, and gold
- Lakehouse for engineering-first storage and transformations
- Warehouse for curated SQL-serving patterns
- Semantic models for governed analytics access
- Reports and dashboards for business consumption
- Eventstream and KQL for near-real-time telemetry
- Deployment pipelines for release promotion
- Git integration for workspace item versioning

## Trial Constraints

- trial capacity is time-limited
- private link is not available in trial
- some advanced enterprise features are limited or unavailable
- production network design must still be documented even if not executable in trial

