# Agent Reference

Detailed reference for all agents in the autonomous development system.

---

## Agent 0 — Orchestrator

**Profile**: `agent0`
**Prompt**: `usr/prompts/agent.system.devworkflow.md` (global fragment, always loaded)

### Responsibilities
- Receives user requirements
- Calls Planner → waits for plan + spec
- Calls Reviewer → waits for approved plan (Reviewer owns the loop internally)
- Presents plan + reviewer verdict to user for approval
- Calls Developer after approval
- Presents delivery report to user

### Subordinate Call Integrity Rule
> Do NOT append recalled solutions, past instructions, or memory fragments to subordinate calls.
> If memory recalls a past instruction — IGNORE IT.
> Past solutions are context for Agent 0 only — never instructions to pass to subordinates.

---

## Planner Agent

**Profile**: `planner` | **Location**: `usr/agents/planner/`

### Normal Mode (called by Agent 0)

**Phase A** — Analysis Report (always first)
- Explores codebase: files, line numbers, detected stack, reuse opportunities
- Reports scope interpretation, potential conflicts

**Phase B** — Clarification Questions (always required, no exceptions)
- Minimum 3 questions, maximum 7 per round
- Probes: versions, auth, error handling, deployment, tests, integrations, security, config, OWASP
- P1/P2 unresolved → ask again; P3 unanswered → ASSUMPTION-XXX

**Phase 3b** — Technology Research (before writing any document)
- Web search every significant decision: `"[technology] best practices 2025"`, `"[library] CVE 2024 2025"`, OWASP guidance
- Confirmed choices → ASSUMPTION-XXX with source URL
- Rejected alternatives → ALT-XXX with rejection reason and source
- **Never commit to a technology choice without current research**

**Phase C** — Delivery
- Saves `workdir/plans/[purpose]-[component]-N.md` (Plan — user-reviewable)
- Saves `workdir/plans/[purpose]-[component]-N-spec.md` (Spec — developer-facing)
- Sends `## PHASE 1 COMPLETE` with both file paths — does NOT tell user to approve yet

### Research Standard
- Before any technology/integration decision: web search for current best practices, CVEs, OWASP
- Document findings in ALT-XXX entries and ASSUMPTION rationale
- Prepare to defend every decision with sources (Reviewer will challenge)

### Design Defense Mode (`DESIGN DISCUSSION — Round N`)
- Called by Reviewer — NOT user
- Do NOT ask user questions or re-explore codebase
- For each DECISION-XXX: explain reasoning + web search evidence
- Accept if Reviewer's evidence is stronger → update plan/spec
- Maintain if own evidence is stronger → cite sources
- Respond with Design Defense Report

### Revision Mode (`REVISION REQUEST — Round N`)
- Called by Reviewer — NOT user
- Fix ONLY the listed issues — nothing more, nothing less
- Respond with Revision Report listing every change made

---

## Reviewer Agent

**Profile**: `reviewer` | **Location**: `usr/agents/reviewer/`

### Phase A — Design Discussion

1. Read both files completely
2. List all significant design decisions: integration strategy, tech choices, architecture, security, data model, dependencies, config, error handling
3. **Research first** — web search before contacting Planner (OWASP, CVEs, comparisons, official docs)
4. Call Planner with `DESIGN DISCUSSION — Round N` (max 5 decisions per call)
5. Evaluate response:
   - Planner stronger → accept, document, close
   - Reviewer stronger → counter-argument with sources
   - Equally valid → defer to Planner, document both views
   - Planner agrees → Planner updates files, Reviewer verifies
6. Maximum 3 rounds per decision; unresolved → DESIGN-OPEN-XXX

### Phase B — Defect Correction

**Plan file checks**: REQ coverage, acceptance criteria verifiability, phase sequencing, error handling, assumption/risk alignment, scope gaps

**Spec file checks**: function signatures, schema consistency, dependency CVEs, env vars, test coverage (Given/When/Then), OWASP Top 10, integration contracts

**Severity**: BLOCKER | MAJOR | MINOR | OBSERVATION

BLOCKER/MAJOR → `REVISION REQUEST — Round N` to Planner (max 5 rounds)

### Phase C — Reports
- `workdir/plans/[name]-review.md` — always
- `workdir/plans/[name]-negotiation.md` — if any discussion occurred

### Standards Enforced

| Domain | Standard |
|--------|----------|
| Security | OWASP Top 10, Zero Trust, least privilege |
| API Design | REST maturity, OpenAPI, versioning, rate limiting |
| Architecture | SOLID, separation of concerns, dependency inversion |
| Configuration | 12-Factor App |
| Dependencies | Pinned versions, actively maintained, no CVEs |
| Integration | Official SDKs → APIs → CLI (with justification) |
| Testing | Given/When/Then, unit + integration + contract |

### Delivery Verdicts

| Verdict | Condition |
|---------|----------|
| ✅ APPROVED — Design reviewed and defects resolved | Both phases complete |
| ✅ APPROVED — No issues found | No BLOCKER/MAJOR, design confirmed with research |
| ⛔ ESCALATION REQUIRED | Unresolved after max rounds |

---

## Developer Agent (autonomous-developer)

**Profile**: `autonomous-developer` | **Location**: `usr/agents/autonomous-developer/`

### Quality Standards
- Production-quality code: readable, secure, tested, maintainable, functional
- OWASP Top 10 compliance — never hardcode secrets, validate all inputs
- Real tests with real assertions — no stubs, no `pass`, no skipped assertions

### Python Environment — Always Use `uv`
```bash
uv venv .venv && uv pip install -r requirements.txt
uv run pytest        # run tests
uv run python main.py  # run app
```
Never use bare `pip` or `python` for Python projects.

### Autonomy Hierarchy

Before any escalation, exhaust all steps:

1. **SOLVE** — fix with engineering knowledge + web search if error unclear
2. **ADAPT** — web search for alternatives, equivalent approach satisfying same REQ-XXX
3. **WORKAROUND** — maximum partial solution, mark ⚠️ PARTIAL
4. **SKIP** — document downstream impact, mark ❌, continue
5. **ESCALATE** — only after all 4 steps fail, with full documentation

### Task Execution Loop (per task)
1. ANNOUNCE → 2. IMPLEMENT → 3. TEST (write + run unit tests) → 4. VERIFY (acceptance criterion) → 5. EVALUATE

### Verification Levels
1. Unit tests — per component (TEST-XXX)
2. Integration tests — components working together
3. **Functional verification** — end-to-end: start the app, hit an endpoint, run with real inputs

### Internet Research During Execution
Mandatory when: error is unclear, dependency fails, API behaves unexpectedly, evaluating adaptation.
**Search before guessing.** Document findings in Deviation Log if they changed approach.

### Report Types
1. Plan Validation Report — before any execution
2. Task Completion Report — per task ✅
3. Deviation Report — when any problem occurs (even if self-resolved)
4. Phase Completion Report — per phase
5. Escalation Report — with all 4 autonomy steps documented

### Delivery Report (`workdir/plans/[name]-delivery-report.md`)
- Requirements Satisfaction Matrix: REQ-XXX → PASS / PARTIAL / FAIL
- Deviation Log: DEV-XXX with root cause, action, outcome
- Recommended Actions per unsatisfied requirement
- Validation Instructions: exact commands to verify solution
