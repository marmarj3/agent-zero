---
applyTo: '**'
---

# Overnight Development Workflow — GitHub Copilot

This file is auto-injected into every Copilot session. It describes how the
three-agent overnight development system works.

---

## Agent Roles

| Agent | Invoke | Role |
|-------|--------|------|
| `@overnight-planner` | User-facing parent agent | Clarifies, plans, calls reviewer sub-agent, delivers approved plan |
| `@overnight-reviewer` | Sub-agent (called by planner only) | Researches decisions, checks defects, returns structured verdict |
| `@implementation-executor` | User-facing parent agent | Implements autonomously from approved plan + spec |

---

## Workflow

### Step 1 — Plan (you invoke once)
```
@overnight-planner [your requirement]
```

The planner will:
1. Explore your codebase
2. Send an Analysis Report
3. Ask exhaustive clarifying questions (minimum 3, across 13 categories)
4. Wait for your answers — iterate until all questions are resolved
5. Research all technology decisions using web search
6. Write `/plan/[name].md` (plan) and `/plan/[name]-spec.md` (spec)
7. Autonomously call `@overnight-reviewer` as a sub-agent:
   - Reviewer researches every design decision with web search
   - Reviewer checks for defects (OWASP, CVEs, missing coverage)
   - Returns `APPROVED` or `ISSUES FOUND` verdict
   - If issues found: planner fixes and calls reviewer again (up to 3 rounds)
8. Sends `## PHASE 1 COMPLETE` with both file paths

### Step 2 — Review (5-10 minutes)

Open `/plan/[name].md` and review:
- Requirements list (REQ/SEC/CON identifiers)
- Phase and task breakdown
- Acceptance criteria (must be runnable commands)
- Assumptions and risks
- Reviewer verdict (included in delivery message)

The spec file (`/plan/[name]-spec.md`) is auto-approved with the plan.

### Step 3 — Implement (run before you sleep)
```
@implementation-executor /plan/[name].md /plan/[name]-spec.md
```

The executor will:
1. Read both files completely
2. Install dependencies
3. Implement task by task, testing each before proceeding
4. Apply autonomy hierarchy on failures (SOLVE → ADAPT → WORKAROUND → SKIP → ESCALATE)
5. Save `/plan/[name]-delivery-report.md`

### Step 4 — Review in the morning

Open `/plan/[name]-delivery-report.md`:
- Requirements Satisfaction Matrix (PASS/PARTIAL/FAIL per REQ)
- Deviation Log (every problem and how it was handled)
- Validation commands to verify the implementation

---

## Key Design Decisions

### Why overnight-reviewer is a sub-agent

GitHub Copilot supports autonomous sub-agent invocation (1 level deep).
The planner calls the reviewer sub-agent during planning — no user action needed.
The reviewer researches and returns findings; the planner owns the loop and fixes issues.

**Constraint**: Sub-agents cannot call other sub-agents (1-level limit).
This is why the planner owns the review loop, not the reviewer.

### Why both plan and spec files exist

| File | For | Contains |
|------|-----|----------|
| `/plan/[name].md` | You to review | Requirements, tasks, acceptance criteria, risks |
| `/plan/[name]-spec.md` | Executor to implement | Function signatures, schemas, env vars, test specs, execution order |

---

## Deviation Severity Guide (for morning review)

| Severity | Meaning | Action |
|----------|---------|--------|
| PASS | Requirement fully implemented and tested | None |
| PARTIAL (DEV-XXX ADAPTED) | Implemented differently but requirement met | Review the deviation |
| PARTIAL (DEV-XXX WORKAROUND) | Partially working — some limitations | Decide to accept or re-run |
| FAIL (DEV-XXX SKIPPED) | Not implemented — see impact assessment | Re-run with revised plan |
| ESCALATION REQUIRED | Executor needed a decision it couldn't make | Read escalation report, decide, re-run |

---

## File Naming Convention

```
/plan/[purpose]-[component]-[version].md
```

Examples:
- `/plan/feature-auth-module-1.md`
- `/plan/feature-auth-module-1-spec.md`
- `/plan/feature-auth-module-1-delivery-report.md`
- `/plan/feature-auth-module-2.md` ← after revision
