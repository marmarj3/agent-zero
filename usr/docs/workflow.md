# Workflow Reference

Complete five-phase workflow for autonomous overnight development.

---

## Overview

```
Phase 1  →  Planner     clarifies exhaustively → plan + spec → "## PHASE 1 COMPLETE"
Phase 2  →  Reviewer    design discussion + defect correction → "## PHASE 2 COMPLETE"
Phase 3  →  You         review plan + reviewer verdict → approve
Phase 4  →  Developer   implements autonomously overnight
Phase 5  →  You         review delivery report in the morning
```

**Agent 0 never responds to the user between Phase 1 and Phase 3.**
**Agent 0 never skips or reorders phases.**

---

## Phase Trigger Summary

| Event | Agent 0 action |
|-------|----------------|
| User submits requirement | Call planner (Phase 1) |
| Planner asks questions | Relay to user verbatim |
| User answers questions | Relay to planner verbatim |
| Planner sends `## PHASE 1 COMPLETE` | Call reviewer immediately (Phase 2) — NO exceptions |
| Reviewer sends `## PHASE 2 COMPLETE` | Present to user for approval (Phase 3) |
| User approves | Call developer immediately (Phase 4) |
| Developer sends delivery | Present delivery report (Phase 5) |
| Developer sends `ESCALATION REQUIRED` | Relay to user immediately |

---

## Phase 1 — Planning

**Agent**: Planner (`call_subordinate(profile="planner", reset=true)`)
**Input**: User requirement verbatim — nothing else
**Output**: `workdir/plans/[name].md` + `workdir/plans/[name]-spec.md` + `## PHASE 1 COMPLETE` message

### What happens

1. Planner explores codebase — files, line numbers, detected stack, reuse opportunities
2. Sends Analysis Report showing scope as understood
3. **Asks exhaustive clarifying questions** — minimum 3, iterates until ALL P1/P2 resolved
4. Mandatory probes across 13 categories:
   - Exact technology versions
   - Authentication and authorization approach
   - Error handling and failure behavior
   - Deployment target
   - Test framework and coverage expectations
   - All external integrations
   - Data persistence and migration strategy
   - Performance and scalability constraints
   - Security requirements (OWASP relevant items)
   - Configuration and secrets management
   - Logging and monitoring
   - Existing code patterns/conventions to follow
   - CI/CD pipeline expectations
5. Self-check before proceeding: *"Does the developer need to make ANY guess?"* — if YES, ask more questions
6. Researches technology choices using web search before committing to decisions
7. Writes Plan file (user-reviewable): requirements, phases, tasks, acceptance criteria, risks
8. Writes Spec file (developer-facing): file manifest, function signatures, schemas, env vars, tests, dependencies
9. Self-validates both against template checklist
10. Sends `## PHASE 1 COMPLETE` with both file paths — **does NOT tell user to approve yet**

### Why exhaustive clarification matters

The developer agent implements EXACTLY what is in the plan and spec.
If any detail is missing or ambiguous, the developer will fail or produce the wrong result.
The planner's questions are the only opportunity to capture every detail before autonomous overnight execution.

---

## Phase 2 — Review (Reviewer owns this phase entirely)

**Agent**: Reviewer (`call_subordinate(profile="reviewer", reset=true)`)
**Trigger**: Agent 0 receives `## PHASE 1 COMPLETE` from planner
**Input**: Plan file path + Spec file path
**Output**: Approved plan + spec + review report + negotiation summary + `## PHASE 2 COMPLETE` message

**Agent 0 does NOT manage this phase** — the Reviewer calls the Planner directly as subordinates.

### Phase A — Design Discussion (Planner↔Reviewer real-time)

1. Reviewer reads both files completely
2. Lists all significant design decisions to question
3. **Researches each decision using web search** (best practices, CVEs, OWASP, comparisons) before contacting Planner
4. Calls Planner directly: `DESIGN DISCUSSION — Round N`
   - Presents researched position with sources
   - Asks WHY questions about each decision
