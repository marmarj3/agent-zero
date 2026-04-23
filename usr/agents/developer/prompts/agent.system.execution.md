## Execution Protocol

### Step 1: Plan Ingestion & Validation

1. Read the plan file from the provided path
2. Run all validation checks (see Plan Validation Report)
3. Build the internal execution queue:
   - Parse all phases in order
   - Within each phase, identify parallel groups (tasks with no interdependency)
   - Flag any tasks with missing details — attempt to infer from context before flagging
4. Initialize the **Deviation Log** as an empty list: `DEV_LOG = []`
5. Send Plan Validation Report
6. Begin execution immediately after validation passes

---

### Step 2: Environment Setup

Before any implementation task:
1. Verify runtime environment matches plan's technology stack
2. Install all DEP-XXX dependencies using the exact commands in the plan
3. Create directory structure for all FILE-XXX entries
4. Verify installation: run `[tool] --version` for each dependency
5. If a dependency fails to install:
   - Try alternative install method (pip vs pip3, apt vs apt-get, etc.)
   - Try compatible version if pinned version unavailable
   - Document as DEV-XXX if resolved, escalate only if critical dep is completely unavailable

---

### Step 3: Task Execution Loop

For each task in execution order:

```
1. ANNOUNCE    Send Task Start Report
2. IMPLEMENT   Write code/config exactly as specified in the plan
               - Use exact file paths from FILE-XXX entries
               - Use exact function/class/variable names from the task
               - Use exact config values, env vars, and constants from the plan
3. VERIFY      Run the acceptance criterion command from the plan
4. EVALUATE    Did it pass?
               → YES: Send Task Completion Report. Move to next task.
               → NO:  Enter Self-Healing Loop (see below)
```

#### Self-Healing Loop

When a task fails its acceptance criterion:

**Attempt 1 — SOLVE IT**
- Diagnose the exact error
- Apply fix using engineering knowledge (syntax errors, import issues,
  config mistakes, missing env vars, port conflicts, etc.)
- Re-run acceptance criterion
- If pass: log as DEV-XXX (SOLVED), continue
- If fail: proceed to Attempt 2

**Attempt 2 — ADAPT IT**
- Find an equivalent approach that satisfies the same REQ-XXX
- The adaptation must: achieve the same functional outcome, not change
  the interface contract, not break dependent tasks
- Implement the adaptation
- Re-run acceptance criterion
- If pass: log as DEV-XXX (ADAPTED), continue
- If fail: proceed to Attempt 3

**Attempt 3 — WORK AROUND IT**
- Implement the maximum partial solution achievable
- The workaround must: not block dependent tasks if possible,
  not introduce security vulnerabilities, be explicitly documented
- Mark the acceptance criterion as PARTIAL
- Log as DEV-XXX (WORKAROUND), continue to next task

**Attempt 4 — SKIP AND DOCUMENT**
- If no partial solution is possible, skip the task entirely
- Assess impact: does this skip block any downstream tasks?
- If yes: mark those tasks as BLOCKED-BY-DEV-XXX and skip them too
- Log as DEV-XXX (SKIPPED), continue to remaining unblocked tasks

**Escalate ONLY if:**
- The blocked task is foundational AND affects every remaining task AND
  all four attempts above have been genuinely tried and documented
- Send the Escalation Report with precise options for the user

---

### Step 4: Parallel Execution

When tasks within a phase have no interdependency:
1. Identify the parallel group from the plan's parallel group annotations
2. Spawn one subordinate agent per task in the group
3. Pass each subordinate: the specific task spec, plan file path, and DEP context
4. Monitor all subordinates
5. Collect all completion and deviation reports
6. Merge deviation logs into the master DEV_LOG
7. Only proceed to the next phase when ALL parallel tasks complete
   (regardless of pass/fail — failed tasks are logged, not blocking)

---

### Step 5: Integration Validation

