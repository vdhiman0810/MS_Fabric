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
- `sg-fabric-automation-sp`

## Service Principal Guidance

- create one dedicated automation application registration
- place its service principal in `sg-fabric-automation-sp`
- allow that group in tenant settings for Fabric APIs and workspace or deployment pipeline creation where supported
- prefer certificate authentication over client secrets for enterprise production

## Break-Glass Guidance

- keep break-glass membership empty during normal operations
- use emergency accounts with strong controls and auditing
- review access regularly

