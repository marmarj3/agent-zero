# Copilot Processing — Git Setup for Agent Zero Fork (2026-04-07)

## User Request

Set up a professional Git workflow for the Agent Zero local fork on macOS.
- Generate Ed25519 SSH keys (personal + work)
- Configure `~/.ssh/config` with dual-account aliases
- Fork Agent Zero on GitHub (personal account)
- Point `origin` to personal fork, add `upstream` to official repo
- Set global and local git identity
- Update `.gitignore` with any missing entries
- Commit and push `main-jose` branch to personal fork
- Document per-project git setup pattern

## Action Plan & Tracking

| # | Action | Status |
|---|--------|--------|
| 1 | Ask for GitHub username + personal/work emails | ✅ Done |
| 2 | Generate Ed25519 SSH keys (personal + work) | ⏳ Awaiting user info |
| 3 | Create `~/.ssh/config` with dual-account entries | ⏳ Awaiting user info |
| 4 | Output public keys — user adds to GitHub | ⏳ Awaiting user info |
| 5 | Update `.gitignore` (add `*.local` — only missing entry) | ⏳ Ready |
| 6 | User confirms SSH keys added to GitHub | ⏳ Blocked on Step 4 |
| 7 | Set `origin` remote to personal fork using SSH alias | ⏳ Blocked on Step 4 |
| 8 | Add `upstream` remote to official repo | ⏳ Blocked on Step 4 |
| 9 | Configure global + local git identity | ⏳ Awaiting user info |
| 10 | Commit and push `main-jose` to personal fork | ⏳ Blocked on Step 9 |
| 11 | Verify SSH connections (`ssh -T`) | ⏳ Blocked on Step 6 |
| 12 | Document per-project git user setup | ✅ Done (in response) |

## Notes

- `.gitignore` already contains: `usr/**`, `tmp/**`, `logs/**`, `**/.env`, `.github/` — all Step 7 entries already satisfied except `*.local`
- Existing SSH key: `~/.rsa` (RSA) — Ed25519 keys will be added alongside
- No `~/.ssh/config` exists yet
- Files to commit: `.gitignore`, `Copilot-Processing.md`, `docker-compose.local.yml`, `docs/Project_Architecture_Blueprint.md`, `plan/feature-affiliate-marketing-1.md`, `scripts/copilot_auth.sh`

---

<!-- Previous session content below -->

# Copilot Processing — Plan Review Session (2026-03-25)

## User Request

Review `plan/feature-affiliate-marketing-1.md` and correct any architectural issues. We are in the **planning phase** — no code files should be created.

## What Was Done

### Cleanup
- Removed `config/affiliate_config.json` — created in error before this session corrected the mode
- Removed `python/helpers/affiliate_memory.py` — created in error before this session corrected the mode

### Plan Corrections Applied (4 fixes)

| Fix | Location | Issue | Change |
|-----|----------|-------|--------|
| FIX-1 | TASK-033 | CON-006 violation: `performance_analysis` agent was computing `composite_score` (arithmetic) | Agent now returns raw array only. Python workflow adds `composite_score` via `affiliate_analytics.composite_article_score()` |
| FIX-2 | TASK-051 | No Python scoring step after agent call | Added: workflow calls `composite_article_score()` per dict, adds field, sorts desc |
| FIX-3 | TASK-013 | `get_articles_for_refresh` referenced sessions period comparison requiring 2 GA4 calls/article/month | Simplified to rank-based refresh detection only (rank is the leading indicator per REQ-017) |
| FIX-4 | TASK-021–025 | No guidance on what `tool_name` value to use in prompt JSON examples | Added naming rule: examples must use Python filename without `.py` (e.g. `"dataforseo_tool"` not `"dataforseo"`) |
| FIX-5 | TASK-026–036 | `agent.json` tasks only documented `title` + `context`; `description` field missing | Added `description` field to all 11 profile task specs |
| FIX-6 | TASK-048 | Internal link HTTP calls had no credential source specified | Added explicit `SecretsManager.get_instance().load_secrets()` call + Gutenberg block note |

## Summary

Plan `plan/feature-affiliate-marketing-1.md` is now architecturally correct, v2.0, 355 lines, 12 implementation phases, 68 tasks, 29 files, 8 sections. Ready for implementation.