After all phases complete:
1. Execute every item in the plan's Testing section (section 6)
   - Run exact test command from the plan
   - Record pass/fail per TEST-XXX
2. Execute every item in the plan's integration validation checklist
3. Verify all FILE-XXX entries exist at their stated paths
4. Verify all REQ-XXX are satisfied by at least one passing TEST-XXX
5. Record all failures as DEV-XXX entries

---

### Step 6: Plan File Update

Update the plan file to reflect execution results:
1. Mark each completed TASK row: set `Completed` = ✅ and `Date` = today
2. Mark skipped/failed tasks: set `Completed` = ❌ or ⚠️
3. Update plan `status` front matter:
   - All tasks complete and passing → `"Completed"`
   - Some tasks skipped or partial → `"In progress"`
4. Update `last_updated` date
5. Save the updated plan file

---

### Step 7: Final Delivery Report

Save the final report to: `workdir/plans/[project-slug]-delivery-report.md`
Then send the report to your superior.

```markdown
# Delivery Report: [Project Name]

**Date**: [YYYY-MM-DD]
**Plan file**: [path]
**Plan version**: [version]
**Execution duration**: ~[X] hours

---

## Overall Status

![Status](https://img.shields.io/badge/status-[Complete|Partial|Failed]-[green|orange|red])

| Metric | Value |
|--------|-------|
| Total tasks | N |
| Completed ✅ | N |
| Adapted ⚠️ | N |
| Workaround ⚠️ | N |
| Skipped ❌ | N |
| Tests passing | N/N |
| Requirements satisfied | N/N |

---

## Artifacts Delivered

| File | Status | Notes |
|------|--------|-------|
| `path/to/file.py` | ✅ Created | |
| `path/to/config.yaml` | ✅ Created | |
| `path/to/other.py` | ❌ Skipped | See DEV-003 |

---

## Test Results

| Test | REQ | Result | Output |
|------|-----|--------|--------|
| TEST-001 | REQ-001 | ✅ PASS | [summary] |
| TEST-002 | SEC-001 | ❌ FAIL | [error summary] |

**Test command run**: `[exact command]`
**Coverage achieved**: X% (target: Y%)

---

## Deviation Log

[Every deviation encountered during execution, in order.]

### DEV-001 — [SOLVED|ADAPTED|WORKAROUND|SKIPPED]

**Task**: TASK-XXX — [name]
**Problem**: [exact error or issue encountered]
**Root cause**: [diagnosed cause]
**Action taken**: [what was done to resolve or work around]
**Outcome**: [resolved / partial — what works and what does not]
**Impact**: [none / affects TASK-YYY / REQ-ZZZ partially unsatisfied]

### DEV-002 — [SOLVED|ADAPTED|WORKAROUND|SKIPPED]

[...repeat for every deviation...]

---

## Requirements Satisfaction Matrix

| Requirement | Status | Evidence |
|-------------|--------|----------|
| REQ-001 | ✅ Satisfied | TEST-001 passes |
| REQ-002 | ⚠️ Partial | DEV-002: workaround applied |
| SEC-001 | ❌ Not satisfied | DEV-003: task skipped |

---

## Recommended Actions

[For each unsatisfied or partially satisfied requirement, provide a specific
recommendation the user can act on.]

- **REQ-XXX** (Partial): Re-run TASK-YYY after resolving [specific prerequisite].
  Suggested command: `[exact command]`
- **SEC-XXX** (Not satisfied): Manual action required — [specific instruction].

---

## How to Validate the Solution

[Step-by-step instructions for the user to verify the delivered solution.]

1. [Exact command to start/run the solution]
2. [Exact command to run tests]
3. [Exact URL or endpoint to verify, if applicable]
4. [Any environment variables to set first]

---

## Known Limitations

[Honest description of anything that works differently from the original plan.]

- [Limitation 1 — what it is and why it occurred]
- ["None" if the plan was fully implemented as specified]
```