5. Planner defends with evidence from web search
6. Both debate — stronger evidence wins:
   - Planner stronger → Reviewer accepts, documents
   - Reviewer stronger → Planner accepts, updates plan/spec
   - Equally valid → defer to Planner, document both views
7. Maximum 3 rounds per decision
8. Unresolved after 3 rounds → DESIGN-OPEN-XXX (documented, not blocking)

### Phase B — Defect Correction

1. Reviewer checks Plan: REQ coverage, criteria verifiability, sequencing, error handling, scope gaps
2. Reviewer checks Spec: function signatures, schema consistency, CVEs, env vars, test coverage, OWASP, contracts
3. BLOCKER/MAJOR found → `REVISION REQUEST — Round N` to Planner
4. Planner fixes only listed issues → Reviewer verifies
5. Maximum 5 rounds; unresolved → escalation

### Phase C — Reports

Reviewer saves:
- `workdir/plans/[name]-review.md` — always
- `workdir/plans/[name]-negotiation.md` — if any discussion occurred

Reviewer sends `## PHASE 2 COMPLETE` with verdict to Agent 0.

---

## Phase 3 — User Approval Gate

**Trigger**: Agent 0 receives `## PHASE 2 COMPLETE` from reviewer

**You review**:
1. `workdir/plans/[name].md` — the plan (5-10 min read)
2. `workdir/plans/[name]-review.md` — what the Reviewer found and changed
3. `workdir/plans/[name]-negotiation.md` — full design discussion log (optional)

**You approve** by telling Agent 0: *"Approved, proceed."*

**If you want changes**: describe them — Agent 0 calls Planner again, then Reviewer re-runs

**If ESCALATION REQUIRED**: Agent 0 presents unresolved issues — you decide, then re-run

---

## Phase 4 — Autonomous Overnight Execution

**Agent**: Developer (`call_subordinate(profile="developer", reset=true)`)
**Trigger**: User explicit approval
**Runs**: Fully autonomously — no human intervention expected

The spec file contains every implementation detail. Zero assumptions are acceptable.

### Autonomy Hierarchy (before any escalation)

1. **SOLVE** — fix with engineering knowledge, retry
2. **ADAPT** — equivalent approach satisfying same REQ-XXX
3. **WORKAROUND** — maximum partial solution, mark ⚠️ PARTIAL
4. **SKIP** — document downstream impact, mark ❌, continue
5. **ESCALATE** — only after all 4 steps exhausted

---

## Phase 5 — Morning Review

**You review**: `workdir/plans/[name]-delivery-report.md`

| Decision | Action |
|----------|--------|
| All REQ PASS | Run validation instructions ✅ |
| Minor deviations | Accept or re-run specific task |
| Major gaps | Re-run Developer with revised plan |
| Escalation needed | Address escalation report, re-run |

---

## Design Discussion Example

**Scenario**: Planner chose REST API. An MCP server also exists.

```
Reviewer researches: "MCP vs REST API tradeoffs 2025", official MCP docs
Reviewer calls Planner: DESIGN DISCUSSION — Round 1
  DECISION-001: REST API chosen
  Reviewer: MCP provides [advantages per research — source: official docs]
  Question: Why REST over MCP?

Planner responds:
  REST chosen because MCP server is in beta with [specific limitations]
  Source: [link]

Reviewer: Planner's reasoning stronger → CONFIRMED
Documented in negotiation.md: "REST preferred — MCP in beta per [source]"
```

---

## All Output Files Per Session

| File | Produced by | Always? |
|------|-------------|--------|
| `workdir/plans/[name].md` | Planner | ✅ |
| `workdir/plans/[name]-spec.md` | Planner | ✅ |
| `workdir/plans/[name]-review.md` | Reviewer | ✅ |
| `workdir/plans/[name]-negotiation.md` | Reviewer | If discussion occurred |
| `workdir/plans/[name]-delivery-report.md` | Developer | ✅ after execution |
