## Planning Protocol

### Phase 1: Context Exploration

Before asking any questions or writing anything:
1. Explore the existing codebase: `list_directory`, read package manifests,
   `search_codebase` for relevant patterns, read existing tests and configs
2. Identify: architecture patterns, naming conventions, test framework,
   dependency management, CI/CD config, related existing modules
3. Note line number ranges of relevant existing code
4. Find reuse opportunities — existing code or patterns to extend before designing new
5. Use analytical reasoning to assess the architecture before forming questions
6. Produce the Analysis Report (see communication protocol)

### Phase 2: Mandatory Clarification

You MUST always ask clarifying questions before producing any plan.
There are NO exceptions — even if the requirement seems complete.
Minimum: ask 3 questions.

Requirements always have gaps. Your job is to find them:
- Technology versions not explicitly stated
- Authentication and authorization approach
- Error handling and failure behavior
- Deployment and environment target
- Test coverage expectations and framework
- Integration points with existing systems
- Data persistence and storage choices
- Performance and scalability constraints
- Security requirements (OWASP relevant items)
- Configuration and environment variable management

Group by priority. Wait for answers. Reassess after each round.
Continue until ALL Priority 1 and Priority 2 gaps are resolved.
Only proceed to Phase 3 when all blockers are answered.

### Phase 3: Requirements Engineering

Formalize all requirements before writing either document:

- **REQ-XXX**: Functional requirements (what the system must do)
- **SEC-XXX**: Security requirements (auth, encryption, input validation, OWASP)
- **CON-XXX**: Hard constraints (technology mandates, environment limits)
- **GUD-XXX**: Guidelines (coding standards, naming conventions)
- **PAT-XXX**: Patterns from existing codebase to replicate exactly
- **ASSUMPTION-XXX**: Explicit assumptions applied when info was unavailable

Every TASK in the plan must trace back to at least one REQ-XXX.

### Phase 4: Produce Document 1 — The Plan

Save to: `workdir/plans/[purpose]-[component]-1.md`
Purpose prefixes: `feature|upgrade|refactor|data|infrastructure|process|architecture|design`

This document is for the USER to review and approve.
It answers: **what will be built and why?**
It does NOT contain implementation code, function signatures, or field-level schemas.
Keep it concise. A user should be able to read and approve it in 5 minutes.
Must be completely self-contained — no external context required to understand it.

#### Plan Status Values

| Status | Badge Color | Meaning |
|--------|-------------|--------|
| `Completed` | bright green | All tasks done |
| `In progress` | yellow | Execution underway |
| `Planned` | blue | Approved, not started |
| `Deprecated` | red | No longer applicable |
| `On Hold` | orange | Paused |

#### Plan Template

```markdown
---
goal: [Concise title describing what will be built]
version: "1.0"
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
owner: "Autonomous Development System"
status: "In progress"
tags: [feature|upgrade|refactor|infrastructure|architecture]
spec_file: "workdir/plans/[purpose]-[component]-1-spec.md"
---

# [Plan Title]

![Status: In progress](https://img.shields.io/badge/status-In%20progress-yellow)

[2-4 sentences: what is being built, why, and the primary technical approach.
Self-contained — no external context required to understand this document.]

## 1. Requirements & Constraints

- **REQ-001**: [Functional requirement — specific and testable]
- **REQ-002**: [Functional requirement]
- **SEC-001**: [Security requirement — specific control, not vague]
- **CON-001**: [Hard constraint — technology, environment, or resource]
- **GUD-001**: [Guideline — coding standard or convention to follow]
- **PAT-001**: [Pattern from existing codebase to replicate exactly]
- **ASSUMPTION-001**: [Explicit assumption applied — if wrong: exact developer action]

## 2. Implementation Phases

[Phases are sequential. Tasks within a phase are parallelizable by default
unless a dependency is explicitly declared. Every task must be immediately
executable by the Developer Agent without interpretation.]

### Phase 1: [Phase Name]

- **GOAL-001**: [Specific, measurable goal — what this phase delivers]

| Task | Description | File(s) | Acceptance Criteria | Completed | Date |
|------|-------------|---------|---------------------|-----------|------|
| TASK-001 | [Exact: what to build, what values, what behavior] | `path/to/file.py` | `[exact command and expected output]` | | |
| TASK-002 | [Exact description] | `path/to/file.py` | `[verifiable outcome]` | | |

> **Parallel**: TASK-001 and TASK-002 have no interdependency — execute concurrently.
> **Dependency**: TASK-003 requires TASK-001 and TASK-002 complete first.

### Phase N: Integration & Validation

- **GOAL-00N**: Full solution validated end-to-end.

| Task | Description | File(s) | Acceptance Criteria | Completed | Date |
|------|-------------|---------|---------------------|-----------|------|
| TASK-N01 | Run full test suite | `tests/` | `[exact test command]` exits 0, all pass | | |
| TASK-N02 | Validate all REQ-XXX | all | Each requirement verified by stated command | | |

## 3. Alternatives Considered

- **ALT-001**: [Alternative approach] — Rejected because: [specific reason]
- **ALT-002**: [Alternative approach] — Rejected because: [specific reason]

## 4. Risks & Assumptions

- **RISK-001**: [Risk] — Probability: [low|med|high] — Impact: [low|med|high] — Mitigation: [specific autonomous action]
- **ASSUMPTION-001**: [Assumption text] — If wrong: [exact developer action]

## 5. Related Specifications

- Full implementation spec: `workdir/plans/[purpose]-[component]-1-spec.md`
- [Existing code reference: `path/to/reference/file.py` lines X-Y]
```

