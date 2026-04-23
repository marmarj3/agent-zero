# Workflow Reference

Complete five-phase workflow for autonomous overnight development.

---

## Overview

```
Phase 1  →  Planner          clarifies → plan + spec
Phase 2  →  Reviewer         design discussion + defect correction → approved plan
Phase 3  →  You              review plan + reviewer verdict → approve
Phase 4  →  Developer        implements autonomously overnight
Phase 5  →  You              review delivery report in the morning
```

---

## Phase 1 — Planning

**Agent**: Planner (`call_subordinate(profile="planner")`)
**Input**: User requirement
**Output**: `workdir/plans/[name].md` + `workdir/plans/[name]-spec.md`

### What happens

1. Planner explores codebase — files, line numbers, detected stack, reuse opportunities
2. Sends Analysis Report showing scope as understood
3. Asks ≥3 clarifying questions (P1/P2 block until answered; P3 → ASSUMPTION-XXX)
4. Researches technology choices using web search before committing to decisions
5. Writes Plan file (user-reviewable): requirements, phases, tasks, acceptance criteria, risks
6. Writes Spec file (developer-facing): file manifest, function signatures, schemas, env vars, tests, dependencies
7. Self-validates both against template checklist
8. Delivers with executive summary and phase table

### Outputs

| File | Contents | Audience |
|------|----------|----------|
| `[name].md` | Requirements, phases, tasks, acceptance criteria, risks | You |
| `[name]-spec.md` | File manifest, function signatures, schemas, env vars, test specs | Developer |

---

## Phase 2 — Review (Reviewer owns this phase entirely)

**Agent**: Reviewer (`call_subordinate(profile="reviewer")`)
**Input**: Plan file path + Spec file path
**Output**: Approved plan + spec + review report + negotiation summary

### Phase A — Design Discussion

Before checking for defects, the Reviewer validates every significant design decision:

1. Reviewer reads both files completely
2. Lists all significant design decisions:
   - Integration strategy (API vs CLI vs SDK vs MCP vs webhook)
   - Technology and library choices
   - Architecture patterns
   - Security approach
   - Data model decisions
   - Dependency choices
   - Configuration approach
3. For each decision: **researches using web search** (best practices, CVEs, OWASP, comparisons) before contacting Planner
4. Calls Planner directly with `DESIGN DISCUSSION — Round N`
5. Both agents discuss with evidence — each cites sources
6. Resolution per decision:
   - Planner's reasoning stronger → Reviewer accepts, documents
   - Reviewer's evidence stronger → Planner accepts, updates plan/spec
   - Equally valid → defer to Planner (full context), document both views
7. Maximum 3 rounds per individual decision
8. Unresolved after 3 rounds → DESIGN-OPEN-XXX (documented, not blocking)

### Phase B — Defect Correction

After all design decisions settled:

1. Reviewer checks Plan for: REQ coverage, acceptance criteria quality, phase sequencing, error handling, assumption/risk alignment, scope gaps
2. Reviewer checks Spec for: function signatures, schema consistency, dependency CVEs, env vars, test coverage, OWASP compliance, integration contracts
3. BLOCKER/MAJOR found → calls Planner with `REVISION REQUEST — Round N`
4. Planner fixes only listed issues, responds with Revision Report
5. Reviewer re-reads and verifies
6. Maximum 5 rounds; unresolved → escalation

### Phase C — Reports

Reviewer saves:
- `workdir/plans/[name]-review.md` — always (design decisions + defect log + statistics)
- `workdir/plans/[name]-negotiation.md` — if any discussion occurred (full round-by-round log)

### Reviewer returns to Agent 0 with one of:

| Verdict | Meaning |
|---------|----------|
| ✅ APPROVED — Design reviewed and defects resolved | Both phases complete, all resolved |
| ✅ APPROVED — No issues found | No BLOCKER/MAJOR, design decisions confirmed with research |
| ⛔ ESCALATION REQUIRED | Unresolved after maximum rounds — user decision needed |

---

## Phase 3 — User Approval Gate

