# Identity Model

## Principles

- use Microsoft Entra groups, not direct user grants
- enforce least privilege
- separate tenant admins, platform engineers, developers, and consumers
- reserve direct assignment for break-glass only

## Recommended Groups

- `sg-fabric-admins`
- `sg-fabric-capacity-admins`
- `sg-fabric-platform-engineers`
- `sg-fabric-data-engineers`
- `sg-fabric-bi-developers`
- `sg-fabric-consumers`
- `sg-fabric-breakglass`
- `sg-fabric-automation-approved-sp`
- `sg-fabric-automation-api-readers-sp`
- `sg-fabric-automation-workspace-admin-sp`
- `sg-fabric-automation-deployment-sp`
- `sg-fabric-automation-monitoring-sp`

## Service Principal Guidance

- create one dedicated automation application registration
- place service principals into purpose-specific groups instead of one catch-all bucket
- use `sg-fabric-automation-approved-sp` as the tenant-level allow-list boundary for approved automation identities
- use narrower groups for specific automation scopes such as API read, workspace lifecycle, deployments, and monitoring
- prefer certificate authentication over client secrets for enterprise production

## Break-Glass Guidance

- keep break-glass membership empty during normal operations
- use emergency accounts with strong controls and auditing
- review access regularly
