# Autonomous Development System — Documentation

## What This Is

A fully autonomous, plan-driven software development pipeline built on Agent Zero.
You describe what to build. The system plans, reviews, debates, and implements it.
You review the plan before execution and the delivery report in the morning.

---

## Quick Start

### 1. Give a requirement
```
Build a REST API for user authentication using FastAPI and PostgreSQL with JWT and a Dockerfile.
```

### 2. Planner asks clarifying questions — answer them

### 3. Review the plan (5–10 min)
- Plan file: `workdir/plans/[name].md`
- Reviewer verdict: `workdir/plans/[name]-review.md`
- Design discussion log: `workdir/plans/[name]-negotiation.md` (optional)

### 4. Approve
```
Approved, proceed.
```

### 5. Wake up to the delivery report
- `workdir/plans/[name]-delivery-report.md`

---

## System File Locations

| Component | Location |
|-----------|----------|
| Orchestration prompt | `usr/prompts/agent.system.devworkflow.md` |
| Planner agent | `usr/agents/planner/` |
| Reviewer agent | `usr/agents/reviewer/` |
| Developer agent | `usr/agents/developer/` |
| Plans and reports | `usr/workdir/plans/` |
| Documentation | `usr/docs/` |
| Project code | `usr/projects/<name>/code/` |

---

## Documentation Index

| File | Contents |
|------|----------|
| `README.md` | This file — overview and quick start |
| `architecture.md` | Agent roles, data flow, memory architecture |
| `agents.md` | Full agent reference — modes, protocols, templates |
| `workflow.md` | Complete 5-phase workflow with examples |
| `file-conventions.md` | Output files, naming, all identifier prefixes |
| `memory-and-projects.md` | Project setup, memory scoping, clearing bad memories |
| `troubleshooting.md` | Common problems with exact fixes |
