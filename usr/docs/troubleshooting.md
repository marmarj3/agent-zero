# Troubleshooting Guide

---

## Problem 1: Agent skips clarification and goes straight to plan

**Symptoms**: Planner produces a plan without asking any questions.

**Cause**: Stale memory entry with instruction like *"Ask NO clarifying questions"* being recalled and injected into the system prompt.

**Fix**:
```bash
# Step 1: Wipe project FAISS index
rm usr/projects/<name>/.a0proj/memory/index.faiss
rm usr/projects/<name>/.a0proj/memory/index.pkl

# Step 2: Also clean global memory via Dashboard
# Settings → Memory → filter by project name → delete matches
```

**Prevention**: The orchestration prompt (`usr/prompts/agent.system.devworkflow.md`) contains the Subordinate Call Integrity Rule — Agent 0 must IGNORE recalled solutions when calling subordinates.

---

## Problem 2: Reviewer skips Phase A and goes straight to defect checking

**Symptoms**: Review report has no Design Decisions section, only an Issue Log.

**Cause**: Reviewer prompt may be outdated (pre-Phase A version).

**Diagnosis**:
```bash
grep -n 'Phase A' /a0/usr/agents/reviewer/prompts/agent.system.role.md
grep -n 'DESIGN DISCUSSION' /a0/usr/agents/reviewer/prompts/agent.system.communication.md
```

**Fix**: Both should return matches. If not, the reviewer prompts need to be updated to the current version. See `agents.md` for the full Phase A protocol.

---

## Problem 3: Planner ignores DESIGN DISCUSSION message from Reviewer

**Symptoms**: Reviewer calls planner but planner treats it as a new planning request.

**Cause**: Planner missing Design Defense Mode in communication prompt.

**Diagnosis**:
```bash
grep -n 'DESIGN DISCUSSION' /a0/usr/agents/planner/prompts/agent.system.communication.md
```

**Fix**: Should return a match. If not, Design Defense Mode section is missing — re-add from `agents.md` reference.

---

## Problem 4: Plan file not found at expected path

**Symptoms**: Developer or Reviewer cannot find the plan file.

**Cause**: Planner saved to wrong path or used wrong naming convention.

**Diagnosis**:
```bash
find /a0/usr/workdir/plans -name '*.md' | sort
# Or if using a project:
find /a0/usr/projects/<name>/plans -name '*.md' | sort
```

**Expected naming**: `[purpose]-[component]-[version].md`
Example: `feature-auth-module-1.md`

---

## Problem 5: Reviewer keeps finding new issues after 5 rounds

**Symptoms**: Reviewer sends ESCALATION REQUIRED after 5 rounds.

**This is correct behavior** — not a bug. It means genuine unresolved issues exist.

**What to do**:
1. Read `workdir/plans/[name]-negotiation.md` — find the DESIGN-OPEN-XXX or unresolved ISSUE-XXX entries
2. Decide which position is correct (you have context the agents may lack)
3. Tell Agent 0: *"For ISSUE-001, use approach X because [reason]. Proceed with this decision."*
4. Agent 0 calls Planner with your decision, then Reviewer re-reviews

---

## Problem 6: Developer deviates from plan silently

**Symptoms**: Delivery report shows PARTIAL or FAIL for requirements, but no DEV-XXX entries explain why.

**Cause**: Developer agent prompt may be outdated (missing Deviation Log requirement).

**Diagnosis**:
```bash
grep -n 'DEV-' /a0/usr/agents/developer/prompts/agent.system.execution.md
grep -n 'deviation' /a0/usr/agents/developer/prompts/agent.system.role.md
```

**Fix**: Both should return matches. If not, the developer prompts need updating to include the Deviation Log requirement.

---

## Problem 7: Agent profile not resolving correctly

**Symptoms**: Wrong agent behavior — planner behaves like default agent, or reviewer doesn't exist.

**Diagnosis**:
```bash
# Check agent.yaml exists
ls /a0/usr/agents/planner/
ls /a0/usr/agents/reviewer/
ls /a0/usr/agents/developer/

# Check agent.yaml content
cat /a0/usr/agents/planner/agent.yaml

# Check prompts exist
ls /a0/usr/agents/planner/prompts/
ls /a0/usr/agents/reviewer/prompts/
```

**Expected files per agent**:
```
<name>/
├── agent.yaml
└── prompts/
    ├── agent.system.role.md
    ├── agent.system.communication.md
    └── agent.system.[role-specific].md
```

---

## Problem 8: Orchestration prompt not loaded (Agent 0 doesn't follow workflow)

**Symptoms**: Agent 0 does planning itself instead of calling the planner profile.

**Diagnosis**:
```bash
ls /a0/usr/prompts/
cat /a0/usr/prompts/agent.system.devworkflow.md | head -20
```

**Expected**: File exists and starts with the workflow header. Files in `usr/prompts/` are loaded automatically as global fragments for all sessions.

**Fix if missing**: Re-create the file. It must be at `usr/prompts/agent.system.devworkflow.md` — the filename pattern `agent.system.*.md` is required for auto-loading.

---

## Quick Health Check

Run this to verify all critical files are in place:

```bash
echo '=== Orchestration ===' && ls /a0/usr/prompts/
echo '=== Planner ===' && ls /a0/usr/agents/planner/prompts/
echo '=== Reviewer ===' && ls /a0/usr/agents/reviewer/prompts/
echo '=== Developer ===' && ls /a0/usr/agents/developer/prompts/
echo '=== Docs ===' && ls /a0/usr/workdir/docs/
echo '=== Plans ===' && ls /a0/usr/workdir/plans/ 2>/dev/null || echo '(empty — no plans yet)'
```

---

## Problem 9: Reviewer never called — Agent 0 responds to user after planner

**Symptoms**: Only A0 and A1 appear in the console. No reviewer files produced.

**Cause**: Agent 0 interprets planner delivery as task completion and responds to user.

**Fix applied** (all three of these must be present):
```bash
# Verify hard gates in orchestration prompt
grep 'PHASE 1 COMPLETE\|DO NOT SKIP\|NEVER respond' /a0/usr/prompts/agent.system.devworkflow.md

# Verify planner delivery uses PHASE 1 COMPLETE trigger
grep 'PHASE 1 COMPLETE' /a0/usr/agents/planner/prompts/agent.system.communication.md

# Verify reviewer delivery uses PHASE 2 COMPLETE trigger
grep 'PHASE 2 COMPLETE' /a0/usr/agents/reviewer/prompts/agent.system.communication.md
```

If any missing — re-apply fixes from this session. Also wipe project FAISS (see Problem 1).

---

## Problem 10: Planner skips or minimizes clarification questions

**Symptoms**: Planner produces plan after 0-2 questions, leaving gaps the developer must guess.

**Cause**: LLM decides requirement is complete enough, skips mandatory clarification.

**Fix applied**: Planner communication prompt now has:
- 13-category mandatory probe list
- Explicit warning: missing details cause developer failure
- Self-check gate: must answer NO to "Does developer need to guess anything?" before proceeding

**Verify**:
```bash
grep 'MANDATORY probes\|Does the developer need' /a0/usr/agents/planner/prompts/agent.system.communication.md
```
