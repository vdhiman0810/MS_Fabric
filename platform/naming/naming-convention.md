# Naming Convention

## Prefix

- project prefix: `npw`

## Workspaces

- pattern: `ws-{project}-{domain}-{env}`
- example: `ws-npw-platform-dev`

## Security Groups

- pattern: `sg-fabric-{purpose}`
- example: `sg-fabric-platform-engineers`

## Service Principals

- pattern: `sp-{project}-{purpose}-{env}`
- example: `sp-npw-fabric-cicd-dev`

## Pipelines

- pattern: `dp-{project}-{scope}`
- example: `dp-npw-platform`

## General Rules

- use lowercase and hyphens
- include environment in deployable assets where ambiguity exists
- keep names deterministic so automation can derive them

