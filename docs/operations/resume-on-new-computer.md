# Resume On A New Computer

This guide explains how to continue the Microsoft Fabric learning project on another machine without losing context.

## Goal

Use one source-controlled state file so the next machine knows:

- current progress
- current phase
- completed milestones
- immediate next steps
- key asset names

## Source Of Truth

Open this file first:

- `backlog/learning-state.json`

This file is the project handoff checkpoint.

It includes:

- current progress
- current phase
- next actions
- the full end-to-end phase roadmap through the final production-readiness stage

## Recommended Resume Flow

1. Clone the repository to the preferred path:
   - `C:\Users\varun\OneDrive\Documents\MS_Fabric`
2. Open `backlog/learning-state.json`.
3. Review `README.md`.
4. Review `docs/architecture/fabric-learning-plan.md`.
5. Continue from the `next_steps` section in the state file.
6. If you want to log progress after a session, use:
   - `automation/powershell/Update-LearningState.ps1`

## What To Update After Each Session

Update these fields in `backlog/learning-state.json`:

- `project.last_updated`
- `progress.overall_percent`
- `progress.current_phase`
- `progress.current_phase_percent`
- `current_state.completed`
- `current_state.working_on`
- `current_state.next_steps`

Or use the helper script instead.

Example:

```powershell
.\automation\powershell\Update-LearningState.ps1 `
  -OverallPercent 60 `
  -CurrentPhase "Phase 4" `
  -CurrentPhaseName "Semantic Modeling and Reporting" `
  -CurrentPhasePercent 65 `
  -Status "in_progress" `
  -WorkingOn "Power BI KPI cards","Date slicer" `
  -NextSteps "Finish report layout","Save report","Start RLS design"
```

## What Belongs In Source Control

- learning state
- non-secret runbooks
- platform decisions
- repo-level progress notes

## What Must Not Go In Source Control

- passwords
- PATs
- client secrets
- tokens
- exported credentials

## Practical Tip

If the new computer cannot use the same local path, the repo will still work, but keep the same relative folder structure inside the repository. The state file is intended to preserve learning continuity, not machine-specific secrets.
