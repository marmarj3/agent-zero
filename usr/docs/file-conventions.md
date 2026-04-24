# File Conventions Reference

---

## Output Files Per Session

| File | Produced by | Always? | Purpose |
|------|-------------|---------|--------|
| `workdir/plans/[name].md` | Planner | ✅ | User-reviewable plan |
| `workdir/plans/[name]-spec.md` | Planner | ✅ | Developer implementation contract — **Markdown (.md) format** |
| `workdir/plans/[name]-review.md` | Reviewer | ✅ | Design decisions + defect log |
| `workdir/plans/[name]-negotiation.md` | Reviewer | If discussion occurred | Full round-by-round log |
| `workdir/plans/[name]-delivery-report.md` | Developer | ✅ after execution | Requirements matrix + deviation log |

---

## Plan File Naming Convention

```
[purpose]-[component]-[version].md
```

| Part | Description | Example |
|------|-------------|--------|
| `purpose` | What the plan does | `feature`, `refactor`, `fix`, `design` |
| `component` | What system component | `auth-module`, `payment-api`, `data-pipeline` |
| `version` | Increment on revision | `1`, `2`, `3` |

**Examples**:
- `feature-auth-module-1.md`
- `feature-auth-module-1-spec.md`
- `feature-auth-module-1-review.md`
- `feature-auth-module-1-negotiation.md`
- `feature-auth-module-1-delivery-report.md`
- `feature-auth-module-2.md` ← after revision

---

## Identifier Prefixes

### Plan File Identifiers

| Prefix | Type | Example | Used in |
|--------|------|---------|--------|
| `REQ-` | Functional requirement | `REQ-001` | Plan |
| `SEC-` | Security requirement | `SEC-001` | Plan |
| `CON-` | Constraint | `CON-001` | Plan |
| `GUD-` | Guideline | `GUD-001` | Plan |
| `PAT-` | Pattern/convention | `PAT-001` | Plan |
| `ASSUMPTION-` | Documented assumption | `ASSUMPTION-001` | Plan + Spec |
| `GOAL-` | Phase completion goal | `GOAL-001` | Plan |
| `TASK-` | Implementation task | `TASK-001` | Plan |
| `ALT-` | Alternative considered | `ALT-001` | Plan |
| `RISK-` | Identified risk | `RISK-001` | Plan |

### Spec File Identifiers

| Prefix | Type | Example | Used in |
|--------|------|---------|--------|
| `DEP-` | Dependency | `DEP-001` | Spec |
| `FILE-` | File to create/modify | `FILE-001` | Spec |
| `TEST-` | Test specification | `TEST-001` | Spec |
| `ENV-` | Environment variable | `ENV-001` | Spec |

### Review File Identifiers

| Prefix | Type | Example | Used in |
|--------|------|---------|--------|
| `ISSUE-` | Defect found | `ISSUE-001` | Review |
| `DECISION-` | Design decision evaluated | `DECISION-001` | Negotiation |
| `DESIGN-OPEN-` | Unresolved design question | `DESIGN-OPEN-001` | Negotiation |

### Developer Identifiers

| Prefix | Type | Example | Used in |
|--------|------|---------|--------|
| `DEV-` | Deviation from plan | `DEV-001` | Delivery report |

---

## Status Badges (Plan File)

Used in plan front matter `status` field and as inline badges:

| Status | Badge | Meaning |
|--------|-------|---------|
| Completed | `![Status: Completed](https://img.shields.io/badge/Status-Completed-brightgreen)` | All tasks done |
| In progress | `![Status: In progress](https://img.shields.io/badge/Status-In_progress-yellow)` | Actively being implemented |
| Planned | `![Status: Planned](https://img.shields.io/badge/Status-Planned-blue)` | Approved, not started |
| On Hold | `![Status: On Hold](https://img.shields.io/badge/Status-On_Hold-orange)` | Paused |
| Deprecated | `![Status: Deprecated](https://img.shields.io/badge/Status-Deprecated-lightgrey)` | No longer relevant |

---

## Severity Levels (Review File)

| Level | Meaning | Blocks approval? |
|-------|---------|------------------|
| BLOCKER | Execution failure, wrong results, security vulnerability | ✅ Yes |
| MAJOR | Significant delivery risk, missing coverage, incorrect assumption | ✅ Yes |
| MINOR | Small gap or clarification needed | ❌ No |
| OBSERVATION | Informational — no action required | ❌ No |

---

## REQ Traceability Rule

Every identifier must trace through the chain:

```
REQ-001
  └─► TASK-001, TASK-002   (implements)
        └─► TEST-001        (verifies)
              └─► DEV-001   (deviation, if any)
```

The Reviewer validates this chain in Phase B. The Developer's delivery report closes it.

---

## File Manifest Entry Format (Spec)

```
FILE-001: src/auth/token_service.py
  Action: CREATE
  Purpose: JWT token generation and validation
  Functions:
    - generate_token(user_id: str, expires_in: int) -> str
    - validate_token(token: str) -> dict | raises TokenExpiredError
  Constants:
    - ALGORITHM = "HS256"  # OWASP recommended for symmetric signing
    - TOKEN_EXPIRE_MINUTES = 30  # per SEC-002

FILE-002: src/auth/models.py
  Action: MODIFY lines 45-67
  Purpose: Add refresh_token field to User model
  Change: Add field refresh_token: Optional[str] = None
```