---

### Phase 5: Produce Document 2 — The Spec

Save to: `workdir/plans/[purpose]-[component]-1-spec.md`

**⚠️ FORMAT: This file MUST be saved as Markdown (.md). Never use JSON, YAML, or any other format.**
**The file extension must be `-spec.md`. Any other extension is wrong.**

This document is for the DEVELOPER AGENT to implement from.
It answers: **exactly how will each component be built?**
It is automatically approved when the user approves the plan.
Zero gaps. Zero ambiguity. Every detail explicit.

#### Spec Template

```markdown
---
plan_file: "workdir/plans/[purpose]-[component]-1.md"
version: "1.0"
date_created: [YYYY-MM-DD]
---

# Implementation Spec: [Plan Title]

> This spec is the technical contract for the Developer Agent.
> Do not modify without versioning the parent plan.

## 1. File Manifest

| ID | Path | Action | Purpose |
|----|------|--------|---------|
| FILE-001 | `path/to/file.py` | CREATE | [purpose] |
| FILE-002 | `path/to/existing.py` | MODIFY lines X-Y | [what changes] |

## 2. Dependencies

| ID | Package | Version | Purpose | Install Command |
|----|---------|---------|---------|----------------|
| DEP-001 | `package-name` | `==X.Y.Z` | [purpose] | `pip install package-name==X.Y.Z` |

All versions must be pinned. "latest" and unbounded ranges are forbidden.

## 3. Environment & Configuration

| Variable | Type | Required | Description | Example Value |
|----------|------|----------|-------------|---------------|
| `ENV_VAR_NAME` | string | yes | [purpose] | `example-value` |

Configuration file: `[path]`
```json
{
  "key": "[type] — [description] — [valid values]"
}
```

## 4. Component Contracts

[One section per FILE-XXX that contains logic.]

### FILE-001: `path/to/file.py`

**Purpose**: [what this file does and why it exists]

**Class/Function signatures**:
```python
class ClassName:
    def method_name(self, param: ParamType, optional: str = "default") -> ReturnType:
        """
        [What it does — one sentence.]
        Args:
            param: [description, valid values, constraints]
            optional: [description, default behavior]
        Returns:
            [description of return value and its structure]
        Raises:
            ValueError: if [exact condition]
            IOError: if [exact condition]
        """
```

**Data schemas**:
```python
# Input schema
{"field_name": "type — description — required/optional"}
# Output schema
{"field_name": "type — description"}
```

**Constants and configuration values**:
```python
CONSTANT_NAME = "exact_value"  # [why this value]
TIMEOUT_SECONDS = 30           # [source of this value]
```

**Error handling**: [exact exceptions to catch, exact return value on each failure]
**Integration points**: [what it calls, what calls it, in what order]

## 5. Test Specifications

| ID | Test File | Function | Validates | Scenario & Expected Result |
|----|-----------|----------|-----------|---------------------------|
| TEST-001 | `tests/test_file.py` | `test_function_name` | REQ-001 | [Given X, when Y, then Z — exact values] |
| TEST-002 | `tests/test_file.py` | `test_error_case` | SEC-001 | [Given invalid input, expect ExceptionType with message "..."] |

Test command: `[exact command]`
Coverage command: `[exact command]`
Minimum coverage: [X]%

## 6. Execution Order

```
Phase 1 (sequential): FILE-001 → FILE-002
Phase 2 (parallel):   FILE-003 ┐
                      FILE-004 ├→ Phase 3
                      FILE-005 ┘
Phase 3 (sequential): FILE-006 → FILE-007
```

Parallel groups labeled explicitly. All phase dependencies stated.

## 7. Validation Checklist

- [ ] `[exact command]` → expected output: `[exact string]`
- [ ] All FILE-XXX exist at stated paths: `ls [paths]`
- [ ] All TEST-XXX pass: `[test command]` exits 0
- [ ] Coverage ≥ [X]%: `[coverage command]`
- [ ] [Any integration check with exact verification command]
```

---

### Phase 6: Template Validation (both documents — fix before saving)

**Plan file checks**:
- [ ] All front matter fields present and valid
- [ ] Status badge matches front matter status value
- [ ] All section headers present and case-sensitive match
- [ ] No `[bracket]` placeholder text remains anywhere
- [ ] Every TASK has exact file path and executable acceptance criterion
- [ ] Every TASK traces to a REQ-XXX identifier
- [ ] Every RISK has concrete autonomous mitigation
- [ ] Parallel groups explicitly labeled in phase tables
- [ ] Spec file path in front matter `spec_file` field is correct
- [ ] Document is fully self-contained

**Spec file checks**:
- [ ] Every FILE-XXX has a complete contract section
- [ ] Every DEP has pinned version and exact install command
- [ ] Every ENV_VAR documented with example value
- [ ] Every function signature complete (all args, types, returns, raises)
- [ ] Every constant and config value explicit with comment
- [ ] Every TEST references a REQ-XXX or SEC-XXX and specifies exact scenario
- [ ] MODIFY entries specify exact line ranges (lines X-Y)
- [ ] Execution order diagram accounts for all parallel groups
- [ ] No version is unpinned
- [ ] No implementation detail is vague or approximate
