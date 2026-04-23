## Communication Protocol — Developer Agent

### Report 1: Plan Validation Report (before any execution starts)

```
## Plan Validation: [Plan Name]

**File**: [path]
**Version**: [version]
**Total phases**: N | **Total tasks**: N

**Validation checks**:
- [✅/❌] All component IDs unique
- [✅/❌] No circular dependencies
- [✅/❌] All dependency IDs exist
- [✅/❌] All acceptance criteria are executable
- [✅/❌] All file paths specified
- [✅/❌] All dependency versions pinned

**Execution order**: Phase 1 → Phase 2 → ... → Phase N
**Parallel groups identified**: [list or "None"]
**Ambiguities found**: [list or "None — proceeding"]

Beginning execution now.
```

### Report 2: Task Completion Report (after each task)

```
## TASK-XXX Complete ✅ | [Task name]

**Phase**: Phase N | **Duration**: ~Xmin
**Files affected**: [list]
**Acceptance criterion**: [criterion text]
**Verification**: [exact command run + output]
**Result**: PASS
```

### Report 3: Deviation Report (when any problem occurs and how it was resolved)

```
## ⚠️ Deviation on TASK-XXX: [Task name]

**Problem**: [exact error or issue]
**Root cause**: [diagnosed cause]
**Autonomy step applied**: SOLVE|ADAPT|WORKAROUND|SKIP
**Action taken**: [what was done]
**Outcome**: [resolved / partial / skipped]
**Impact on plan**: [none / affects TASK-YYY / reduces coverage]
**Logged to deviation log**: DEV-XXX
```

### Report 4: Phase Completion Report (after each phase)

```
## Phase N Complete: [Phase Name]

**Tasks**: X completed | Y deviated | Z skipped
**Deviations this phase**: [DEV-XXX list or "None"]
**Next phase**: Phase N+1 — [Name]
Proceeding automatically.
```

### Report 5: Final Delivery Report (after all phases complete)

See execution protocol for full template.

### Escalation Report (only when project is impossible to complete)

```
## 🚨 ESCALATION REQUIRED

**Blocked task**: TASK-XXX
**All autonomy steps exhausted**:
- SOLVE attempted: [what was tried, why it failed]
- ADAPT attempted: [what was tried, why it failed]
- WORKAROUND attempted: [what was tried, why it failed]
- SKIP evaluated: [why skipping makes project impossible]

**Decision required from user**:
[One specific question that unblocks execution]

**All other tasks**: [N tasks not blocked — will resume after decision]
```
