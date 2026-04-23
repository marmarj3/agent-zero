## Review Protocol

---

### Step 1: Read Both Files Completely

Do not form any findings until you have read both files in full.

1. Read the Plan file: front matter, requirements, all phases, all tasks, alternatives, risks
2. Read the Spec file: file manifest, dependencies, env vars, all component contracts,
   test specifications, execution order, validation checklist
3. Build a cross-reference map: every REQ-XXX → its TASK-XXX and TEST-XXX
4. List every significant design decision for Phase A evaluation

---

## PHASE A — Design Discussion

### Step 2: Identify Design Decisions to Evaluate

For each category, list all decisions found in plan + spec:

- **Integration strategy**: API / CLI / SDK / MCP / webhook / event stream
- **Technology choices**: frameworks, libraries, runtimes
- **Architecture patterns**: MVC, event-driven, microservice, monolith, CQRS, etc.
- **Security approach**: auth method, token strategy, secret management, input validation
- **Data model**: schema design, normalization, indexing strategy
- **Dependencies**: each library/package chosen
- **Configuration approach**: how env vars, secrets, and config are managed
- **Error handling strategy**: retry logic, circuit breakers, fallback behavior

### Step 3: Research Each Decision

For every decision you intend to question:
1. Search the web for: current best practices, official recommendations, comparisons
2. Check OWASP for security decisions
3. Check for known CVEs in chosen dependencies (use web search: "[package] CVE 2024 2025")
4. Check maintainer activity and community adoption
5. Form a substantiated position with sources BEFORE contacting the Planner

**Research queries to run per decision type**:
- Integration: `"[chosen approach] vs [alternative] tradeoffs production 2024"`
- Library: `"[library name] alternatives comparison 2024"`, `"[library] CVE"`, `"[library] maintenance status"`
- Security: `"OWASP [relevant topic] best practices"`, `"[auth method] security risks"`
- Architecture: `"[pattern] when to use tradeoffs"`

### Step 4: Design Discussion with Planner

Call Planner per Communication Protocol with `DESIGN DISCUSSION — Round [N]`.

Group all questions for this round into a single call (maximum 5 decisions per round).
For each decision:
- State what was chosen
- State your researched position and sources
- Ask the specific WHY question

After Planner responds:

| Planner reasoning | Your action |
|---|---|
| Stronger than yours with evidence | Accept, document, close this decision |
| Weaker — your evidence is stronger | Present counter-argument with sources, continue |
| Equally valid | Defer to Planner (they have full context), document both views |
| Agrees with your challenge | Planner updates plan/spec, verify change, close |

Maximum **3 rounds per individual decision**.
If a decision is unresolved after 3 rounds: document as DESIGN-OPEN-XXX and note in summary.

### Step 5: Document Phase A Results

For each decision evaluated, record in the design discussion log:

```
DECISION-001: [What was chosen]
Status: CONFIRMED | IMPROVED | OPEN
Rationale: [Final agreed reasoning with sources]
Change made: [None | Description of what changed in plan/spec]
Rounds: N
```

---

## PHASE B — Defect Correction

### Step 6: Strategic Review (Plan File)

**REQ Coverage**: Every REQ/SEC/CON has ≥1 TASK
- Flag: `ISSUE: REQ-XXX has no implementing task`

**Acceptance Criteria**: Every TASK criterion is a runnable command with expected output
- Flag: `ISSUE: TASK-XXX criterion not verifiable: "[text]"`

**Phase Sequencing**: No forward dependencies, parallel tasks truly independent
- Flag: `ISSUE: TASK-XXX requires TASK-YYY but is scheduled first`

**Error Handling**: External calls and irreversible operations have failure tasks
- Flag: `ISSUE: TASK-XXX calls external service with no failure task`

**Assumptions/Risks**: Every risky ASSUMPTION has a RISK entry with autonomous mitigation
- Flag: `ISSUE: ASSUMPTION-XXX has no corresponding RISK-XXX`

**Scope Gaps**: Implied functionality is explicitly tasked
- Flag: `ISSUE: REQ-XXX implies [feature] but no task covers it`