**You review**:
1. `workdir/plans/[name].md` — the plan (5-10 min read)
2. `workdir/plans/[name]-review.md` — what the Reviewer found and changed
3. `workdir/plans/[name]-negotiation.md` — full design discussion log (optional deep-dive)

**You approve** by telling Agent 0: *"Approved, proceed"*

**If you want changes**: describe them — Agent 0 calls Planner again (new revision round)

**Auto-approved with plan**: Spec file — you only need to read it if you want to inspect implementation details

---

## Phase 4 — Autonomous Overnight Execution

**Agent**: Developer (`call_subordinate(profile="developer")`)
**Input**: Plan file path + Spec file path
**Runs**: Fully autonomously — no human intervention expected

### Execution loop (per task)

1. Read task from plan + implementation details from spec
2. Implement component
3. Test component
4. If passes: mark ✅ in plan, send Task Completion Report
5. If fails: apply Autonomy Hierarchy before any escalation:
   - **SOLVE**: fix with engineering knowledge, retry
   - **ADAPT**: equivalent approach satisfying same REQ-XXX
   - **WORKAROUND**: maximum partial solution, mark ⚠️ PARTIAL
   - **SKIP**: document downstream impact, mark ❌, continue
   - **ESCALATE**: only after all 4 steps exhausted — with full documentation
6. Record every problem as DEV-XXX in deviation log (even if self-resolved)
7. Proceed to next task

### Parallel execution

Tasks marked `can_parallel_with` in the spec are spawned as concurrent subordinates.

---

## Phase 5 — Morning Review

**You review**: `workdir/plans/[name]-delivery-report.md`

Report contains:
- **Requirements Satisfaction Matrix**: every REQ-XXX → PASS / PARTIAL / FAIL
- **Deviation Log**: every DEV-XXX with root cause, action taken, outcome
- **Recommended Actions**: what to do about each unsatisfied requirement
- **Validation Instructions**: exact commands to verify the solution works

### Decision tree

```
All REQ PASS?
  Yes → Run validation instructions, done ✅
  No  → Read recommended actions
          Minor deviations?  → Accept or re-run specific task
          Major gaps?        → Re-run Developer with revised plan
          Escalation needed? → Address escalation report, re-run
```

---

## Revision Cycle

If you want to revise the plan after seeing the reviewer's output:

```
You: "Change [X] in the plan"
Agent 0 → Planner (revision round)
Agent 0 → Reviewer (re-reviews the revision)
Agent 0 → You: updated plan + updated review
You: approve
```

Version counter increments: `[name]-1.md` → `[name]-2.md`

---

## Design Discussion Example

**Scenario**: Planner chose REST API integration. An MCP server also exists.

```
Reviewer researches:
  - "MCP vs REST API integration tradeoffs 2024"
  - "[tool name] MCP server production readiness"
  - Official MCP documentation

Reviewer calls Planner:
  DESIGN DISCUSSION — Round 1
  DECISION-001: REST API integration chosen
  Reviewer position: MCP provides [advantages from research — source: official docs]
  Question: Why REST API over MCP? MCP appears more suitable for [reasons].

Planner responds:
  DECISION-001: REST API chosen because [specific reasons]
  Research: [sources] show MCP server for this tool is in beta with [specific limitations]
  Evidence: [link/reference]

Reviewer evaluates:
  Planner's reasoning stronger → CONFIRMED
  Documented: "REST API preferred over MCP — MCP server in beta per [source]"

Result: decision documented in negotiation.md, plan unchanged, no issue raised
```

---

## All Output Files Per Session

| File | Produced by | Always? |
|------|-------------|--------|
| `workdir/plans/[name].md` | Planner | ✅ |
| `workdir/plans/[name]-spec.md` | Planner | ✅ |
| `workdir/plans/[name]-review.md` | Reviewer | ✅ |
| `workdir/plans/[name]-negotiation.md` | Reviewer | Only if discussion occurred |
| `workdir/plans/[name]-delivery-report.md` | Developer | ✅ after execution |
