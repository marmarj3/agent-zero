# Memory and Projects Reference

---

## Project Setup

### Create a project
1. In Agent Zero UI: create new project named e.g. `my-feature`
2. This creates `usr/projects/my-feature/.a0proj/`

### Clone your company repo into the project
```bash
git clone https://github.com/your-company/your-repo.git \
  /path/to/agent-zero/usr/projects/my-feature/code
```

### Create project instructions
Create `usr/projects/my-feature/.a0proj/instructions.md`:

```markdown
# Project: My Feature

## Working Directory
All code work happens in: `/a0/usr/projects/my-feature/code/`
This is a git clone of: `https://github.com/your-company/your-repo.git`

## Before starting any task
1. `cd /a0/usr/projects/my-feature/code`
2. `git status` — confirm correct branch
3. `git pull` — ensure latest changes

## Git workflow
- Create feature branch per task: `git checkout -b feature/[task-name]`
- Commit incrementally as components complete
- Never commit directly to main/master
- Plans: `/a0/usr/projects/my-feature/plans/`

## Tech stack
[describe your stack — saves planner re-discovering it every session]

## Key files
- Entry point: [path]
- Tests: [command]
- Dependencies: [path]
```

---

## Memory Scoping Rules

| Session context | Memory written to | Memory recalled from |
|-----------------|-------------------|---------------------|
| No project active | `usr/memory/default/` | Global only |
| Project active | `usr/projects/<name>/.a0proj/memory/` | Project first, then global |

- Memory is **never written to both** — one target per session
- Project memories are isolated — learnings in project A never affect project B
- Global memory is shared across all sessions and projects

---

## Clearing Bad Memories

### Step 1: Try the Memory Dashboard first
1. Go to Settings → Memory in the Agent Zero UI
2. Filter by project name
3. Delete matching entries

### Step 2: Also wipe the project FAISS index
The Dashboard may not fully control the project-local FAISS index.
Always also run:
```bash
rm usr/projects/<name>/.a0proj/memory/index.faiss
rm usr/projects/<name>/.a0proj/memory/index.pkl
```
The index rebuilds automatically on next session — only stale entries are lost.

### When to do this
- Agent skips clarification and goes straight to plan
- Agent produces a plan without asking questions
- Agent uses an old file path or old tool name
- Agent passes unexpected instructions to subordinates

---

## Knowledge vs Memory Rule

| Content type | Where it belongs | Why |
|--------------|-----------------|-----|
| Agent MUST have (always, every session) | Agent prompt file (`usr/agents/<name>/prompts/`) | Deterministic — always loaded |
| Orchestration logic Agent 0 always needs | Global fragment (`usr/prompts/`) | Deterministic — always loaded |
| Large reference corpus, conditionally useful | `usr/knowledge/main/` (FAISS) | Probabilistic — recalled by similarity |
| Learned solutions from past sessions | Auto-managed by Agent Zero memory system | Auto-saved, auto-recalled |

**Rule**: If missing it breaks the agent → prompt file.
**Rule**: If useful but not always needed → knowledge or memory.

---

## Multiple Projects — Same Repo, Different Branches

```
usr/projects/
├── feature-auth/
│   ├── .a0proj/instructions.md   ← branch: feature/auth
│   └── code/                     ← cloned on feature/auth
├── feature-payments/
│   ├── .a0proj/instructions.md   ← branch: feature/payments
│   └── code/                     ← cloned on feature/payments
└── main-review/
    ├── .a0proj/instructions.md   ← branch: main
    └── code/                     ← cloned on main
```

Each project is fully isolated — memory, code, and plans do not cross.

---

## Update Paths

| What to update | How | Affects |
|----------------|-----|--------|
| Agent Zero framework | Pull new Docker image | Framework only |
| Custom agents | Edit files in `usr/agents/` | All projects |
| Company repo | `git pull` inside `usr/projects/<name>/code/` | That project only |
| Project instructions | Edit `.a0proj/instructions.md` | That project only |
| Plans and reports | Auto-generated | That project session |