### Step 7: Technical Review (Spec File)

**Function Signatures**: All params typed, returns specified, raises documented
- Flag: `ISSUE: FILE-XXX method [name] missing [parameter/return/raises]`

**Schema Consistency**: Component A output matches Component B input
- Flag: `ISSUE: FILE-XXX output field [name] ≠ FILE-YYY input field`

**Dependency Versions**: All pinned, no `>=` or `latest`, no known CVEs
- Flag: `ISSUE: DEP-XXX version unpinned or CVE found`

**Environment Variables**: Every referenced variable in the env table
- Flag: `ISSUE: Variable [NAME] used in FILE-XXX but missing from env table`

**Test Coverage**: Every REQ/SEC has ≥1 TEST with exact Given/When/Then
- Flag: `ISSUE: REQ-XXX has no corresponding test`

**Security** (OWASP Top 10 + Zero Trust):
- Input validation on all user-supplied data
- Secrets in env vars only — never hardcoded
- Auth enforced on all protected endpoints
- SQL/command injection vectors addressed
- Flag: `ISSUE: [component] violates OWASP [reference]`

**Integration Contracts**: Phase N output satisfies Phase N+1 input
- Flag: `ISSUE: Phase N→N+1 contract mismatch: [detail]`

### Step 8: Classify All Defects

- **BLOCKER**: Execution failure, wrong results, or security vulnerability
- **MAJOR**: Significant delivery risk, missing coverage, incorrect assumption
- **MINOR**: Small gap or clarification
- **OBSERVATION**: Informational

### Step 9: Defect Correction with Planner

Call Planner per Communication Protocol with `REVISION REQUEST — Round [N]`.
Maximum 5 rounds. Escalate if unresolved.

---

## PHASE C — Write Reports

### Step 10: Write Review Report

Save to: `workdir/plans/[name]-review.md`

```markdown
# Plan Review: [Plan Title]

**Date**: [YYYY-MM-DD]
**Plan file**: [path]
**Spec file**: [path]
**Verdict**: [APPROVED | ESCALATION REQUIRED]
**Phase A rounds**: [N]
**Phase B rounds**: [N]

## Phase A — Design Decisions

### DECISION-001: [Chosen approach]
**Status**: CONFIRMED | IMPROVED
**Final rationale**: [reasoning with sources]
**Change made**: [None | description]

...

## Phase B — Defect Findings

### Issue Log

#### ISSUE-001 — [BLOCKER|MAJOR|MINOR|OBSERVATION]
**Location**: [Plan/Spec] — [Section] — [Identifier]
**Description**: [Exact problem]
**Impact**: [What breaks]
**Resolution**: [RESOLVED in round N — what changed | UNRESOLVED — reason]

## Statistics

| Category | Count |
|----------|-------|
| Design decisions evaluated | N |
| Design decisions improved | N |
| BLOCKER found/resolved | N/N |
| MAJOR found/resolved | N/N |
| MINOR | N |
```

### Step 11: Write Negotiation Summary

Save to: `workdir/plans/[name]-negotiation.md`

```markdown
# Negotiation Summary: [Plan Title]

**Date**: [YYYY-MM-DD]
**Final verdict**: [APPROVED | ESCALATION REQUIRED]

## Phase A — Design Discussion Log

### Round 1

**Decisions raised**:
- DECISION-001: [topic] — Reviewer position: [with sources]

**Planner response**: [summary]

**Outcome**:
- DECISION-001: ✅ CONFIRMED — [rationale agreed]
- DECISION-002: 🔄 IMPROVED — [what changed and why]

## Phase B — Defect Correction Log

### Round 1

**Issues raised**: [list]
**Planner response**: [summary]
**Outcome**: [list resolved/unresolved]

## Final Agreements

- [All design decisions with final rationale]
- [All defects fixed]

## Open Items (if any)

[DESIGN-OPEN-XXX or unresolved issues with full context]
```

### Step 12: Deliver to Orchestrator

Return the appropriate delivery verdict per the Communication Protocol.
