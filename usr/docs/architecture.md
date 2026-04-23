# Architecture Reference

---

## Agent Roles Summary

| Agent | Profile | Owns | Never does |
|-------|---------|------|------------|
| Agent 0 | `agent0` | Orchestration, user communication | Code, planning, reviewing |
| Planner | `planner` | Requirements, plan + spec files, research | Code, reviewing |
| Reviewer | `reviewer` | Quality gate, design discussion, defect correction | Code, planning from scratch |
| Developer | `developer` | Implementation, testing, deviation log | Planning, reviewing |

---

## Data Flow

```
User requirement
      │
      ▼
┌─────────────┐
│   Agent 0   │  ← orchestration prompt always loaded
│ Orchestrator│
└──────┬──────┘
       │ call_subordinate(profile="planner")
       ▼
┌─────────────┐   clarification questions
│   Planner   │ ◄────────────────────────── User answers
│             │   web research
│             │ ──────────────────────────► External sources
└──────┬──────┘
       │ saves plan.md + spec.md
       │ returns delivery summary
       ▼
┌─────────────┐
│   Agent 0   │
└──────┬──────┘
       │ call_subordinate(profile="reviewer")
       ▼
┌──────────────────────────────────────┐
│              Reviewer                │
│                                      │
│  Phase A — Design Discussion         │
│  ┌─────────────────────────────┐     │
│  │ Research decisions          │     │
│  │ call_subordinate("planner") │     │
│  │  DESIGN DISCUSSION Rnd N   │◄──┐ │
│  │ Planner defends/improves   │   │ │
│  │ Update plan/spec if needed  │   │ │
│  │ Repeat up to 3 rounds/dec  │───┘ │
│  └─────────────────────────────┘     │
│                                      │
│  Phase B — Defect Correction         │
│  ┌─────────────────────────────┐     │
│  │ Check plan + spec           │     │
│  │ call_subordinate("planner") │     │
│  │  REVISION REQUEST Rnd N    │◄──┐ │
│  │ Planner fixes issues        │   │ │
│  │ Reviewer verifies           │───┘ │
│  │ Repeat up to 5 rounds       │     │
│  └─────────────────────────────┘     │
│                                      │
│  saves review.md + negotiation.md    │
└──────┬───────────────────────────────┘
       │ returns verdict
       ▼
┌─────────────┐
│   Agent 0   │  presents plan + verdict to user
└──────┬──────┘
       │ User approves
       ▼
┌─────────────┐
│  Developer  │  autonomous execution
│             │  SOLVE→ADAPT→WORKAROUND→SKIP→ESCALATE
└──────┬──────┘
       │ saves delivery-report.md
       ▼
┌─────────────┐
│   Agent 0   │  presents delivery report
└─────────────┘
       │
       ▼
     User
```

---

## Memory Architecture

### Two Separate Stores

| Store | Location | Scope | Dashboard visible? |
|-------|----------|-------|-------------------|
| Global memory | `usr/memory/default/` | All sessions, all projects | ✅ |
| Project memory | `usr/projects/<name>/.a0proj/memory/` | Sessions inside that project only | ⚠️ Partial |

### Memory Recall Flow

```
Every N loop iterations:
  RecallMemories extension runs
  → queries project FAISS index (if project active)
  → queries global FAISS index
  → injects top results into system prompt
```

### Memory Write Target

- **No project active** → writes to `usr/memory/default/`
- **Project active** → writes to `usr/projects/<name>/.a0proj/memory/`
- Memory is **never written to both** — one target per session

### Knowledge vs Memory

| Type | Location | Indexed how | Recalled how |
|------|----------|-------------|-------------|
| Knowledge files | `usr/knowledge/main/` | FAISS at startup | Auto-recalled by similarity |
| Memory entries | `usr/memory/` or project memory | FAISS at save time | Auto-recalled by similarity |
| Agent prompts | `usr/agents/<name>/prompts/` | NOT indexed | Always loaded — deterministic |
| Global fragments | `usr/prompts/` | NOT indexed | Always loaded — deterministic |

**Rule**: Content the agent MUST have → prompt file. Content that is useful but conditional → knowledge/memory.

---

## Profile Resolution Order

When `call_subordinate(profile="planner")` is called:

```
1. agents/<name>/           ← built-in defaults
2. plugins/*/<name>/        ← plugin agents
3. usr/agents/<name>/       ← user agents (overrides built-in on conflict)
4. project/.a0proj/<name>/  ← project agents (highest priority)
```

Prompt files are merged — user files win on filename conflict.

---

## Extension Points

| What to customize | Where |
|-------------------|-------|
| New agent profile | `usr/agents/<name>/` with `agent.yaml` + `prompts/` |
| Global behavior for all agents | `usr/prompts/agent.system.*.md` |
| Project-specific instructions | `usr/projects/<name>/.a0proj/instructions.md` |
| Shared knowledge corpus | `usr/knowledge/main/` |
| Framework core | ❌ Do not modify — use `usr/` overrides |
